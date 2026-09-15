import Foundation

/// 코드의 루트로 쓰는 음이름.
///
/// `PitchClass`가 "어떤 소리인가"라면 이쪽은 "어떻게 적는가"다.
/// C♯과 D♭은 같은 건반을 누르지만 코드 이름도 구성음 표기도 달라서 따로 둔다.
public enum NoteName: String, CaseIterable, Sendable, Hashable, Codable, Identifiable {
    case c
    case cSharp
    case dFlat
    case d
    case dSharp
    case eFlat
    case e
    case f
    case fSharp
    case gFlat
    case g
    case gSharp
    case aFlat
    case a
    case aSharp
    case bFlat
    case b

    public var id: String { rawValue }

    /// 실제로 울리는 음.
    public var pitch: PitchClass {
        switch self {
        case .c: .c
        case .cSharp, .dFlat: .cSharp
        case .d: .d
        case .dSharp, .eFlat: .dSharp
        case .e: .e
        case .f: .f
        case .fSharp, .gFlat: .fSharp
        case .g: .g
        case .gSharp, .aFlat: .gSharp
        case .a: .a
        case .aSharp, .bFlat: .aSharp
        case .b: .b
        }
    }

    /// 플랫으로 적는 음이름인지. 코드 구성음도 이 표기를 따라간다.
    public var prefersFlats: Bool {
        switch self {
        case .dFlat, .eFlat, .gFlat, .aFlat, .bFlat: true
        default: false
        }
    }

    /// 검은 건반 위의 음인지.
    public var isAccidental: Bool { pitch.isAccidental }

    /// 화면에 적는 이름. (예: `D♭`)
    public var name: String { pitch.name(preferringFlats: prefersFlats) }

    /// 계이름. 음이름과 같은 표기를 쓴다.
    public var solfege: String { pitch.solfege(preferringFlats: prefersFlats) }

    /// 같은 소리를 다르게 적은 음이름. 흰 건반은 짝이 없다.
    public var enharmonic: NoteName? {
        switch self {
        case .cSharp: .dFlat
        case .dFlat: .cSharp
        case .dSharp: .eFlat
        case .eFlat: .dSharp
        case .fSharp: .gFlat
        case .gFlat: .fSharp
        case .gSharp: .aFlat
        case .aFlat: .gSharp
        case .aSharp: .bFlat
        case .bFlat: .aSharp
        default: nil
        }
    }

    /// 반음 단위로 옮긴다. 샤프로 적는 음은 샤프로, 플랫으로 적는 음은 플랫으로 남는다.
    public func transposed(by semitones: Int) -> NoteName {
        NoteName.named(pitch.transposed(by: semitones), preferringFlats: prefersFlats)
    }

    /// 어떤 소리를 원하는 표기로 적은 음이름.
    public static func named(_ pitch: PitchClass, preferringFlats: Bool) -> NoteName {
        if preferringFlats {
            switch pitch {
            case .cSharp: return .dFlat
            case .dSharp: return .eFlat
            case .fSharp: return .gFlat
            case .gSharp: return .aFlat
            case .aSharp: return .bFlat
            default: break
            }
        }
        switch pitch {
        case .c: return .c
        case .cSharp: return .cSharp
        case .d: return .d
        case .dSharp: return .dSharp
        case .e: return .e
        case .f: return .f
        case .fSharp: return .fSharp
        case .g: return .g
        case .gSharp: return .gSharp
        case .a: return .a
        case .aSharp: return .aSharp
        case .b: return .b
        }
    }
}
