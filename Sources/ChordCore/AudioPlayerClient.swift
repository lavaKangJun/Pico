import ComposableArchitecture
import Foundation

/// 코드/음 재생을 담당하는 의존성.
///
/// 리듀서는 이 인터페이스만 알고, 실제 오디오 엔진은 `liveValue`에만 들어 있다.
public struct AudioPlayerClient: Sendable {
    public var play: @Sendable (_ midiNotes: [Int], _ style: PlaybackStyle) async -> Void
    public var stop: @Sendable () async -> Void

    public init(
        play: @escaping @Sendable ([Int], PlaybackStyle) async -> Void,
        stop: @escaping @Sendable () async -> Void
    ) {
        self.play = play
        self.stop = stop
    }

    /// 코드 하나를 재생한다.
    public func play(chord: Chord, octave: Int = 4, inversion: Int = 0, style: PlaybackStyle = .block) async {
        await play(chord.midiNotes(octave: octave, inversion: inversion), style)
    }

    /// 건반 하나를 재생한다.
    public func play(note: Int) async {
        await play([note], .block)
    }
}

extension AudioPlayerClient: DependencyKey {
    public static let liveValue: AudioPlayerClient = {
        let synthesizer = ChordSynthesizer()
        return AudioPlayerClient(
            play: { notes, style in await synthesizer.play(midiNotes: notes, style: style) },
            stop: { await synthesizer.stop() }
        )
    }()

    /// 프리뷰와 테스트에서는 소리를 내지 않는다.
    public static let testValue = AudioPlayerClient(play: { _, _ in }, stop: {})
    public static let previewValue = testValue
}

public extension DependencyValues {
    var audioPlayer: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}
