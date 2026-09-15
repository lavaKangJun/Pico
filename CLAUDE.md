# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

피아노 코드를 찾아보고 소리로 확인하는 iOS 앱. Tuist · TCA · SwiftUI로 만들었다.
코드 주석과 커밋 메시지는 한국어로 쓴다.

## 명령

Tuist 버전은 `.mise.toml`에 고정돼 있다. 셸에 mise 훅이 없으면 `mise x -- tuist ...`로 실행한다.

```sh
tuist generate --no-open      # Pico.xcworkspace 생성
```

**파일을 새로 추가하면 반드시 `tuist generate`를 다시 돌려야 한다.** Tuist는 생성 시점의
파일 목록을 고정하므로, 새 파일은 재생성 전까지 빌드에 포함되지 않는다. 이걸 잊으면
"cannot find type ... in scope" 같은 엉뚱한 오류로 나타난다.

```sh
# 빌드
xcodebuild build -workspace Pico.xcworkspace -scheme Pico \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO -skipMacroValidation

# 전체 테스트 (Pico-Workspace 스킴이 두 테스트 타깃을 모두 돈다)
xcodebuild test -workspace Pico.xcworkspace -scheme Pico-Workspace \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO -skipMacroValidation

# 테스트 하나만
xcodebuild test -workspace Pico.xcworkspace -scheme Pico-Workspace \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipMacroValidation \
  -only-testing:ChordCoreTests/ChordTests
```

`-skipMacroValidation`이 없으면 TCA 매크로가 "must be enabled before it can be used"로
막힌다. Xcode에서는 한 번 신뢰하면 되지만 CLI에서는 프롬프트를 띄울 수 없다.

시뮬레이터에서 직접 확인할 때:

```sh
SIM=$(xcrun simctl list devices available | grep "iPhone 17 Pro " | head -1 | sed 's/.*(\(.*\)) (.*/\1/')
xcrun simctl boot $SIM; xcrun simctl install $SIM <경로>/Pico.app
xcrun simctl launch $SIM com.lavakangjun.pico -AppleLanguages "(ja)" -AppleLocale ja_JP
xcrun simctl io $SIM screenshot /tmp/shot.png
```

첫 실행 직후 몇 초 동안은 레이아웃이 자리를 잡는 중이라 스크린샷이 스크롤된 것처럼
찍힐 수 있다. 10초쯤 기다린 뒤 찍어야 실제 화면이 나온다.

## 구조

```
Sources/App/          진입점. 단일 Store를 들고 AdMob을 초기화한다
Sources/ChordFeature/ TCA 리듀서 + SwiftUI 뷰 + UI 문구 번역
Sources/ChordCore/    음악 이론 도메인 + 오디오 + 음악 용어 번역
```

의존은 `App → ChordFeature → ChordCore` 한 방향이다. `ChordCore`는 SwiftUI를 모른다.
모든 모듈이 `.staticFramework`다.

### 화면 흐름

`AppView`는 지금 `RootListView` 하나만 띄운다. `ProgressionFeature`/`ProgressionView`는
살아 있지만 화면에서만 빠져 있고, `AppFeature`에 상태와 Scope도 그대로 있다.
탭을 되살리려면 `AppView`의 body를 TabView로 되돌리면 된다.

`RootListFeature`가 `StackState<ChordFinderFeature.State>`로 네비게이션을 들고 있다.
루트 목록 → 코드 찾기 화면이 이 스택으로 밀려 들어간다.

### TCA 사용 방식

TCA는 1.26.2로 고정돼 있다 (`.exact`). 리듀서는 아래 모양을 따른다.

```swift
@Reducer
public struct ChordFinderFeature: Sendable {   // Sendable을 빼면 .run에서 self를 못 잡는다
    @ObservableState
    public struct State: Equatable { ... }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)     // 뷰에서 $store.style 같은 바인딩을 쓸 때만
        case rootTapped(PitchClass)            // 나머지는 "사용자가 무엇을 했는가"로 이름 짓는다
    }

    @Dependency(\.audioPlayer) var audioPlayer

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in ... }
    }
}
```

- **State는 파생값을 저장하지 않는다.** `chord`, `midiNotes`, `inversionOptions`처럼 루트와
  성질에서 계산되는 것들은 전부 computed property다. 뷰가 쓰는 표시 문자열도 마찬가지다.
- **이펙트는 필요한 값만 캡처한다.** `.run { [notes = state.midiNotes] _ in ... }` 식으로
  state를 통째로 들고 들어가지 않는다.
- **취소는 `private enum CancelID`** 로 잡는다. `ProgressionFeature`의 순차 재생이 예다.
- 부수효과는 전부 의존성 뒤에 있다. 오디오는 `AudioPlayerClient`, 시간은
  `@Dependency(\.continuousClock)`. 리듀서 안에서 직접 `Task.sleep`이나 AVFoundation을
  부르지 않는다.

네비게이션은 `StackState` + `.forEach(\.path, action: \.path)`로 붙이고, 뷰에서는
`NavigationStack(path: $store.scope(state: \.path, action: \.path))`와
`NavigationLink(state:)`를 쓴다. 뷰는 `@Bindable var store: StoreOf<...>`를 들고
`store.send(...)`로만 말을 건다.

테스트는 Swift Testing + `TestStore`다. 스위트에 `@MainActor`를 붙이고, 상태 변화를
`store.send(.x) { $0.y = z }`로 남김없이 적는다.

```swift
let store = TestStore(initialState: .init()) { Feature() } withDependencies: {
    $0.continuousClock = TestClock()          // 시간이 필요한 이펙트
    $0.audioPlayer = AudioPlayerClient(...)   // 호출 여부를 확인할 때
}
```

