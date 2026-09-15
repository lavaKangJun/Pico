import ChordCore
@testable import ChordFeature
import ComposableArchitecture
import Testing

@MainActor
@Suite("코드 찾기 화면")
struct ChordFinderFeatureTests {
    @Test("루트를 고르면 코드가 바뀐다")
    func selectsRoot() async {
        let store = TestStore(initialState: ChordFinderFeature.State()) {
            ChordFinderFeature()
        }

        await store.send(.rootTapped(.g)) {
            $0.root = .g
        }
        #expect(store.state.symbol == "G")
        await store.finish()
    }

    @Test("분류를 바꾸면 그 분류의 첫 코드로 옮겨 간다")
    func switchesCategory() async {
        let store = TestStore(initialState: ChordFinderFeature.State()) {
            ChordFinderFeature()
        }

        await store.send(.categoryTapped(.seventh)) {
            $0.category = .seventh
            $0.quality = .dominantSeventh
        }
        #expect(store.state.symbol == "C7")
        await store.finish()
    }

    @Test("구성음이 줄어드는 코드로 바꾸면 전위가 범위 안으로 돌아온다")
    func clampsInversion() async {
        let store = TestStore(initialState: ChordFinderFeature.State(
            quality: .majorSeventh,
            inversion: 3
        )) {
            ChordFinderFeature()
        }

        await store.send(.qualityTapped(.power)) {
            $0.quality = .power
            $0.inversion = 1
        }
        await store.finish()
    }

    @Test("옥타브는 2와 6 사이로 제한된다")
    func limitsOctave() async {
        let store = TestStore(initialState: ChordFinderFeature.State(octave: 6)) {
            ChordFinderFeature()
        }

        await store.send(.octaveStepped(1))
        #expect(store.state.octave == 6)

        await store.send(.octaveStepped(-1)) {
            $0.octave = 5
        }
        #expect(store.state.midiNotes == [72, 76, 79])
        await store.finish()
    }

    @Test("코드를 누르면 재생 요청이 나간다")
    func playsChord() async {
        let played = LockIsolated<[[Int]]>([])
        let store = TestStore(initialState: ChordFinderFeature.State()) {
            ChordFinderFeature()
        } withDependencies: {
            $0.audioPlayer = AudioPlayerClient(
                play: { notes, _ in played.withValue { $0.append(notes) } },
                stop: {}
            )
        }

        await store.send(.playButtonTapped)
        await store.finish()
        #expect(played.value == [[60, 64, 67]])
    }
}
