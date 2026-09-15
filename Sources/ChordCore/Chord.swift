import Foundation

/// 루트 음과 성질로 정의되는 하나의 코드.
public struct Chord: Sendable, Hashable, Codable, Identifiable {
    public let root: PitchClass
    public let quality: ChordQuality

    public var id: String { "\(root.rawValue)-\(quality.id)" }

    public init(root: PitchClass, quality: ChordQuality) {
        self.root = root
        self.quality = quality
    }

    /// 루트 표기에 플랫을 쓰는지 여부.
    public var prefersFlatSpelling: Bool { root.prefersFlatSpelling }

    /// 코드 심볼. (예: `B♭m7`)
    public var symbol: String {
        root.name(preferringFlats: prefersFlatSpelling) + quality.symbol
    }

    /// 전위를 반영한 코드 심볼. (예: `Cmaj7/E`)
    public func symbol(inversion: Int) -> String {
        let normalized = normalizedInversion(inversion)
        guard normalized > 0 else { return symbol }
        let bass = bassNote(inversion: normalized)
        return "\(symbol)/\(bass.name(preferringFlats: prefersFlatSpelling))"
    }

    /// 코드 구성음(피치 클래스). 옥타브 위 텐션은 같은 음으로 접혀 중복이 제거된다.
    public var pitches: [PitchClass] {
        var seen = Set<PitchClass>()
        return quality.intervals.compactMap { interval in
            let pitch = root.transposed(by: interval)
            return seen.insert(pitch).inserted ? pitch : nil
        }
    }

    /// 구성음 이름. (예: `["B♭", "D♭", "F", "A♭"]`)
    public var pitchNames: [String] {
        pitches.map { $0.name(preferringFlats: prefersFlatSpelling) }
    }

    /// 구성음 계이름. 음이름과 같은 표기 규칙을 쓴다.
    public var solfegeNames: [String] {
        pitches.map { $0.solfege(preferringFlats: prefersFlatSpelling) }
    }

    /// 구성음의 도수 이름과 음이름 쌍.
    public var tones: [Tone] {
        var seen = Set<PitchClass>()
        return quality.intervals.compactMap { interval in
            let pitch = root.transposed(by: interval)
            guard seen.insert(pitch).inserted else { return nil }
            return Tone(
                semitone: interval,
                pitch: pitch,
                degree: ChordQuality.degreeLabel(forSemitone: interval),
                name: pitch.name(preferringFlats: prefersFlatSpelling)
            )
        }
    }

    /// 가능한 전위의 개수. (기본 위치 포함)
    public var inversionCount: Int { min(quality.intervals.count, 4) }

    /// 주어진 옥타브와 전위로 실제 연주할 MIDI 노트를 만든다.
    ///
    /// - Parameters:
    ///   - octave: 루트가 놓일 옥타브. `4`면 가운데 도(C4 = 60) 기준.
    ///   - inversion: 0이면 기본 위치. 1이면 가장 낮은 음을 한 옥타브 올린다.
    public func midiNotes(octave: Int = 4, inversion: Int = 0) -> [Int] {
        let rootMIDI = (octave + 1) * 12 + root.rawValue
        var notes = quality.intervals.map { rootMIDI + $0 }
        for index in 0 ..< normalizedInversion(inversion) {
            notes[index % notes.count] += 12
        }
        return notes.sorted()
    }

    /// 전위했을 때 가장 낮은 음(베이스).
    public func bassNote(inversion: Int) -> PitchClass {
        let notes = midiNotes(inversion: inversion)
        return PitchClass(midiNote: notes.first ?? root.rawValue)
    }

    private func normalizedInversion(_ inversion: Int) -> Int {
        max(0, min(inversion, inversionCount - 1))
    }

    public struct Tone: Sendable, Hashable, Codable, Identifiable {
        public let semitone: Int
        public let pitch: PitchClass
        public let degree: String
        public let name: String

        public var id: Int { semitone }
    }
}

// MARK: - 역으로 찾기

public extension Chord {
    /// 누른 음들과 정확히 일치하는 코드를 모두 찾는다.
    ///
    /// 옥타브는 무시하고 피치 클래스 집합으로만 비교한다.
    static func matching(pitches: Set<PitchClass>) -> [Chord] {
        guard pitches.count >= 2 else { return [] }
        var matches: [Chord] = []
        for root in PitchClass.allCases {
            for quality in ChordQuality.all {
                let chord = Chord(root: root, quality: quality)
                if Set(chord.pitches) == pitches {
                    matches.append(chord)
                }
            }
        }
        // 구성음이 단순한 코드를 먼저 보여준다.
        return matches.sorted { $0.quality.intervals.count < $1.quality.intervals.count }
    }

    /// MIDI 노트 배열로 코드를 찾는다.
    static func matching(midiNotes: [Int]) -> [Chord] {
        matching(pitches: Set(midiNotes.map(PitchClass.init(midiNote:))))
    }
}
