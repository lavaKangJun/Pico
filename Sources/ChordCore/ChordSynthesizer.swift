import AVFoundation
import ComposableArchitecture
import Foundation

/// 코드를 어떤 식으로 울릴지.
public enum PlaybackStyle: String, CaseIterable, Sendable, Hashable, Codable, Identifiable {
    /// 구성음을 한 번에 누른다.
    case block
    /// 아르페지오
    case arpeggio

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .block: localized("동시에")
        case .arpeggio: localized("아르페지오")
        }
    }

    public var systemImage: String {
        switch self {
        case .block: "rectangle.stack.fill"
        case .arpeggio: "waveform.path"
        }
    }
}

/// 사운드폰트 없이 가산 합성으로 피아노에 가까운 소리를 만들어 재생한다.
actor ChordSynthesizer {
    @Dependency(\.crashReporter) private var crashReporter

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private lazy var format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    private var isConfigured = false

    /// 한 음이 울리는 길이(초).
    private let noteDuration: Double = 2.4
    /// 아르페지오에서 음 사이 간격(초).
    private let arpeggioGap: Double = 0.17

    func play(midiNotes: [Int], style: PlaybackStyle) {
        guard !midiNotes.isEmpty else { return }
        do {
            try configureIfNeeded()
            let buffer = try makeBuffer(midiNotes: midiNotes.sorted(), style: style)
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            player.play()
        } catch {
            // 오디오는 앱의 본질 기능이 아니므로, 실패해도 화면은 그대로 동작한다.
            // 다만 소리가 안 나는 건 사용자가 바로 알아차리니 리포터에는 남긴다.
            crashReporter.record(error, context: [
                "midi_notes": midiNotes.map(String.init).joined(separator: ","),
                "style": style.rawValue,
            ])
            assertionFailure("코드 재생 실패: \(error)")
        }
    }

    func stop() {
        player.stop()
    }

    // MARK: - 엔진

    private func configureIfNeeded() throws {
        guard !isConfigured else {
            if !engine.isRunning { try engine.start() }
            return
        }

        #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        #endif

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()
        try engine.start()
        isConfigured = true
    }

    // MARK: - 합성

    /// 배음을 쌓고 감쇠 엔벨로프를 씌워 PCM 버퍼를 만든다.
    private func makeBuffer(midiNotes: [Int], style: PlaybackStyle) throws -> AVAudioPCMBuffer {
        let offsets = noteOffsets(count: midiNotes.count, style: style)
        let totalDuration = (offsets.last ?? 0) + noteDuration
        let frameCount = AVAudioFrameCount(totalDuration * sampleRate)

        guard
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let channel = buffer.floatChannelData?[0]
        else {
            throw SynthesizerError.bufferAllocationFailed
        }
        buffer.frameLength = frameCount

        for frame in 0 ..< Int(frameCount) {
            channel[frame] = 0
        }

        // 음이 많을수록 전체 음량을 낮춰 클리핑을 막는다.
        let gain = Float(0.55 / Double(midiNotes.count).squareRoot())

        for (index, note) in midiNotes.enumerated() {
            let frequency = note.midiFrequency
            let startFrame = Int(offsets[index] * sampleRate)
            let voiceFrames = min(Int(noteDuration * sampleRate), Int(frameCount) - startFrame)
            guard voiceFrames > 0 else { continue }

            // 높은 음일수록 배음이 빨리 사라지는 피아노 특성을 흉내 낸다.
            let brightness = max(0.25, 1.0 - Double(note - 48) / 60.0)

            for frame in 0 ..< voiceFrames {
                let time = Double(frame) / sampleRate
                var sample = 0.0
                for (harmonic, weight) in Self.harmonics.enumerated() {
                    let partial = Double(harmonic + 1)
                    let partialFrequency = frequency * partial
                    guard partialFrequency < sampleRate / 2 else { break }
                    let decay = exp(-time * (2.2 + partial * 1.4 * (1.0 - brightness) + partial * 0.35))
                    sample += sin(2 * .pi * partialFrequency * time) * weight * decay
                }
                channel[startFrame + frame] += Float(sample * envelope(at: time)) * gain
            }
        }

        return buffer
    }

    /// 배음별 진폭.
    private static let harmonics: [Double] = [1.0, 0.42, 0.22, 0.12, 0.06]

    /// 어택은 짧게, 릴리스는 끝에서 부드럽게 떨어뜨린다.
    private func envelope(at time: Double) -> Double {
        let attack = 0.006
        let release = 0.25
        if time < attack { return time / attack }
        let remaining = noteDuration - time
        if remaining < release { return max(0, remaining / release) }
        return 1
    }

    private func noteOffsets(count: Int, style: PlaybackStyle) -> [Double] {
        switch style {
        case .block:
            Array(repeating: 0, count: count)
        case .arpeggio:
            (0 ..< count).map { Double($0) * arpeggioGap }
        }
    }

    enum SynthesizerError: Error {
        case bufferAllocationFailed
    }
}
