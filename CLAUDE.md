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
Sources/App/          진입점. 단일 Store를 들고 Crashlytics와 AdMob을 초기화한다
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

- `PitchClass` — 12음. "어떤 소리인가"만 담당한다.
- `NoteName` — 17개 음이름. "어떻게 적는가"를 담당한다. C♯과 D♭은 같은 건반이지만
  코드 이름도 구성음 표기도 달라 따로 둔다. 코드의 루트는 항상 `NoteName`이고,
  구성음 표기는 루트의 `prefersFlats`를 따라간다.
  - 목록과 루트 스트립은 소리 기준 12줄이고 `PitchClass.combinedName`으로 `C♯/D♭`처럼
    두 표기를 함께 적는다. 들어가면 `defaultNoteName`(관습적으로 흔한 쪽)으로 열리고,
    상세 화면의 표기 토글로 바꾼다. 표기를 바꿔도 소리는 그대로다.
  - 알려진 한계: 표기가 피치 클래스 기준이라 C♯ 메이저를 `C♯ F G♯`로 적는다.
    이론상 맞는 표기는 `C♯ E♯ G♯`다. 음이름을 글자(letter) 기준으로 다시 세우면 고칠 수 있다.
- `ChordQuality` — 28가지 코드 성질을 반음 간격 배열로 정의. `nameKey`가 번역 키다.
- `Chord` — 루트 + 성질. 전위는 낮은 음부터 한 옥타브씩 올리는 방식이다.
- `ChordProgression` — 으뜸음으로부터의 반음 거리로 정의해 어떤 조로든 이조된다.
- `ChordSynthesizer` — 사운드폰트 없이 배음을 쌓아 PCM 버퍼를 만드는 actor.
  리듀서는 `AudioPlayerClient` 의존성만 보고, `testValue`는 소리를 내지 않는다.

## 의존성

TCA와 GoogleMobileAds, Firebase 모두 **Xcode 네이티브 SPM**으로 붙인다. `Project.swift`의
`packages:`에 선언하고 타깃에서 `.package(product:)`로 가져다 쓴다.
해석 결과는 루트 `.package.resolved`에 남고 이 파일은 커밋한다. `tuist generate`는
워크스페이스 쪽에만 쓰므로, 패키지를 더하거나 뺀 뒤에는 루트 파일을 직접 맞춰 준다.

```sh
cp Pico.xcworkspace/xcshareddata/swiftpm/Package.resolved .package.resolved
```

Tuist의 SPM 통합(`Tuist/Package.swift` + `.external`)은 쓰지 않는다. 한 번 그렇게
만들었다가 걷어냈다.

GoogleMobileAds는 동적 프레임워크라 **ChordFeature와 앱 타깃 양쪽에서 링크**한다.
정적 프레임워크는 동적 라이브러리를 품을 수 없어, 앱 타깃이 직접 링크해야 번들에 들어간다.

FirebaseCrashlytics는 **앱 타깃에만** 링크한다. 크래시 수집은 UI도 도메인도 아닌 앱
수명주기 인프라라 아래 모듈이 알 이유가 없다. 자세한 것은 "크래시 수집"에 적었다.

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

배너와 전면 광고 둘 다 쓴다.

**배너** — 코드 찾기 화면의 코드 카드 바로 아래 (`AdBannerView`).
배너 크기에 맞춘 사각형이고 모서리를 둥글리지 않는다. 광고를 못 받으면 자리를 접는다.

배너 배경이나 SDK 내부 뷰 계층은 건드리지 않는다. 크리에이티브가 슬롯보다 작을 때 생기는
여백도 SDK가 그리는 대로 둔다. 한 번 손댔다가 걷어낸 코드다.

`updateUIView`에서 크기를 비교할 때 `banner.adSize`를 쓰면 안 된다. 광고가 실리면 그 값이
내려온 크기로 바뀌어서, 비교할 때마다 "요청과 다르다 → 재요청"이 무한히 반복된다.
요청한 크기는 코디네이터가 따로 들고 있다.

### 광고 동의 (UMP)

유럽·영국·스위스에 광고를 실으려면 구글이 인증한 동의 양식으로 동의를 받아야 한다. 동의
흐름이 없으면 비개인화 광고조차 실리지 않아 그 지역 노출이 통째로 빠진다. `AdConsent`가
그 흐름이고, `AdMob.start()`가 **동의를 받은 뒤에** SDK를 켠다. 광고 요청은 모두 지연돼
있어(배너는 코드 찾기 화면, 전면 광고는 분류를 누를 때) 여기서 몇백 밀리초 늦어도 첫 광고를
놓치지 않는다.

`UserMessagingPlatform`은 GoogleMobileAds 패키지가 함께 들고 오므로 `Project.swift`에 따로
선언하지 않는다.

