import ChordCore
import ChordFeature
import ComposableArchitecture
import SwiftUI

@main
struct PicoApp: App {
    /// 앱이 살아 있는 동안 유지되는 단일 스토어.
    @MainActor
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
        #if DEBUG
            ._printChanges()
        #endif
    }

    init() {
        // 크래시 리포터가 제일 먼저다. 그래야 AdMob 초기화 중에 나는 크래시도 잡힌다.
        // Firebase가 안 켜졌으면 no-op 기본값을 그대로 둔다. (Crashlytics를 부르면 죽는다)
        if CrashReporting.start() {
            prepareDependencies { $0.crashReporter = .firebase }
        }
        AdMob.start()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