`AudioPlayerClient.testValue`는 아무 소리도 내지 않으므로, 재생 자체를 검증하지 않는
테스트는 의존성을 갈아끼울 필요가 없다. 다만 이펙트가 끝나기를 기다려야 하면
`await store.finish()`를 붙인다.

### 도메인

- `PitchClass` — 12음. 루트마다 샤프/플랫 표기 성향(`prefersFlatSpelling`)이 정해져 있고,
  음이름·계이름 모두 이 성향을 따라간다. 표기가 어긋나면 이 값을 먼저 본다.
- `ChordQuality` — 28가지 코드 성질을 반음 간격 배열로 정의. `nameKey`가 번역 키다.
- `Chord` — 루트 + 성질. 전위는 낮은 음부터 한 옥타브씩 올리는 방식이다.
- `ChordProgression` — 으뜸음으로부터의 반음 거리로 정의해 어떤 조로든 이조된다.
- `ChordSynthesizer` — 사운드폰트 없이 배음을 쌓아 PCM 버퍼를 만드는 actor.
  리듀서는 `AudioPlayerClient` 의존성만 보고, `testValue`는 소리를 내지 않는다.

## 의존성

TCA와 GoogleMobileAds 모두 **Xcode 네이티브 SPM**으로 붙인다. `Project.swift`의
`packages:`에 선언하고 타깃에서 `.package(product:)`로 가져다 쓴다.
해석 결과는 루트 `.package.resolved`에 남고 이 파일은 커밋한다.

Tuist의 SPM 통합(`Tuist/Package.swift` + `.external`)은 쓰지 않는다. 한 번 그렇게
만들었다가 걷어냈다.

GoogleMobileAds는 동적 프레임워크라 **ChordFeature와 앱 타깃 양쪽에서 링크**한다.
정적 프레임워크는 동적 라이브러리를 품을 수 없어, 앱 타깃이 직접 링크해야 번들에 들어간다.

## 번역

한국어로 쓰고 영어·일본어·중국어(간체/번체)를 지원한다. 모듈마다 자기 String Catalog을
들고 다닌다 (`Sources/<모듈>/Resources/Localizable.xcstrings`). **키는 한국어 원문이다.**

SwiftUI의 `Text`는 기본적으로 메인 번들을 보므로 모듈 안에서는 번들을 직접 지정한다.

```swift
Text("옥타브", bundle: .chordFeature)   // 뷰
localized("마이너 세븐스")               // 모델 (NSLocalizedString 래퍼)
```

지원 언어는 `Project.swift`의 `knownRegions`와 앱 Info.plist의 `CFBundleLocalizations`
**양쪽에** 선언돼 있다. 언어를 추가하려면 두 곳과 각 String Catalog을 모두 손봐야 한다.

같은 한국어 단어라도 언어에 따라 뜻이 갈리면 키를 나눠야 한다. 조성을 "메이저/마이너"가
아니라 "장조/단조"로 쓰는 이유가 이것이다 — 중국어는 大三和弦(화음)과 大调(조성)를 구분한다.

`LocalizationTests`가 언어별 `.lproj`를 직접 열어 번역 누락을 잡는다. 시뮬레이터 언어
설정과 무관하게 돌아간다.

## 광고

코드 찾기 화면의 코드 카드 바로 아래에 AdMob 배너가 들어간다 (`AdBannerView`).
배너 크기에 맞춘 사각형이고 모서리를 둥글리지 않는다. 광고를 못 받으면 자리를 접는다.

배너 배경이나 SDK 내부 뷰 계층은 건드리지 않는다. 크리에이티브가 슬롯보다 작을 때 생기는
여백도 SDK가 그리는 대로 둔다. 한 번 손댔다가 걷어낸 코드다.

`updateUIView`에서 크기를 비교할 때 `banner.adSize`를 쓰면 안 된다. 광고가 실리면 그 값이
내려온 크기로 바뀌어서, 비교할 때마다 "요청과 다르다 → 재요청"이 무한히 반복된다.
요청한 크기는 코디네이터가 따로 들고 있다.

### 배포 체크리스트

지금 들어 있는 ID는 전부 구글이 공개한 테스트 값이다. 실제 배포 전에:

1. `AdMob.bannerAdUnitID`를 AdMob 콘솔에서 발급받은 배너 단위 ID로
2. `Project.swift`의 `GADApplicationIdentifier`를 실제 앱 ID로
3. `Project.swift`의 `SKAdNetworkItems`를 구글 문서의 전체 목록으로
4. 개발자 웹사이트 루트에 `app-ads.txt`를 올리고 AdMob 콘솔에서 인식 확인

`app-ads.txt`는 "이 퍼블리셔 ID로 내 앱 인벤토리를 파는 건 나뿐"이라는 선언이다.
없으면 누군가 광고 단위 ID를 자기 앱에 박아 가짜 노출을 만들어도 막을 방법이 없고,
그 부정 트래픽이 내 계정에 적립돼 수익 차감이나 계정 정지로 돌아온다.
앱스토어 등록 정보의 개발자 웹사이트와 도메인이 같아야 인식된다.

AdMob 앱 ID와 광고 단위 ID는 **비밀값이 아니다.** 구글 문서가 Info.plist와 코드에 그대로
넣으라고 안내하는 공개 식별자다. 환경변수나 별도 설정 파일로 빼낼 이유가 없다.
숨겨야 하는 건 AdMob 계정 자격증명, 리포팅 API 키, GCP 서비스 계정 JSON 쪽이고
이 저장소에는 그런 것이 없다.

## 규칙

- Swift 6 모드에 strict concurrency가 켜져 있다. public 타입은 암묵적 Sendable을 받지
  못한다는 점에 자주 걸린다.
- 생성물(`*.xcodeproj`, `*.xcworkspace`, `Derived/`)은 커밋하지 않는다.
