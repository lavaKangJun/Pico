import Foundation

/// 옥타브를 구분하지 않는 12개의 음이름(피치 클래스).
public enum PitchClass: Int, CaseIterable, Sendable, Hashable, Codable, Identifiable {
    case c = 0
    case cSharp
    case d
    case dSharp
    case e
    case f
    case fSharp
    case g
    case gSharp
    case a
    case aSharp
    case b

    public var id: Int { rawValue }

    private static let sharpNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    private static let flatNames = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
    private static let sharpSolfege = ["도", "도♯", "레", "레♯", "미", "파", "파♯", "솔", "솔♯", "라", "라♯", "시"]
    private static let flatSolfege = ["도", "레♭", "레", "미♭", "미", "파", "솔♭", "솔", "라♭", "라", "시♭", "시"]

    /// 샤프 표기 (예: `C♯`)
    public var sharpName: String { Self.sharpNames[rawValue] }

    /// 플랫 표기 (예: `D♭`)
    public var flatName: String { Self.flatNames[rawValue] }

    /// 음이름과 같은 표기 규칙을 따르는 계이름. (예: `D♭` → `레♭`)
    public var solfege: String { solfege(preferringFlats: prefersFlatSpelling) }

    /// 조표 성향에 맞춘 계이름.
    public func solfege(preferringFlats: Bool) -> String {
        localized(preferringFlats ? Self.flatSolfege[rawValue] : Self.sharpSolfege[rawValue])
    }

    /// 검은 건반 여부.
    public var isAccidental: Bool { sharpName.count > 1 }

    /// 조표 성향에 맞춘 표기를 돌려준다.
    public func name(preferringFlats: Bool) -> String {
        preferringFlats ? flatName : sharpName
    }

    /// 루트로 쓰였을 때 플랫 표기가 더 자연스러운지 여부.
    ///
    /// F, B♭, E♭, A♭, D♭, G♭ 계열은 관습적으로 플랫으로 적는다.
    public var prefersFlatSpelling: Bool {
        switch self {
        case .dSharp, .gSharp, .aSharp, .cSharp, .f: true
        default: false
        }
    }

    /// 반음 단위로 이조한다.
    public func transposed(by semitones: Int) -> PitchClass {
        let index = ((rawValue + semitones) % 12 + 12) % 12
        return PitchClass(rawValue: index)!
    }

    /// MIDI 노트 번호의 피치 클래스.
    public init(midiNote: Int) {
        self = PitchClass(rawValue: ((midiNote % 12) + 12) % 12)!
    }
}

public extension Int {
    /// MIDI 노트 번호를 `C4` 같은 표기로 바꾼다.
    func midiNoteName(preferringFlats: Bool = false) -> String {
        let pitch = PitchClass(midiNote: self)
        let octave = self / 12 - 1
        return "\(pitch.name(preferringFlats: preferringFlats))\(octave)"
    }

    /// MIDI 노트 번호를 A4 = 440Hz 기준 주파수로 바꾼다.
    var midiFrequency: Double {
        440.0 * pow(2.0, (Double(self) - 69.0) / 12.0)
    }
}