**코드만으로는 아무것도 뜨지 않는다.** AdMob 콘솔의 `개인정보 보호 및 메시지 → 유럽 규정`에서
메시지를 만들고 **게시**해야 한다. 안 되어 있으면 로그에
`no form(s) configured for the input app ID`가 찍힌다. 게시는 서버 설정이라 **앱을 다시
빌드하지 않아도 적용된다.** 규제 대상 미국 주도 같은 구조다 (`미국 주 규정` 메시지).
`IDFA 설명` 메시지는 만들지 않는다 — ATT를 요청하지 않는 앱이라 띄울 팝업이 없다.

동의 양식이 "앱에서 동의를 관리하는 경로를 찾으라"고 안내하므로 그 경로가 실제로 있어야 한다.
루트 목록 맨 아래의 "광고 개인정보 설정" 버튼이 그것이고, `privacyOptionsRequirementStatus`가
`required`일 때만 그려서 그 밖의 지역에서는 화면이 지금과 똑같다. 루트 목록은 내비게이션 바를
접어 두므로 툴바에 넣을 자리가 없어 목록 아래에 뒀다.

미리 볼 때는 지역을 위장한다. 시뮬레이터는 UMP가 언제나 디버그 기기로 취급하므로 기기 ID를
등록할 필요가 없다. 한 번 동의하면 다시 묻지 않으니, 이 스위치가 켜져 있으면 매번 `reset()`한다.

```sh
xcrun simctl launch $SIM com.lavakangjun.pico -PicoConsentGeography eea
xcrun simctl launch $SIM com.lavakangjun.pico -PicoConsentGeography us
```

**동의를 거부하면 광고가 실리지 않고, 잠긴 분류도 열리지 않는다.** 광고를 끝까지 본 경우에만
열어 주는 규칙(`interstitialFinished`의 `watched`)을 그대로 두기로 했다. 네트워크가 없거나
노 필일 때도 같아서 아무 일도 일어나지 않는데, 화면에 이미 "광고를 보면 … 열 수 있어요"가
적혀 있으니 따로 안내하지 않는다.

**전면 광고** — 6화음·7화음·텐션 분류를 누를 때마다 (`InterstitialAdClient`).
한 번 봤다고 열어 두지 않는다. 3화음만 광고 없이 오간다.
`AdMob.showsInterstitialForLockedCategories`는 개발 중에 광고를 건너뛰려고 두는
디버깅 스위치다. 배포 빌드에서는 true여야 한다.

전면 광고를 띄우는 `InterstitialPresenter`는 `@MainActor`다. 의존성의 `liveValue` 초기화는
메인 액터가 아닌 곳에서 도니, 거기서 인스턴스를 만들면 실행 즉시 크래시한다.
클로저 안에서 `.shared`로 처음 접근할 때 만들어지게 해 뒀다.

## 크래시 수집

Firebase Crashlytics를 쓴다. SDK는 **앱 타깃에만** 링크한다. `ChordCore`와 `ChordFeature`는
Firebase를 모른다.

`ChordCore`의 `CrashReporterClient`가 인터페이스고, 기본값(`liveValue`)은 아무것도 하지
않는 `.noop`이다. 실제 구현 `.firebase`는 `Sources/App/CrashReporting.swift`에 있고
앱을 켤 때 `prepareDependencies`로 갈아 끼운다. 그래서 테스트와 프리뷰는 의존성을
바꾸지 않아도 조용하다.

```swift
init() {
    if CrashReporting.start() { prepareDependencies { $0.crashReporter = .firebase } }
    AdMob.start()
}
```

- **순서가 중요하다.** 크래시 리포터가 AdMob보다 먼저 붙어야 SDK 초기화 중 크래시도 잡는다.
- **`prepareDependencies`는 첫 읽기보다 먼저여야 한다.** 누가 먼저 `crashReporter`를 읽으면
  `.noop`이 전역 캐시에 굳고, 그 뒤의 주입은 무시되며 런타임 경고만 뜬다. `PicoApp.init()`은
  스토어도 뷰도 아직 없는 시점이라 여기가 안전한 자리다.
- **`start()`가 false면 주입하지 않는다.** `FirebaseApp.configure()`가 안 돌았는데
  `Crashlytics.crashlytics()`를 부르면 그 자리에서 죽는다. `GoogleService-Info.plist`가
  없으면 경고만 남기고 `.noop`을 그대로 둔다 — 크래시 리포터가 없다고 앱이 죽는 건
  앞뒤가 바뀐 얘기다.

기록하는 곳은 세 군데다. 합성기 재생 실패(`ChordSynthesizer`), 전면 광고 present
실패(`InterstitialPresenter`), 그리고 화면에 떠 있던 코드를 커스텀 키로(`ChordFinderView`).
마지막 것을 리듀서가 아니라 뷰에 둔 이유는 리듀서에 부수효과를 들이지 않으려는 것이다.

dSYM 업로드는 `Project.swift`의 포스트 스크립트가 맡는다. `runForInstallBuildsOnly`라
아카이브할 때만 돈다. 이게 없으면 크래시 로그가 심볼 없는 주소값으로만 올라온다.

알아 둘 것:

- **디버거가 붙어 있으면 리포트가 안 올라간다.** 디버거가 크래시를 먼저 잡는다. 확인하려면
  앱을 죽인 뒤 시뮬레이터나 기기에서 직접 다시 켜야 다음 실행 때 전송된다.
