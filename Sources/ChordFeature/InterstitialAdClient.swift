import ComposableArchitecture
import GoogleMobileAds
import SwiftUI
import UIKit

/// 전면 광고를 띄우는 의존성.
///
/// 리듀서는 "광고를 끝까지 보여 줬는가"만 알면 되므로, 성공 여부만 돌려준다.
public struct InterstitialAdClient: Sendable {
    /// 미리 받아 둔다. 광고가 준비돼 있어야 기다림 없이 뜬다.
    public var prepare: @Sendable () async -> Void
    /// 광고를 띄우고 닫힐 때까지 기다린다. 못 띄우면 `false`.
    public var show: @Sendable () async -> Bool

    public init(
        prepare: @escaping @Sendable () async -> Void,
        show: @escaping @Sendable () async -> Bool
    ) {
        self.prepare = prepare
        self.show = show
    }
}

extension InterstitialAdClient: DependencyKey {
    // 발표자는 @MainActor라서 의존성 초기화 시점(메인 아닌 곳)에 만들면 안 된다.
    // 클로저 안에서 처음 쓸 때 메인에서 만들어진다.
    public static let liveValue = InterstitialAdClient(
        prepare: { await InterstitialPresenter.shared.prepare() },
        show: { await InterstitialPresenter.shared.show() }
    )

    /// 프리뷰와 테스트에서는 광고를 띄우지 않고 통과시킨다.
    public static let testValue = InterstitialAdClient(prepare: {}, show: { true })
    public static let previewValue = testValue
}

public extension DependencyValues {
    var interstitialAd: InterstitialAdClient {
        get { self[InterstitialAdClient.self] }
        set { self[InterstitialAdClient.self] = newValue }
    }
}

/// 전면 광고를 하나 들고 있다가 띄우고, 닫힐 때까지 기다린다.
@MainActor
private final class InterstitialPresenter: NSObject {
    static let shared = InterstitialPresenter()

    private var ad: InterstitialAd?
    /// 광고가 닫히기를 기다리는 쪽.
    private var dismissal: CheckedContinuation<Bool, Never>?

    func prepare() async {
        guard ad == nil else { return }
        ad = try? await InterstitialAd.load(with: AdMob.interstitialAdUnitID, request: Request())
    }

    func show() async -> Bool {
        if ad == nil { await prepare() }
        guard
            let ad,
            let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.keyWindow?.rootViewController
        else { return false }

        ad.fullScreenContentDelegate = self
        self.ad = nil

        let watched = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            dismissal = continuation
            ad.present(from: root)
        }

        // 다음 번을 위해 미리 받아 둔다.
        Task { await prepare() }
        return watched
    }

    private func finish(_ watched: Bool) {
        dismissal?.resume(returning: watched)
        dismissal = nil
    }
}

extension InterstitialPresenter: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_: any FullScreenPresentingAd) {
        finish(true)
    }

    func ad(_: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError _: any Error) {
        finish(false)
    }
}
