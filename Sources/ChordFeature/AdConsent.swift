import UIKit
import UserMessagingPlatform
import os

/// 광고 동의(UMP)를 받아 오는 곳.
///
/// 유럽·영국 사용자에게 광고를 실으려면 구글이 인증한 동의 양식으로 동의를 받아야 한다.
/// 동의 흐름이 없으면 비개인화 광고조차 실리지 않아 그 지역 노출이 통째로 빠진다.
/// 규제 대상 미국 주에도 같은 구조가 적용된다 (AdMob의 "미국 주 규정" 메시지).
/// 그 밖의 지역에서는 "양식이 필요 없다"고 내려오므로, 아래 흐름은 대부분의 사용자에게
/// 아무 화면도 띄우지 않고 지나간다.
///
/// `UserMessagingPlatform`은 GoogleMobileAds 패키지가 함께 들고 오므로 따로 선언하지 않는다.
enum AdConsent {
    private static let logger = Logger(subsystem: "com.lavakangjun.pico", category: "ad-consent")

    /// 뷰가 볼 수 있는 동의 상태.
    ///
    /// `privacyOptionsRequirementStatus`는 동의 정보 갱신이 끝난 뒤에야 유효하다. 뷰가 그릴
    /// 때 바로 읽으면 아직 `unknown`이라, 갱신이 끝날 때 여기에 옮겨 담아 뷰에 알린다.
    @MainActor
    @Observable
    final class Status {
        static let shared = Status()

        /// 동의를 나중에 바꿀 경로를 앱이 제공해야 하는지. 유럽과 규제 대상 미국 주에서 true가 된다.
        var isPrivacyOptionsRequired = false

        private init() {}
    }

    /// 동의 정보를 갱신하고, 필요하면 양식을 띄운 뒤 `completion`을 부른다.
    ///
    /// 실패해도 `completion`은 반드시 부른다. 동의를 못 받았다고 앱이 멈출 이유는 없고,
    /// 동의가 필요한 지역이면 광고 노출만 빠진다 — 코드를 찾아보는 기능은 그대로 돈다.
    @MainActor
    static func gather(then completion: @escaping @Sendable @MainActor () -> Void) {
        // 아동을 주 대상으로 하는 앱이 아니므로 기본 파라미터를 쓴다.
        let parameters = RequestParameters()
        #if DEBUG
            if let debug = debugSettings {
                parameters.debugSettings = debug
                // 한 번 동의하면 다시 묻지 않으므로, 미리 보기에서는 매번 지운다.
                ConsentInformation.shared.reset()
            }
        #endif

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
            // UMP는 메인 스레드로 콜백하지만 그 보장을 타입으로 표현할 수 없어 다시 올린다.
            Task { @MainActor in
                if let error {
                    logger.error("동의 정보 갱신 실패: \(error.localizedDescription, privacy: .public)")
                    completion()
                    return
                }
                presentFormIfRequired(then: completion)
            }
        }
    }

    /// 동의가 필요한 지역이면 양식을 띄우고, 아니면 곧바로 넘어간다.
    @MainActor
    private static func presentFormIfRequired(then completion: @escaping @Sendable @MainActor () -> Void) {
        ConsentForm.loadAndPresentIfRequired(from: rootViewController) { error in
            Task { @MainActor in
                if let error {
                    logger.error("동의 양식 표시 실패: \(error.localizedDescription, privacy: .public)")
                }
                // 동의를 받지 못하면 false다. 이 값이 false인 지역에서는 광고가 실리지 않는다.
                logger.info("광고 요청 가능: \(ConsentInformation.shared.canRequestAds, privacy: .public)")
                Status.shared.isPrivacyOptionsRequired =
                    ConsentInformation.shared.privacyOptionsRequirementStatus == .required
                completion()
            }
        }
    }

    /// 이미 한 동의를 다시 고르는 양식. 동의 양식이 "앱에서 이 경로를 찾으라"고 안내하므로,
    /// 그 안내가 가리키는 곳이 실제로 있어야 한다.
    @MainActor
    static func presentPrivacyOptions() {
        ConsentForm.presentPrivacyOptionsForm(from: rootViewController) { error in
            Task { @MainActor in
                if let error {
                    logger.error("개인정보 설정 양식 실패: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    /// 양식을 띄울 화면. 앱을 켠 직후라 아직 없을 수 있고, 그때는 UMP가 알아서 건너뛴다.
    @MainActor
    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController
    }

    #if DEBUG
        /// 특정 지역으로 위장해 동의 양식을 미리 보는 스위치.
        ///
        ///     xcrun simctl launch <udid> com.lavakangjun.pico -PicoConsentGeography eea
        ///     xcrun simctl launch <udid> com.lavakangjun.pico -PicoConsentGeography us
        ///
        /// 인수가 없으면 nil이라 평소 실행에는 영향이 없다. 시뮬레이터는 UMP가 언제나
        /// 디버그 기기로 취급하므로 기기 ID를 등록할 필요가 없다. 실기기로 볼 때는
        /// 로그에 찍히는 해시 ID를 `testDeviceIdentifiers`에 넣어야 한다.
        private static var debugSettings: DebugSettings? {
            let geography: DebugGeography? =
                switch UserDefaults.standard.string(forKey: "PicoConsentGeography")?.lowercased() {
                case "eea": .EEA
                case "us": .regulatedUSState
                default: nil
                }
            guard let geography else { return nil }

            let settings = DebugSettings()
            settings.geography = geography
            return settings
        }
    #endif
}