- 실행하면 `NSUncaughtExceptionHandler is 'GADRegisterExceptionHandler'` 경고가 뜬다.
  AdMob이 나중에 초기화되며 핸들러를 덮어써서 그렇다. 시그널 기반 크래시(Swift `fatalError`,
  범위 초과, EXC_BAD_ACCESS)는 Crashlytics가 따로 잡으므로 영향이 없고, Objective-C
  `NSException`만 AdMob 체인에 달린다. 순서를 뒤집으면 반대가 된다.

## 배포 체크리스트

### 끝난 것

- 배너·전면 광고 단위 ID와 `GADApplicationIdentifier`가 실제 값이다
- `SKAdNetworkItems`가 구글 공개 목록 전체다 (2026-01-30 기준 50개)
- `AdMob.showsInterstitialForLockedCategories`가 `true`다
- 광고 콘텐츠 등급을 **G(전체 이용가)로 제한**했다. 연령 등급 4+에 맞추려면 필요하다.
  코드(`AdMob.start()`의 `maxAdContentRating = .general`)와 AdMob 콘솔 양쪽에 걸어 뒀다.
  둘 중 더 엄격한 쪽이 적용된다. 코드에 둔 이유는 콘솔 설정이 바뀌어도 앱이 스스로
  지키게 하려는 것이고, 콘솔에 둔 이유는 중개 네트워크로 들어오는 광고까지 걸러야 해서다.
- `app-ads.txt`를 https://lavakangjun.github.io/app-ads.txt 에 올렸다
  (저장소는 `~/lavakangjun.github.io`, GitHub Pages 사용자 사이트)

**이제 실제 광고 단위라 자기 광고를 누르면 안 된다.** 무효 트래픽으로 잡혀 수익 차감이나
계정 정지로 돌아온다. 시뮬레이터는 SDK가 자동으로 테스트 기기로 잡아 주지만, 실기기로
확인하려면 AdMob 콘솔에 테스트 기기를 먼저 등록한다.

### 남은 것

1. 앱스토어 등록 정보의 마케팅 URL을 `https://lavakangjun.github.io/pico/`로 적는다.
   AdMob은 **스토어 등록 정보에 적힌 도메인**을 읽어 그 루트의 `app-ads.txt`를 크롤링하므로,
   앱이 스토어에 올라가기 전에는 인증이 끝나지 않는다. 출시 후 콘솔에서 "인증됨" 확인
   (최대 24시간). 하위 경로를 적어도 크롤러는 도메인 루트에서 찾는다.
2. 개인정보 처리방침 페이지. 앱스토어 심사에 필요하고, AdMob과 Crashlytics가 데이터를
   수집하므로 그 내용이 들어가야 한다. 홈페이지에 얹으면 된다.
3. 홈페이지 `index.html`의 App Store 링크와 문의 이메일을 채운다. 둘 다 주석으로 표시해 뒀다.
4. 첫 아카이브 뒤 Crashlytics 콘솔에 dSYM 누락 경고가 없는지 확인한다.

`SKAdNetworkItems`는 중개 네트워크가 늘면 바뀐다. 앱을 올릴 때마다
https://developers.google.com/admob/ios/3p-skadnetworks 와 맞춰 본다.

### 알아 둘 것

`app-ads.txt`는 "이 퍼블리셔 ID로 내 앱 인벤토리를 파는 건 나뿐"이라는 공개 선언이다.
실제 효과는 두 가지다. 광고를 사는 쪽이 이 파일을 확인하므로 **없으면 입찰이 낮아지거나
빠져 수익이 깎이고**, 남이 내 앱인 척 인벤토리를 파는 스푸핑을 구매자가 걸러낼 수 있다.
(누군가 내 광고 단위 ID를 자기 앱에 박는 것은 다른 문제이고, 그쪽은 AdMob 콘솔의
앱 확인 기능이 맡는다.)

앱이 몇 개로 늘어도 파일은 그대로다. 적히는 것은 앱이 아니라 **퍼블리셔 ID 하나**라,
같은 AdMob 계정의 앱들은 스토어 등록 정보에 같은 도메인만 적으면 전부 이 파일을 함께 쓴다.

AdMob 앱 ID와 광고 단위 ID, `GoogleService-Info.plist`는 **비밀값이 아니다.** 앱 번들에
실려 배포되므로 누구나 꺼낼 수 있고, 구글 문서도 코드에 그대로 넣으라고 안내한다.
환경변수나 별도 설정 파일로 빼낼 이유가 없다. 숨겨야 하는 건 AdMob 계정 자격증명,
리포팅 API 키, Firebase 서비스 계정 JSON 쪽이고 이 저장소에는 그런 것이 없다.

## 규칙

- Swift 6 모드에 strict concurrency가 켜져 있다. public 타입은 암묵적 Sendable을 받지
  못한다는 점에 자주 걸린다.
- 생성물(`*.xcodeproj`, `*.xcworkspace`, `Derived/`)은 커밋하지 않는다.
