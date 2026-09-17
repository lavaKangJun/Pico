import ChordCore
import ComposableArchitecture
import GoogleMobileAds
import SwiftUI
import UIKit

/// AdMob 설정값.
public enum AdMob {
    /// 배너 광고 단위 ID. AdMob 콘솔에서 발급받은 실제 단위다.
    ///
    /// - Important: 실제 단위라 이제 진짜 광고가 실린다. **자기 광고를 누르면 안 된다.**
    ///   무효 트래픽으로 잡혀 수익 차감이나 계정 정지로 돌아온다. 시뮬레이터는 SDK가
    ///   자동으로 테스트 기기로 취급하므로 안전하고, 실기기로 확인할 때는 AdMob 콘솔에
    ///   테스트 기기를 먼저 등록한다.
    public static let bannerAdUnitID = "ca-app-pub-4602481899762111/3854820761"

    /// 전면 광고 단위 ID. 배너와 마찬가지로 AdMob 콘솔에서 발급받은 실제 단위다.
    public static let interstitialAdUnitID = "ca-app-pub-4602481899762111/8386936026"

    /// true면 6화음·7화음·텐션을 누를 때마다 전면 광고를 먼저 보여 준다.
    ///
    /// 개발 중에 광고 없이 화면을 넘겨 보고 싶을 때 false로 내린다.
    /// 배포 빌드에서는 true여야 한다.
    public static let showsInterstitialForLockedCategories = true

    /// 앱을 켤 때 한 번 호출한다. 초기화 전에 요청한 광고는 로드되지 않는다.
    @MainActor
    public static func start() {
        // 연령 등급 4+로 내는 앱이라 광고도 전체 이용가로 제한한다. 이걸 지정하지 않으면
        // 성인 지향 광고까지 실릴 수 있다. AdMob 콘솔에도 같은 제한이 있지만, 콘솔 설정이
        // 바뀌어도 앱이 스스로 지키도록 코드에 둔다.
        MobileAds.shared.requestConfiguration.maxAdContentRating = .general

        // 동의를 받은 뒤에 SDK를 켠다. 유럽에서 동의 없이 광고를 요청하면 노출이 빠진다.
        // 광고 요청은 모두 지연돼 있어(배너는 코드 찾기 화면, 전면 광고는 분류를 누를 때)
        // 여기서 몇백 밀리초 늦어도 첫 광고를 놓치지 않는다.
        AdConsent.gather {
            MobileAds.shared.start()
        }
    }
}

/// 화면 폭에 맞춰 크기가 정해지는 앵커드 배너.
public struct AdBannerView: View {
    private let adUnitID: String
    /// 배너를 감싼 좌우 여백. 광고 폭을 계산할 때 뺀다.
    private let horizontalInset: CGFloat
    /// 광고를 받아 오기 전/후 상태. 실패하면 자리를 통째로 접는다.
    @State private var phase: Phase = .loading

    private enum Phase: Equatable {
        case loading
        case loaded(height: CGFloat)
        case failed
    }

    public init(adUnitID: String = AdMob.bannerAdUnitID, horizontalInset: CGFloat = 0) {
        self.adUnitID = adUnitID
        self.horizontalInset = horizontalInset
    }

    public var body: some View {
        let size = adSize
        Group {
            if phase != .failed {
                BannerRepresentable(
                    adUnitID: adUnitID,
                    adSize: size,
                    onLoad: { phase = .loaded(height: $0) },
                    onFailure: { phase = .failed }
                )
                .frame(width: size.size.width, height: height(default: size.size.height))
                // 배너 크기에 딱 맞는 네모난 자리. 둥근 모서리를 주면 광고가 잘려 보인다.
                .background(Theme.card)
                .clipShape(Rectangle())
            }
        }
        .animation(.easeOut(duration: 0.2), value: phase)
    }

    /// 광고를 받기 전에는 요청한 높이로 자리를 잡아 둔다.
    private func height(default requested: CGFloat) -> CGFloat {
        if case let .loaded(height) = phase { height } else { requested }
    }

    /// 창 너비에서 여백을 뺀 폭으로 배너 크기를 구한다. (아이패드 분할 화면도 따라간다)
    private var adSize: AdSize {
        let windowWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.bounds.width ?? 320
        return currentOrientationAnchoredAdaptiveBanner(width: windowWidth - horizontalInset * 2)
    }
}

private struct BannerRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize
    let onLoad: (CGFloat) -> Void
    let onFailure: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoad: onLoad, onFailure: onFailure)
    }

    func makeUIView(context: Context) -> BannerView {
        context.coordinator.requestedSize = adSize.size
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = rootViewController
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        context.coordinator.onLoad = onLoad
        context.coordinator.onFailure = onFailure
        // 회전이나 분할 화면으로 폭이 달라졌을 때만 다시 받아 온다.
        //
        // 광고가 실리면 banner.adSize가 실제로 내려온 크기로 바뀌므로, 그 값과 비교하면
        // "요청과 다르다 → 다시 요청"을 끝없이 반복하게 된다. 요청한 크기를 따로 들고 비교한다.
        guard context.coordinator.requestedSize != adSize.size else { return }
        context.coordinator.requestedSize = adSize.size
        banner.adSize = adSize
        banner.load(Request())
    }

    @MainActor
    final class Coordinator: NSObject, BannerViewDelegate {
        @Dependency(\.crashReporter) private var crashReporter

        var onLoad: (CGFloat) -> Void
        var onFailure: () -> Void
        /// 마지막으로 요청한 크기. 내려온 광고 크기와 헷갈리지 않으려고 따로 둔다.
        var requestedSize: CGSize?

        init(onLoad: @escaping (CGFloat) -> Void, onFailure: @escaping () -> Void) {
            self.onLoad = onLoad
            self.onFailure = onFailure
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            // 요청한 크기보다 큰 광고가 오면 잘리므로 실제 높이에 맞춘다.
            let height = bannerView.adSize.size.height
            guard height > 0 else { return }
            onLoad(height)
        }

        func bannerView(_: BannerView, didFailToReceiveAdWithError error: any Error) {
            // 광고는 앱의 본질 기능이 아니므로, 못 받으면 빈 카드를 남기지 않고 자리를 접는다.
            // 다만 왜 못 받았는지는 남긴다. 계정·단위 설정 문제와 단순 no fill을 구분해야 한다.
            let reason = error.localizedDescription
            // record가 아니라 log다. 배너 no fill은 흔한 일이라 비치명적 에러로 올리면
            // 콘솔이 그걸로 도배돼 정작 봐야 할 것이 묻힌다. 크래시가 났을 때 함께 실리는
            crashReporter.log("배너 실패: \(reason)")
            onFailure()
        }
    }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController
    }
}
