import ChordCore
import ComposableArchitecture
import Foundation

/// 루트 음 12개를 보여 주고, 고른 음의 코드 찾기 화면으로 밀어 넣는다.
@Reducer
public struct RootListFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        /// 쌓인 코드 찾기 화면들.
        public var path: StackState<ChordFinderFeature.State>

        public init(path: StackState<ChordFinderFeature.State> = .init()) {
            self.path = path
        }

        /// 지금 열려 있는 코드 찾기 화면의 루트.
        public var openedRoot: PitchClass? { path.last?.root }
    }

    public enum Action: Equatable {
        case path(StackActionOf<ChordFinderFeature>)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            ChordFinderFeature()
        }
    }
}

public extension PitchClass {
    /// 리스트에서 미리 보여 줄 메이저 3화음 구성음. (예: `C E G`)
    var majorTriadPreview: String {
        Chord(root: self, quality: .major).pitchNames.joined(separator: " ")
    }
}
