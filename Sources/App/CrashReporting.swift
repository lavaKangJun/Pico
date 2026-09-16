import ChordCore
import FirebaseCore
import FirebaseCrashlytics
import Foundation
import os

/// Firebase Crashlytics를 켜는 곳.
///
/// Crashlytics는 UI도 도메인도 아닌 앱 수명주기 인프라라서 앱 타깃에만 둔다.
/// `ChordFeature`와 `ChordCore`는 Firebase를 모르는 채로 남는다.
enum CrashReporting {
    private static let logger = Logger(subsystem: "com.lavakangjun.pico", category: "crash-reporting")

    /// 앱을 켤 때 가장 먼저 호출한다. 다른 SDK가 초기화되다 죽는 것까지 잡으려면
    /// 리포터가 제일 앞에 붙어 있어야 한다.
    ///
    /// - Returns: Firebase가 실제로 켜졌는지. 꺼져 있는데 `Crashlytics.crashlytics()`를
    ///   부르면 그 자리에서 죽으므로, 부른 쪽은 이 값을 보고 의존성 주입 여부를 정한다.
    @discardableResult
    static func start() -> Bool {
        // configure()는 GoogleService-Info.plist가 없으면 예외를 던지며 앱을 세운다.
        // 여기서 막지 않으면 파일을 넣기 전까지 앱을 아예 못 띄운다. assertionFailure도
        // 같은 이유로 안 쓴다 — 크래시 리포터가 없다고 앱이 죽는 건 앞뒤가 바뀐 얘기다.
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            logger.error(
                "GoogleService-Info.plist가 번들에 없어 크래시 수집을 건너뛴다. Firebase 콘솔에서 받아 Resources/에 넣고 tuist generate를 다시 돌린다."
            )
            return false
        }

        FirebaseApp.configure()
        return true
    }
}

extension CrashReporterClient {
    /// Crashlytics로 보내는 구현. `CrashReporting.start()`가 true를 돌려준 뒤에만 쓸 수 있다.
    static let firebase = CrashReporterClient(
        recordError: { error, context in
            Crashlytics.crashlytics().record(error: error, userInfo: context.isEmpty ? nil : context)
        },
        log: { message in
            Crashlytics.crashlytics().log(message)
        },
        setKey: { key, value in
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        }
    )
}
