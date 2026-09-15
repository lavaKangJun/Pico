import ComposableArchitecture
import SwiftUI

public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        // 지금은 코드 찾기 흐름만 보여 준다.
        // 코드 진행 화면은 리듀서와 뷰를 그대로 둔 채 화면에서만 빼 놓았다.
        RootListView(store: store.scope(state: \.roots, action: \.roots))
            .tint(Theme.accent)
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) {
        AppFeature()
    })
}
