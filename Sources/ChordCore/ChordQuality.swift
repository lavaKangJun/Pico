import Foundation

/// 코드의 성질(마이너, 메이저 세븐 등)을 루트로부터의 반음 간격으로 정의한다.
public struct ChordQuality: Sendable, Hashable, Codable, Identifiable {
    /// 코드 심볼에 붙는 접미사. 메이저는 빈 문자열이다. (예: `m7`)
    public let symbol: String
    /// 한국어 표시 이름. (예: `마이너 세븐스`)
    public let displayName: String
    /// 분류 탭.
    public let category: Category
    /// 루트를 0으로 했을 때의 반음 간격.
    public let intervals: [Int]

    public var id: String { symbol.isEmpty ? "maj" : symbol }

    public init(symbol: String, displayName: String, category: Category, intervals: [Int]) {
        self.symbol = symbol
        self.displayName = displayName
        self.category = category
        self.intervals = intervals
    }

    /// 각 구성음의 도수 이름. (예: `R`, `♭3`, `5`)
    public var degreeLabels: [String] {
        intervals.map(Self.degreeLabel(forSemitone:))
    }

    public enum Category: String, CaseIterable, Sendable, Hashable, Codable, Identifiable {
        case triad
        case sixth
        case seventh
        case tension

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .triad: "3화음"
            case .sixth: "6화음"
            case .seventh: "7화음"
            case .tension: "텐션"
            }
        }
    }

    static func degreeLabel(forSemitone semitone: Int) -> String {
        switch semitone {
        case 0: "R"
        case 1: "♭9"
        case 2: "9"
        case 3: "♭3"
        case 4: "3"
        case 5: "11"
        case 6: "♭5"
        case 7: "5"
        case 8: "♯5"
        case 9: "6"
        case 10: "♭7"
        case 11: "7"
        case 13: "♭9"
        case 14: "9"
        case 15: "♯9"
        case 17: "11"
        case 18: "♯11"
        case 20: "♭13"
        case 21: "13"
        default: "\(semitone)st"
        }
    }
}

// MARK: - 기본 제공 코드

public extension ChordQuality {
    // 3화음
    static let major = ChordQuality(symbol: "", displayName: "메이저", category: .triad, intervals: [0, 4, 7])
    static let minor = ChordQuality(symbol: "m", displayName: "마이너", category: .triad, intervals: [0, 3, 7])
    static let diminished = ChordQuality(symbol: "dim", displayName: "디미니시드", category: .triad, intervals: [0, 3, 6])
    static let augmented = ChordQuality(symbol: "aug", displayName: "오그멘티드", category: .triad, intervals: [0, 4, 8])
    static let sus2 = ChordQuality(symbol: "sus2", displayName: "서스펜디드 2", category: .triad, intervals: [0, 2, 7])
    static let sus4 = ChordQuality(symbol: "sus4", displayName: "서스펜디드 4", category: .triad, intervals: [0, 5, 7])
    static let power = ChordQuality(symbol: "5", displayName: "파워 코드", category: .triad, intervals: [0, 7])

    // 6화음
    static let sixth = ChordQuality(symbol: "6", displayName: "메이저 식스", category: .sixth, intervals: [0, 4, 7, 9])
    static let minorSixth = ChordQuality(symbol: "m6", displayName: "마이너 식스", category: .sixth, intervals: [0, 3, 7, 9])
    static let sixNine = ChordQuality(symbol: "6/9", displayName: "식스 나인", category: .sixth, intervals: [0, 4, 7, 9, 14])
    static let addNine = ChordQuality(symbol: "add9", displayName: "애드 나인", category: .sixth, intervals: [0, 4, 7, 14])
    static let minorAddNine = ChordQuality(symbol: "madd9", displayName: "마이너 애드 나인", category: .sixth, intervals: [0, 3, 7, 14])

    // 7화음
    static let dominantSeventh = ChordQuality(symbol: "7", displayName: "도미넌트 세븐스", category: .seventh, intervals: [0, 4, 7, 10])
    static let majorSeventh = ChordQuality(symbol: "maj7", displayName: "메이저 세븐스", category: .seventh, intervals: [0, 4, 7, 11])
    static let minorSeventh = ChordQuality(symbol: "m7", displayName: "마이너 세븐스", category: .seventh, intervals: [0, 3, 7, 10])
    static let minorMajorSeventh = ChordQuality(symbol: "mMaj7", displayName: "마이너 메이저 세븐스", category: .seventh, intervals: [0, 3, 7, 11])
    static let halfDiminished = ChordQuality(symbol: "m7♭5", displayName: "하프 디미니시드", category: .seventh, intervals: [0, 3, 6, 10])
    static let diminishedSeventh = ChordQuality(symbol: "dim7", displayName: "디미니시드 세븐스", category: .seventh, intervals: [0, 3, 6, 9])
    static let dominantSeventhSus4 = ChordQuality(symbol: "7sus4", displayName: "세븐 서스4", category: .seventh, intervals: [0, 5, 7, 10])
    static let augmentedSeventh = ChordQuality(symbol: "aug7", displayName: "오그멘티드 세븐스", category: .seventh, intervals: [0, 4, 8, 10])

    // 텐션
    static let ninth = ChordQuality(symbol: "9", displayName: "나인스", category: .tension, intervals: [0, 4, 7, 10, 14])
    static let majorNinth = ChordQuality(symbol: "maj9", displayName: "메이저 나인스", category: .tension, intervals: [0, 4, 7, 11, 14])
    static let minorNinth = ChordQuality(symbol: "m9", displayName: "마이너 나인스", category: .tension, intervals: [0, 3, 7, 10, 14])
    static let eleventh = ChordQuality(symbol: "11", displayName: "일레븐스", category: .tension, intervals: [0, 7, 10, 14, 17])
    static let thirteenth = ChordQuality(symbol: "13", displayName: "써틴스", category: .tension, intervals: [0, 4, 7, 10, 14, 21])
    static let seventhFlatNine = ChordQuality(symbol: "7♭9", displayName: "세븐 플랫 나인", category: .tension, intervals: [0, 4, 7, 10, 13])
    static let seventhSharpNine = ChordQuality(symbol: "7♯9", displayName: "세븐 샵 나인", category: .tension, intervals: [0, 4, 7, 10, 15])
    static let seventhSharpEleven = ChordQuality(symbol: "7♯11", displayName: "세븐 샵 일레븐", category: .tension, intervals: [0, 4, 7, 10, 18])

    /// 앱에서 고를 수 있는 전체 코드 성질.
    static let all: [ChordQuality] = [
        .major, .minor, .diminished, .augmented, .sus2, .sus4, .power,
        .sixth, .minorSixth, .sixNine, .addNine, .minorAddNine,
        .dominantSeventh, .majorSeventh, .minorSeventh, .minorMajorSeventh,
        .halfDiminished, .diminishedSeventh, .dominantSeventhSus4, .augmentedSeventh,
        .ninth, .majorNinth, .minorNinth, .eleventh, .thirteenth,
        .seventhFlatNine, .seventhSharpNine, .seventhSharpEleven,
    ]

    /// 분류별로 묶인 코드 성질.
    static func all(in category: Category) -> [ChordQuality] {
        all.filter { $0.category == category }
    }

    /// 심볼로 코드 성질을 찾는다.
    static func quality(symbol: String) -> ChordQuality? {
        all.first { $0.symbol == symbol }
    }
}
