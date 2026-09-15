import ChordCore
import ComposableArchitecture
import Foundation

/// 코드 진행을 골라 한 마디씩 들어 보는 화면.
@Reducer
public struct ProgressionFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var key: PitchClass
        public var progression: ChordProgression
        public var selectedIndex: Int?
        public var isPlaying: Bool
        /// 분당 박자 수. 코드 하나가 두 박을 차지한다.
        public var tempo: Double

        public init(
            key: PitchClass = .c,
            progression: ChordProgression = .pop,
            tempo: Double = 92
        ) {
            self.key = key
            self.progression = progression
            selectedIndex = nil
            isPlaying = false
            self.tempo = tempo
        }

        public var chords: [Chord] { progression.chords(inKey: key) }

        public var selectedChord: Chord? {
            guard let selectedIndex, chords.indices.contains(selectedIndex) else { return nil }
            return chords[selectedIndex]
        }

        /// 코드 하나가 울리는 시간(초).
        public var chordDuration: Double { 120.0 / tempo }

        public var keyName: String {
            key.name(preferringFlats: key.prefersFlatSpelling) + progression.tonality.suffix
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case keyTapped(PitchClass)
        case progressionTapped(ChordProgression)
        case chordTapped(Int)
        case playAllButtonTapped
        case stopButtonTapped
        case playbackAdvanced(Int)
        case playbackFinished
    }

    private enum CancelID { case playback }

    @Dependency(\.audioPlayer) var audioPlayer
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .keyTapped(key):
                state.key = key
                return .none

            case let .progressionTapped(progression):
                state.progression = progression
                state.selectedIndex = nil
                return stopPlayback(&state)

            case let .chordTapped(index):
                guard state.chords.indices.contains(index) else { return .none }
                state.selectedIndex = index
                let chord = state.chords[index]
                return .merge(
                    stopPlayback(&state),
                    .run { _ in await audioPlayer.play(chord: chord) }
                )

            case .playAllButtonTapped:
                state.isPlaying = true
                return .run { [chords = state.chords, duration = state.chordDuration] send in
                    for (index, chord) in chords.enumerated() {
                        await send(.playbackAdvanced(index), animation: .easeOut(duration: 0.15))
                        await audioPlayer.play(chord: chord)
                        try await clock.sleep(for: .seconds(duration))
                    }
                    await send(.playbackFinished)
                }
                .cancellable(id: CancelID.playback)

            case .stopButtonTapped:
                return stopPlayback(&state)

            case let .playbackAdvanced(index):
                state.selectedIndex = index
                return .none

            case .playbackFinished:
                state.isPlaying = false
                return .none
            }
        }
    }

    private func stopPlayback(_ state: inout State) -> Effect<Action> {
        guard state.isPlaying else { return .cancel(id: CancelID.playback) }
        state.isPlaying = false
        return .merge(
            .cancel(id: CancelID.playback),
            .run { _ in await audioPlayer.stop() }
        )
    }
}
