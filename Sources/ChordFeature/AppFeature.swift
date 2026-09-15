import ChordCore
import ComposableArchitecture
import Foundation

/// 탭 두 개를 묶는 최상위 리듀서.
@Reducer
public struct AppFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var tab: Tab
        public var roots: RootListFeature.State
        public var progression: ProgressionFeature.State

        public init(
            tab: Tab = .finder,
            roots: RootListFeature.State = .init(),
            progression: ProgressionFeature.State = .init()
        ) {
            self.tab = tab
            self.roots = roots
            self.progression = progression
        }
    }

    public enum Tab: String, CaseIterable, Sendable, Hashable {
        case finder
        case progression

        public var title: String {
            switch self {
            case .finder: "코드 찾기"
            case .progression: "코드 진행"
            }
        }

        public var systemImage: String {
            switch self {
            case .finder: "pianokeys"
            case .progression: "music.note.list"
            }
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case roots(RootListFeature.Action)
        case progression(ProgressionFeature.Action)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.roots, action: \.roots) {
            RootListFeature()
        }

        Scope(state: \.progression, action: \.progression) {
            ProgressionFeature()
        }

        Reduce { _, _ in .none }
    }
}
