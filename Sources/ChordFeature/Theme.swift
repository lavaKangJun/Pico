import ChordCore
import SwiftUI
import UIKit

/// 앱 전체에서 쓰는 색과 간격.
enum Theme {
    static let accent = Color(red: 0.29, green: 0.365, blue: 0.851)
    static let root = Color(red: 0.91, green: 0.33, blue: 0.42)
    static let tone = Color(red: 0.29, green: 0.365, blue: 0.851)

    static let cornerRadius: CGFloat = 14
    /// 목록 카드는 좀 더 둥글다.
    static let listCornerRadius: CGFloat = 20

    /// 카드 배경.
    static var card: Color { Color(.secondarySystemGroupedBackground) }
    static var groupedBackground: Color { Color(.systemGroupedBackground) }

    /// 밝을 때와 어두울 때 다른 색을 쓴다.
    private static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }

    /// 화면 배경. 옅은 보라를 깐다.
    ///
    /// 두 가지를 지켜야 한다.
    ///
    /// 하나, **단색이어야 한다.** 카드가 반투명이라 뒤 배경색을 그대로 빨아들이므로,
    /// 그러데이션을 깔면 카드가 놓인 높이마다 색이 달라져 섹션끼리 톤이 갈린다.
    ///
    /// 둘, **너무 진하면 안 된다.** 머티리얼은 뒤 색을 밝히고 채도를 빼서 그린다. 배경을
    /// 진하게 깔면 카드가 렌더된 색과 벌어져, 마지막 카드 아래처럼 배경이 그대로 드러나는
    /// 자리만 어둡고 보랏빛으로 뜬다. 카드가 실제로 그려지는 색에 맞춰 잡아 둔 값이다.
    static var listBackground: Color {
        dynamic(
            light: Color(red: 0.961, green: 0.961, blue: 0.976),
            dark: Color(red: 0.086, green: 0.086, blue: 0.106)
        )
    }

    /// 카드 면. **불투명이어야 한다.**
    ///
    /// 머티리얼로 채우면 카드가 자기 그림자까지 비춰서, 그림자가 짙게 깔리는 정도가
    /// 카드 크기와 모양을 따라 달라진다. 그래서 섹션마다 미묘하게 다른 색이 된다.
    /// 배경을 단색으로 맞춰도 이건 안 없어진다. 한 번 그렇게 했다가 걷어냈다.
    ///
    /// 값은 머티리얼이 실제로 그리던 색을 그대로 옮긴 것이라 보이는 느낌은 같다.
    static var cardSurface: Color {
        dynamic(
            light: Color(red: 0.965, green: 0.963, blue: 0.976),
            dark: Color(red: 0.161, green: 0.161, blue: 0.169)
        )
    }

    /// 카드가 배경에서 살짝 떠 보이게 하는 그림자. 어두울 때는 거의 보이지 않는다.
    static var cardShadow: Color {
        dynamic(light: Color.black.opacity(0.06), dark: Color.black.opacity(0.35))
    }

    /// 반투명 카드의 가장자리. 머티리얼만으로는 경계가 흐려 한 겹 얹는다.
    static var cardBorder: Color {
        dynamic(light: Color.white.opacity(0.7), dark: Color.white.opacity(0.10))
    }

    /// 반투명 카드 위에 얹는 옅은 칸. 머티리얼을 겹쳐 쓰면 탁해져 단색으로 깐다.
    static var chipBackground: Color {
        dynamic(light: Color.black.opacity(0.05), dark: Color.white.opacity(0.09))
    }

    /// 어두울 때 쓰는 밝은 강조색.
    ///
    /// `accent`는 꽤 어두운 파랑이라 어두운 배경에 글씨로 얹으면 대비가 2.4:1까지 떨어진다.
    /// 면을 칠할 때는 `accent`, 글씨나 아이콘에 쓸 때는 `accentOnSurface`를 쓴다.
    private static let brightAccent = Color(red: 0.62, green: 0.68, blue: 1.0)

    static var accentOnSurface: Color { dynamic(light: accent, dark: brightAccent) }

    /// 고른 칸. 강조색을 옅게 깔고 글씨도 강조색으로 쓴다.
    ///
    /// 강조색을 꽉 채우고 흰 글씨를 얹으면 유리 카드 위에서 혼자 단단해 보인다. 그렇다고
    /// 채운 색에 알파를 주면 흰 글씨 대비가 3:1 아래로 떨어진다. 배경만 옅게 깔고 글씨를
    /// 강조색으로 두면 대비는 5:1을 넘으면서 배경이 비친다.
    static var selectedChip: Color {
        dynamic(light: accent.opacity(0.18), dark: brightAccent.opacity(0.20))
    }

    /// 옅게 깐 칸이 "골랐다"로 읽히도록 두르는 선.
    static var selectedChipBorder: Color {
        dynamic(light: accent.opacity(0.45), dark: brightAccent.opacity(0.55))
    }

    // MARK: - 루트 배지

    /// 12음마다 다른 배지 색.
    ///
    /// 흰 글씨를 얹으므로 밝은 쪽 끝도 대비 3:1을 넘도록 눌러 뒀다. 파스텔로 더 밝히면
    /// 예쁘긴 해도 글자가 읽히지 않는다.
    private static let badgeColors: [(Color, Color)] = [
        (Color(red: 0.357, green: 0.388, blue: 0.910), Color(red: 0.482, green: 0.357, blue: 0.910)), // C
        (Color(red: 0.510, green: 0.341, blue: 0.878), Color(red: 0.643, green: 0.353, blue: 0.847)), // C♯/D♭
        (Color(red: 0.878, green: 0.314, blue: 0.498), Color(red: 0.910, green: 0.392, blue: 0.565)), // D
        (Color(red: 0.133, green: 0.651, blue: 0.498), Color(red: 0.204, green: 0.722, blue: 0.553)), // D♯/E♭
        (Color(red: 0.231, green: 0.561, blue: 0.851), Color(red: 0.310, green: 0.639, blue: 0.878)), // E
        (Color(red: 0.482, green: 0.420, blue: 0.851), Color(red: 0.588, green: 0.514, blue: 0.890)), // F
        (Color(red: 0.788, green: 0.396, blue: 0.122), Color(red: 0.831, green: 0.463, blue: 0.184)), // F♯/G♭
        (Color(red: 0.118, green: 0.620, blue: 0.620), Color(red: 0.169, green: 0.690, blue: 0.675)), // G
        (Color(red: 0.655, green: 0.353, blue: 0.816), Color(red: 0.769, green: 0.424, blue: 0.769)), // G♯/A♭
        (Color(red: 0.298, green: 0.435, blue: 0.878), Color(red: 0.369, green: 0.525, blue: 0.910)), // A
        (Color(red: 0.878, green: 0.357, blue: 0.388), Color(red: 0.910, green: 0.451, blue: 0.459)), // A♯/B♭
        (Color(red: 0.180, green: 0.588, blue: 0.769), Color(red: 0.251, green: 0.663, blue: 0.824)), // B
    ]

    static func badge(for pitch: PitchClass) -> LinearGradient {
        let (start, end) = badgeColors[pitch.rawValue]
        return LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// 배지 아래에 같은 색으로 옅게 깔아 떠 있는 느낌을 준다.
    static func badgeGlow(for pitch: PitchClass) -> Color {
        badgeColors[pitch.rawValue].0.opacity(0.25)
    }
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
    ///
    func cardStyle() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassBackground()
    }

    /// 카드 면 + 가장자리 + 그림자. 목록 줄과 상세 화면 카드가 같은 모양을 쓴다.
    func glassBackground(cornerRadius: CGFloat = Theme.listCornerRadius) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(Theme.cardSurface, in: shape)
            .overlay(shape.strokeBorder(Theme.cardBorder, lineWidth: 0.5))
            // 카드 간격이 12~16pt다. 반경을 더 키우면 위 카드의 그림자가 아래 카드에 얹혀,
            // 맨 위 카드만 깨끗하고 나머지는 윗부분이 어두워진다.
            .shadow(color: Theme.cardShadow, radius: 5, x: 0, y: 2)
    }
}
