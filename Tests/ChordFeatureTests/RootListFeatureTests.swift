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

    @Test("목록은 12음을 모두 보여 주고 메이저 3화음을 미리 알려 준다")
    func listsEveryRoot() {
        #expect(PitchClass.allCases.count == 12)
        #expect(PitchClass.c.majorTriadPreview == "C E G")
        #expect(PitchClass.aSharp.majorTriadPreview == "B♭ D F")
    }
}
