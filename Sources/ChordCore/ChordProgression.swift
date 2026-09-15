import Foundation

/// 조성(장조/단조).
public enum Tonality: String, CaseIterable, Sendable, Hashable, Codable, Identifiable {
    case major
    case minor

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .major: localized("장조")
        case .minor: localized("단조")
        }
    }

    public var suffix: String {
        switch self {
        case .major: ""
        case .minor: "m"
        }
    }
}

/// 자주 쓰이는 코드 진행.
public struct ChordProgression: Sendable, Hashable, Codable, Identifiable {
    /// 진행 단계 하나. 으뜸음으로부터의 반음 거리와 코드 성질로 표현한다.
    public struct Step: Sendable, Hashable, Codable {
        /// 으뜸음(I)으로부터의 반음 거리.
        public let semitoneFromTonic: Int
        /// 이 자리에 쌓는 코드 성질.
        public let quality: ChordQuality
        /// 로마 숫자 표기. (예: `vi`)
        public let numeral: String

        public init(semitoneFromTonic: Int, quality: ChordQuality, numeral: String) {
            self.semitoneFromTonic = semitoneFromTonic
            self.quality = quality
            self.numeral = numeral
        }
    }

    public let id: String
    /// 진행 이름의 번역 키.
    let nameKey: String
    /// 한 줄 설명의 번역 키.
    let summaryKey: String
    public let tonality: Tonality
    public let steps: [Step]

    /// 현재 언어로 번역된 진행 이름.
    public var name: String { localized(nameKey) }

    /// 어떤 곡에서 들어봤는지 같은 한 줄 설명.
    public var summary: String { localized(summaryKey) }

    public init(id: String, name: String, summary: String, tonality: Tonality, steps: [Step]) {
        self.id = id
        nameKey = name
        summaryKey = summary
        self.tonality = tonality
        self.steps = steps
    }

    /// 로마 숫자 표기를 이어 붙인 문자열. (예: `I – V – vi – IV`)
    public var numeralDescription: String {
        steps.map(\.numeral).joined(separator: " – ")
    }

    /// 주어진 으뜸음에서의 실제 코드들.
    public func chords(inKey tonic: PitchClass) -> [Chord] {
        steps.map { step in
            Chord(root: tonic.transposed(by: step.semitoneFromTonic), quality: step.quality)
        }
    }
}

// MARK: - 기본 제공 진행

public extension ChordProgression {
    private static func step(_ semitone: Int, _ quality: ChordQuality, _ numeral: String) -> Step {
        Step(semitoneFromTonic: semitone, quality: quality, numeral: numeral)
    }

    static let pop = ChordProgression(
        id: "I-V-vi-IV",
        name: "팝 진행",
        summary: "가장 많이 쓰이는 네 코드. 발라드부터 K-팝까지 두루 쓰인다.",
        tonality: .major,
        steps: [
            step(0, .major, "I"), step(7, .major, "V"), step(9, .minor, "vi"), step(5, .major, "IV"),
        ]
    )

    static let fifties = ChordProgression(
        id: "I-vi-IV-V",
        name: "50년대 진행",
        summary: "올드팝과 도-왑의 기본. 포근하게 제자리로 돌아온다.",
        tonality: .major,
        steps: [
            step(0, .major, "I"), step(9, .minor, "vi"), step(5, .major, "IV"), step(7, .major, "V"),
        ]
    )

    static let twoFiveOne = ChordProgression(
        id: "ii-V-I",
        name: "투 파이브 원",
        summary: "재즈의 뼈대. 세븐스 코드로 부드럽게 해결된다.",
        tonality: .major,
        steps: [
            step(2, .minorSeventh, "ii7"), step(7, .dominantSeventh, "V7"), step(0, .majorSeventh, "IΔ7"),
        ]
    )

    static let canon = ChordProgression(
        id: "canon",
        name: "캐논 진행",
        summary: "파헬벨 캐논에서 온 여덟 코드. 한 마디씩 내려가는 베이스가 특징.",
        tonality: .major,
        steps: [
            step(0, .major, "I"), step(7, .major, "V"), step(9, .minor, "vi"), step(4, .minor, "iii"),
            step(5, .major, "IV"), step(0, .major, "I"), step(5, .major, "IV"), step(7, .major, "V"),
        ]
    )

    static let sensitiveFemale = ChordProgression(
        id: "vi-IV-I-V",
        name: "vi 시작 진행",
        summary: "마이너로 시작해 밝게 풀리는, 시티팝에서 자주 들리는 흐름.",
        tonality: .major,
        steps: [
            step(9, .minor, "vi"), step(5, .major, "IV"), step(0, .major, "I"), step(7, .major, "V"),
        ]
    )

    static let blues = ChordProgression(
        id: "12-bar-blues",
        name: "12마디 블루스",
        summary: "블루스와 로큰롤의 기본형. 전부 도미넌트 세븐스로 친다.",
        tonality: .major,
        steps: [
            step(0, .dominantSeventh, "I7"), step(5, .dominantSeventh, "IV7"),
            step(0, .dominantSeventh, "I7"), step(7, .dominantSeventh, "V7"),
            step(5, .dominantSeventh, "IV7"), step(0, .dominantSeventh, "I7"),
        ]
    )

    static let andalusian = ChordProgression(
        id: "i-VII-VI-V",
        name: "안달루시안 케이던스",
        summary: "반음씩 내려오는 플라멩코풍 마이너 진행.",
        tonality: .minor,
        steps: [
            step(0, .minor, "i"), step(10, .major, "♭VII"), step(8, .major, "♭VI"), step(7, .major, "V"),
        ]
    )

    static let minorPop = ChordProgression(
        id: "i-VI-III-VII",
        name: "마이너 팝 진행",
        summary: "어둡지만 시원하게 뻗는, 록과 K-팝 후렴의 단골.",
        tonality: .minor,
        steps: [
            step(0, .minor, "i"), step(8, .major, "♭VI"), step(3, .major, "♭III"), step(10, .major, "♭VII"),
        ]
    )

    static let minorTwoFiveOne = ChordProgression(
        id: "iim7b5-V7-i",
        name: "마이너 투 파이브 원",
        summary: "마이너 조성의 해결. m7♭5에서 시작한다.",
        tonality: .minor,
        steps: [
            step(2, .halfDiminished, "iiø7"), step(7, .dominantSeventh, "V7"), step(0, .minorSeventh, "i7"),
        ]
    )

    static let all: [ChordProgression] = [
        .pop, .fifties, .twoFiveOne, .canon, .sensitiveFemale, .blues,
        .andalusian, .minorPop, .minorTwoFiveOne,
    ]
}
