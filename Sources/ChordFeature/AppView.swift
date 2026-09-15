import ComposableArchitecture
import SwiftUI

public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        TabView(selection: $store.tab) {
            NavigationStack {
                ChordFinderView(store: store.scope(state: \.finder, action: \.finder))
            }
            .tabItem {
                Label(AppFeature.Tab.finder.title, systemImage: AppFeature.Tab.finder.systemImage)
            }
            .tag(AppFeature.Tab.finder)

            NavigationStack {
                ProgressionView(store: store.scope(state: \.progression, action: \.progression))
            }
            .tabItem {
                Label(AppFeature.Tab.progression.title, systemImage: AppFeature.Tab.progression.systemImage)
            }
            .tag(AppFeature.Tab.progression)
        }
        .tint(Theme.accent)
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) {
        AppFeature()
    })
}
