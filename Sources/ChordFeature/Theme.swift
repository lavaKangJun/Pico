import SwiftUI

/// 앱 전체에서 쓰는 색과 간격.
enum Theme {
    static let accent = Color(red: 0.29, green: 0.365, blue: 0.851)
    static let root = Color(red: 0.91, green: 0.33, blue: 0.42)
    static let tone = Color(red: 0.29, green: 0.365, blue: 0.851)

    static let cornerRadius: CGFloat = 14

    /// 카드 배경.
    static var card: Color { Color(.secondarySystemGroupedBackground) }
    static var groupedBackground: Color { Color(.systemGroupedBackground) }
}

/// 카드를 그대로 두고 눌린 느낌만 주는 버튼 스타일.
///
/// 목록을 List에서 카드로 바꾸면서 기본 하이라이트가 사라져, 직접 눌림 효과를 준다.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    /// 섹션 하나를 감싸는 카드 스타일.
    func cardStyle() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}
