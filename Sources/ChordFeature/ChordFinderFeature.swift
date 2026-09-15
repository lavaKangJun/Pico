import ChordCore
import ComposableArchitecture
import Foundation

/// 루트와 코드 성질을 골라 구성음을 확인하고 소리로 들어 보는 화면.
@Reducer
public struct ChordFinderFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var root: PitchClass
        public var quality: ChordQuality
        public var category: ChordQuality.Category
        public var inversion: Int
        public var octave: Int
        public var style: PlaybackStyle
        /// true면 잠긴 분류를 누를 때마다 전면 광고를 먼저 보여 준다.
        public var requiresAdForLockedCategories: Bool
        /// 광고를 띄우고 닫히기를 기다리는 중.
        public var isWaitingForAd: Bool

        public init(
            root: PitchClass = .c,
            quality: ChordQuality = .major,
            inversion: Int = 0,
            octave: Int = 4,
            style: PlaybackStyle = .block,
            requiresAdForLockedCategories: Bool = AdMob.showsInterstitialForLockedCategories
        ) {
            self.root = root
            self.quality = quality
            category = quality.category
            self.inversion = inversion
            self.octave = octave
            self.style = style
            self.requiresAdForLockedCategories = requiresAdForLockedCategories
            isWaitingForAd = false
        }

        /// 이 분류를 보려면 광고를 봐야 하는지. 누를 때마다 다시 봐야 한다.
        public func requiresAd(for category: ChordQuality.Category) -> Bool {
            requiresAdForLockedCategories && category != .triad
        }

        /// 광고를 봐야 열리는 분류.
        public var lockedCategories: [ChordQuality.Category] {
            ChordQuality.Category.allCases.filter { requiresAd(for: $0) }
        }

        public var chord: Chord { Chord(root: root, quality: quality) }

        public var midiNotes: [Int] { chord.midiNotes(octave: octave, inversion: inversion) }

        /// 지금 분류에서 고를 수 있는 코드 성질.
        public var qualities: [ChordQuality] { ChordQuality.all(in: category) }

        /// 전위 선택지. (기본 위치 포함)
        public var inversionOptions: [Int] { Array(0 ..< chord.inversionCount) }

        public var symbol: String { chord.symbol(inversion: inversion) }

        /// 옥타브를 더 내리거나 올릴 수 있는지.
        public var canLowerOctave: Bool { octave > 2 }
        public var canRaiseOctave: Bool { octave < 6 }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case rootTapped(PitchClass)
        case categoryTapped(ChordQuality.Category)
        case qualityTapped(ChordQuality)
        case inversionTapped(Int)
        case octaveStepped(Int)
        case playButtonTapped
        case keyTapped(Int)
        case viewAppeared
        /// 전면 광고가 닫혔다. 끝까지 봤으면 그 분류를 열어 준다.
        case interstitialFinished(category: ChordQuality.Category, watched: Bool)
    }

    @Dependency(\.audioPlayer) var audioPlayer
    @Dependency(\.interstitialAd) var interstitialAd

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .rootTapped(root):
                state.root = root
                return .none

            case let .categoryTapped(category):
                guard state.category != category else { return .none }
                guard !state.requiresAd(for: category) else {
                    // 3화음이 아닌 분류는 누를 때마다 광고를 끝까지 봐야 열린다.
                    state.isWaitingForAd = true
                    return .run { send in
                        let watched = await interstitialAd.show()
                        await send(.interstitialFinished(category: category, watched: watched))
                    }
                }
                state.open(category)
                return .none

            case let .interstitialFinished(category, watched):
                state.isWaitingForAd = false
                guard watched else { return .none }
                state.open(category)
                return .none

            case let .qualityTapped(quality):
                state.quality = quality
                state.clampInversion()
                return .none

            case let .inversionTapped(inversion):
                state.inversion = inversion
                return .none

            case let .octaveStepped(delta):
                state.octave = max(2, min(6, state.octave + delta))
                return .none

            case .playButtonTapped:
                return play(state)

            case let .keyTapped(note):
                return .run { _ in await audioPlayer.play(note: note) }

            case .viewAppeared:
                // 잠긴 분류를 누르는 순간 기다리지 않도록 미리 받아 둔다.
                guard state.requiresAdForLockedCategories else { return .none }
                return .run { _ in await interstitialAd.prepare() }
            }
        }
    }

    private func play(_ state: State) -> Effect<Action> {
        .run { [notes = state.midiNotes, style = state.style] _ in
            await audioPlayer.play(notes, style)
        }
    }
}

private extension ChordFinderFeature.State {
    /// 분류를 바꾸고 그 분류의 첫 코드로 옮겨 간다.
    mutating func open(_ category: ChordQuality.Category) {
        self.category = category
        guard let first = ChordQuality.all(in: category).first, first != quality else { return }
        quality = first
        clampInversion()
    }

    /// 코드가 바뀌어 전위 수가 줄면 범위 안으로 되돌린다.
    mutating func clampInversion() {
        inversion = min(inversion, chord.inversionCount - 1)
    }
}
