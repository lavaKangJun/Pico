import ChordCore
@testable import ChordFeature
import ComposableArchitecture
import Testing

@MainActor
@Suite("코드 진행 화면")
struct ProgressionFeatureTests {
    @Test("진행 듣기는 코드를 하나씩 짚고 끝난다")
    func playsThroughProgression() async {
        let clock = TestClock()
        let store = TestStore(initialState: ProgressionFeature.State(tempo: 120)) {
            ProgressionFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        #expect(store.state.chordDuration == 1)

        await store.send(.playAllButtonTapped) {
            $0.isPlaying = true
        }

        for index in 0 ..< 4 {
            await store.receive(.playbackAdvanced(index)) {
                $0.selectedIndex = index
            }
            await clock.advance(by: .seconds(1))
        }

        await store.receive(.playbackFinished) {
            $0.isPlaying = false
        }
    }

    @Test("정지하면 재생이 취소된다")
    func stopsPlayback() async {
        let clock = TestClock()
        let store = TestStore(initialState: ProgressionFeature.State()) {
            ProgressionFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.playAllButtonTapped) {
            $0.isPlaying = true
        }
        await store.receive(.playbackAdvanced(0)) {
            $0.selectedIndex = 0
        }
        await store.send(.stopButtonTapped) {
            $0.isPlaying = false
        }
    }

    @Test("조를 옮기면 진행 전체가 이조된다")
    func transposesProgression() async {
        let store = TestStore(initialState: ProgressionFeature.State()) {
            ProgressionFeature()
        }

        await store.send(.keyTapped(.a)) {
            $0.key = .a
        }
        #expect(store.state.chords.map(\.symbol) == ["A", "E", "F♯m", "D"])
    }

    @Test("코드를 누르면 그 코드가 선택되고 재생된다")
    func playsSingleChord() async {
        let played = LockIsolated<[[Int]]>([])
        let store = TestStore(initialState: ProgressionFeature.State()) {
            ProgressionFeature()
        } withDependencies: {
            $0.audioPlayer = AudioPlayerClient(
                play: { notes, _ in played.withValue { $0.append(notes) } },
                stop: {}
            )
        }

        await store.send(.chordTapped(2)) {
            $0.selectedIndex = 2
        }
        await store.finish()
        // C키 팝 진행의 세 번째 코드는 Am.
        #expect(played.value == [[69, 72, 76]])
    }
}
