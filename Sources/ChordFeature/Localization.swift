import Foundation

public extension Bundle {
    /// ChordFeature의 번역 리소스가 담긴 번들.
    ///
    /// SwiftUI의 `Text`는 기본적으로 메인 번들을 보므로, 모듈 안에서는
    /// `Text("키", bundle: .chordFeature)`처럼 번들을 직접 지정한다.
    static let chordFeature = Bundle.module
}

/// ChordFeature 번들에서 번역을 찾는다. 키는 한국어 원문이다.
func localized(_ key: String) -> String {
    NSLocalizedString(key, bundle: .chordFeature, comment: "")
}
