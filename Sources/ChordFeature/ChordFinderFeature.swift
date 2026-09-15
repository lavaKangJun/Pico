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

        public init(
            root: PitchClass = .c,
            quality: ChordQuality = .major,
            inversion: Int = 0,
            octave: Int = 4,
            style: PlaybackStyle = .block
        ) {
            self.root = root
            self.quality = quality
            category = quality.category
            self.inversion = inversion
            self.octave = octave
            self.style = style
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
    }

    @Dependency(\.audioPlayer) var audioPlayer

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .rootTapped(root):
                state.root = root
                return play(state)

            case let .categoryTapped(category):
                guard state.category != category else { return .none }
                state.category = category
                // 분류를 바꾸면 그 분류의 첫 코드로 옮겨 간다.
                if let first = ChordQuality.all(in: category).first, first != state.quality {
                    state.quality = first
                    state.clampInversion()
                    return play(state)
                }
                return .none

            case let .qualityTapped(quality):
                state.quality = quality
                state.clampInversion()
                return play(state)

            case let .inversionTapped(inversion):
                state.inversion = inversion
                return play(state)

            case let .octaveStepped(delta):
                state.octave = max(2, min(6, state.octave + delta))
                return play(state)

            case .playButtonTapped:
                return play(state)

            case let .keyTapped(note):
                return .run { _ in await audioPlayer.play(note: note) }
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
    /// 코드가 바뀌어 전위 수가 줄면 범위 안으로 되돌린다.
    mutating func clampInversion() {
        inversion = min(inversion, chord.inversionCount - 1)
    }
}
