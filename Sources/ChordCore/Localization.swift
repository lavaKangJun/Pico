import Foundation

extension Bundle {
    /// ChordCore의 번역 리소스가 담긴 번들.
    static let chordCore = Bundle.module
}

/// ChordCore 번들에서 번역을 찾는다. 키는 한국어 원문이다.
func localized(_ key: String) -> String {
    NSLocalizedString(key, bundle: .chordCore, comment: "")
}
