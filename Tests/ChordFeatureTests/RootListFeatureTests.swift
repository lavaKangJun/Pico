import ChordCore
@testable import ChordFeature
import ComposableArchitecture
import Testing

@MainActor
@Suite("루트 목록")
struct RootListFeatureTests {
    @Test("루트를 고르면 그 음의 코드 찾기 화면이 열린다")
    func opensFinderForRoot() async {
        let store = TestStore(initialState: RootListFeature.State()) {
            RootListFeature()
        }

        await store.send(.path(.push(id: 0, state: ChordFinderFeature.State(root: .g)))) {
            $0.path.append(ChordFinderFeature.State(root: .g))
        }

        #expect(store.state.openedRoot == .g)
        #expect(store.state.path[id: 0]?.symbol == "G")
    }

    @Test("코드 찾기 화면 안에서 루트를 바꿔도 같은 화면이 유지된다")
    func switchesRootInPlace() async {
        let store = TestStore(initialState: RootListFeature.State(
            path: StackState([ChordFinderFeature.State(root: .c)])
        )) {
            RootListFeature()
        }

        await store.send(.path(.element(id: 0, action: .rootTapped(.e)))) {
            $0.path[id: 0]?.root = .e
        }

        #expect(store.state.path.count == 1)
        #expect(store.state.openedRoot == .e)
        await store.finish()
    }

    @Test("뒤로 나오면 스택이 빈다")
    func popsBackToList() async {
        let store = TestStore(initialState: RootListFeature.State(
            path: StackState([ChordFinderFeature.State(root: .a)])
        )) {
            RootListFeature()
        }

        await store.send(.path(.popFrom(id: 0))) {
            $0.path.removeAll()
        }

        #expect(store.state.openedRoot == nil)
    }

    @Test("목록은 12줄이고 같은 소리는 두 표기를 함께 적는다")
    func listsEveryRoot() {
        #expect(PitchClass.allCases.count == 12)
        #expect(PitchClass.c.combinedName == "C")
        #expect(PitchClass.cSharp.combinedName == "C♯/D♭")
        #expect(PitchClass.gSharp.combinedName == "G♯/A♭")
        #expect(PitchClass.cSharp.combinedSolfege == "도♯/레♭")
        #expect(PitchClass.c.combinedSolfege == "도")
    }

    @Test("목록에서 들어가면 관습적으로 흔한 표기로 열린다")
    func opensWithConventionalSpelling() {
        #expect(PitchClass.cSharp.defaultNoteName == .dFlat)
        #expect(PitchClass.dSharp.defaultNoteName == .eFlat)
        #expect(PitchClass.fSharp.defaultNoteName == .fSharp)
        #expect(PitchClass.gSharp.defaultNoteName == .aFlat)
        #expect(PitchClass.aSharp.defaultNoteName == .bFlat)
        #expect(PitchClass.f.defaultNoteName == .f)
        #expect(PitchClass.cSharp.defaultNoteName.majorTriadPreview == "D♭ F A♭")
    }

    @Test("상세 화면에서 표기를 바꿔도 소리는 그대로다")
    func switchesSpellingInPlace() async {
        let store = TestStore(initialState: RootListFeature.State(
            path: StackState([ChordFinderFeature.State(root: .dFlat)])
        )) {
            RootListFeature()
        }

        let before = store.state.path[id: 0]?.midiNotes
        #expect(store.state.path[id: 0]?.symbol == "D♭")

        await store.send(.path(.element(id: 0, action: .rootTapped(.cSharp)))) {
            $0.path[id: 0]?.root = .cSharp
        }

        #expect(store.state.path[id: 0]?.symbol == "C♯")
        #expect(store.state.path[id: 0]?.midiNotes == before)
        await store.finish()
    }
}
