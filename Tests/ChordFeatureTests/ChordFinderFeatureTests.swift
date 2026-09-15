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

    @Test("잠금이 없으면 분류를 바꾸는 즉시 그 분류의 첫 코드로 옮겨 간다")
    func switchesCategory() async {
        let store = TestStore(initialState: ChordFinderFeature.State(
            requiresAdForLockedCategories: false
        )) {
            ChordFinderFeature()
        }

        await store.send(.categoryTapped(.seventh)) {
            $0.category = .seventh
            $0.quality = .dominantSeventh
        }
        #expect(store.state.symbol == "C7")
        await store.finish()
    }

    @Test("잠긴 분류는 누를 때마다 전면 광고를 봐야 열린다")
    func showsAdOnEveryLockedCategoryTap() async {
        let shown = LockIsolated(0)
        let store = TestStore(initialState: ChordFinderFeature.State()) {
            ChordFinderFeature()
        } withDependencies: {
            $0.interstitialAd = InterstitialAdClient(
                prepare: {},
                show: {
                    shown.withValue { $0 += 1 }
                    return true
                }
            )
        }

        #expect(!store.state.requiresAd(for: .triad))
        #expect(store.state.requiresAd(for: .tension))

        await store.send(.categoryTapped(.tension)) {
            $0.isWaitingForAd = true
        }
        await store.receive(.interstitialFinished(category: .tension, watched: true)) {
            $0.isWaitingForAd = false
            $0.category = .tension
            $0.quality = .ninth
        }
        #expect(shown.value == 1)

        // 3화음으로 돌아가는 건 광고 없이 된다.
        await store.send(.categoryTapped(.triad)) {
            $0.category = .triad
            $0.quality = .major
        }
        #expect(shown.value == 1)

        // 같은 분류라도 다시 누르면 광고를 또 봐야 한다.
        await store.send(.categoryTapped(.tension)) {
            $0.isWaitingForAd = true
        }
        await store.receive(.interstitialFinished(category: .tension, watched: true)) {
            $0.isWaitingForAd = false
            $0.category = .tension
            $0.quality = .ninth
        }
        #expect(shown.value == 2)
        await store.finish()
    }

    @Test("광고를 끝까지 보지 않으면 분류가 바뀌지 않는다")
    func keepsCategoryWhenAdIsSkipped() async {
        let store = TestStore(initialState: ChordFinderFeature.State()) {
            ChordFinderFeature()
        } withDependencies: {
            $0.interstitialAd = InterstitialAdClient(prepare: {}, show: { false })
        }

        await store.send(.categoryTapped(.seventh)) {
            $0.isWaitingForAd = true
        }
        await store.receive(.interstitialFinished(category: .seventh, watched: false)) {
            $0.isWaitingForAd = false
        }
        #expect(store.state.category == .triad)
        #expect(store.state.requiresAd(for: .seventh))
        await store.finish()
    }

    @Test("코드를 고르는 것만으로는 소리가 나지 않는다")
    func doesNotPlayWhileBrowsing() async {
        let played = LockIsolated(0)
        let store = TestStore(initialState: ChordFinderFeature.State(
            requiresAdForLockedCategories: false
        )) {
            ChordFinderFeature()
        } withDependencies: {
            $0.audioPlayer = AudioPlayerClient(
                play: { _, _ in played.withValue { $0 += 1 } },
                stop: {}
            )
        }

        await store.send(.rootTapped(.g)) { $0.root = .g }
        await store.send(.categoryTapped(.seventh)) {
            $0.category = .seventh
            $0.quality = .dominantSeventh
        }
        await store.send(.qualityTapped(.majorSeventh)) { $0.quality = .majorSeventh }
        await store.send(.inversionTapped(1)) { $0.inversion = 1 }
        await store.send(.octaveStepped(1)) { $0.octave = 5 }
        await store.finish()
        #expect(played.value == 0)

        // Play를 눌렀을 때만 울린다.
        await store.send(.playButtonTapped)
        await store.finish()
        #expect(played.value == 1)
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
