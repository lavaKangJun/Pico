import GoogleMobileAds
import SwiftUI
import UIKit

/// AdMob 설정값.
public enum AdMob {
    /// 배너 광고 단위 ID.
    ///
    /// - Important: 지금 값은 구글이 공개한 **테스트 단위**다. 실제 광고와 수익이 나가려면
    ///   AdMob 콘솔에서 발급받은 ID로 바꾸고, `Project.swift`의 `GADApplicationIdentifier`도
    ///   같이 바꿔야 한다.
    public static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"

    /// 전면 광고 단위 ID. 이것도 구글 테스트 단위다.
    public static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"

    /// true면 6화음·7화음·텐션을 누를 때마다 전면 광고를 먼저 보여 준다.
    ///
    /// 개발 중에 광고 없이 화면을 넘겨 보고 싶을 때 false로 내린다.
    /// 배포 빌드에서는 true여야 한다.
    public static let showsInterstitialForLockedCategories = true

    /// 앱을 켤 때 한 번 호출한다. 초기화 전에 요청한 광고는 로드되지 않는다.
    @MainActor
    public static func start() {
        MobileAds.shared.start()
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

        func bannerView(_: BannerView, didFailToReceiveAdWithError _: any Error) {
            // 광고는 앱의 본질 기능이 아니므로, 못 받으면 빈 카드를 남기지 않고 자리를 접는다.
            onFailure()
        }
    }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController
    }
}
