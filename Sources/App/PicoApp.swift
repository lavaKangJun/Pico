import ChordFeature
import ComposableArchitecture
import SwiftUI

@main
struct PicoApp: App {
    /// 앱이 살아 있는 동안 유지되는 단일 스토어.
    @MainActor
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    init() {
        AdMob.start()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
