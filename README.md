# Pico

피아노 코드를 찾아보고 소리로 확인하는 iOS 앱. Tuist · TCA · SwiftUI로 만들었다.

## 기능

- **루트 코드 목록** — 앱을 열면 12음이 리스트로 보인다. 음을 고르면 그 루트의 코드 찾기 화면으로 들어간다.
  (지금은 이 흐름만 화면에 띄운다. 아래 코드 진행은 코드가 살아 있지만 탭에서 빠져 있다.)
- **코드 찾기** — 28가지 코드 성질을 골라 구성음, 도수(R/♭3/5…), 계이름을 확인하고 건반 위에서 짚어 본다.
  화면 맨 위에 루트 스트립이 고정돼 있어 뒤로 나가지 않고도 가로로 넘겨 다른 루트로 옮겨 갈 수 있다.
  전위·옥타브 조절, 동시에/아르페지오 재생, 건반 개별 타건 지원.
- **코드 진행** — 팝 진행, 캐논, 투 파이브 원, 12마디 블루스 등 9가지 진행을 원하는 조로 옮겨 듣는다. BPM 조절과 한 코드씩 순차 재생.

소리는 Play 버튼을 눌렀을 때만 난다. 루트나 코드를 고르는 중에는 울리지 않는다.
사운드폰트 없이 `AVAudioEngine` 위에서 배음을 쌓아 만든다. (`ChordSynthesizer`)

6화음·7화음·텐션 분류는 누를 때마다 전면 광고를 봐야 열린다. 3화음은 광고 없이 볼 수 있다.
`AdMob.showsInterstitialForLockedCategories`는 개발 중에 광고를 건너뛰려는 디버깅 스위치다.

## 광고

코드 찾기 화면의 코드 카드 바로 아래에 AdMob 배너를 띄운다. (`AdBannerView`)
창 너비에 맞춘 앵커드 어댑티브 배너이고, 광고를 못 받으면 자리를 접어 빈 카드를 남기지 않는다.

> **배포 전에 할 것**
> 1. `AdMob.bannerAdUnitID`와 `AdMob.interstitialAdUnitID` 교체
> 2. `Project.swift`의 `GADApplicationIdentifier` 교체
> 3. `Project.swift`의 `SKAdNetworkItems`를 구글 문서의 전체 목록으로
> 4. 개발자 웹사이트 루트에 `app-ads.txt` 게시 — 광고 단위 ID 도용으로 생기는
>    부정 트래픽이 내 계정에 적립되는 걸 막는다
>
> 지금 들어 있는 값은 모두 구글이 공개한 **테스트 ID**라 실제 광고도 수익도 나가지 않는다.
> 화면에 뜨는 "Test mode" 배지도 실 단위로 바꾸면 사라진다.
> 참고로 이 ID들은 비밀값이 아니라 공개 식별자다. 코드에 두는 것이 정상이다.

## 언어

한국어로 쓰고 영어·일본어·중국어(간체/번체)를 지원한다. 번역은 모듈마다 자기 String Catalog을
들고 다니고(`Sources/<모듈>/Resources/Localizable.xcstrings`), 키는 한국어 원문을 그대로 쓴다.

SwiftUI의 `Text`는 기본적으로 메인 번들을 보기 때문에, 모듈 안에서는 번들을 직접 지정한다.

```swift
Text("들어보기", bundle: .chordFeature)   // 뷰
localized("마이너 세븐스")                  // 모델 (NSLocalizedString 래퍼)
```

지원 언어는 `Project.swift`의 `knownRegions`와 앱 Info.plist의 `CFBundleLocalizations`
양쪽에 선언돼 있다. 언어를 추가하려면 두 곳과 각 String Catalog에 번역을 넣으면 된다.

## 구조

```
Sources/
  App/            앱 진입점 (단일 Store)
  ChordFeature/   TCA 리듀서 + SwiftUI 뷰 + UI 문구 번역
  ChordCore/      음악 이론 도메인 + 오디오 의존성 + 음악 용어 번역
Tests/
  ChordCoreTests/     코드/진행 계산 (Swift Testing)
  ChordFeatureTests/  리듀서 (TestStore)
```

의존 방향은 `App → ChordFeature → ChordCore` 한 방향이다. `ChordCore`는 SwiftUI를 모르고,
오디오 엔진은 `AudioPlayerClient` 뒤에 숨어 있어 테스트에서는 소리가 나지 않는다.

## 의존성

TCA는 Xcode 네이티브 SPM으로 붙인다. `Project.swift`의 `packages:`에 선언하고 각 타깃에서
`.package(product:)`로 가져다 쓴다. 패키지 해석은 Xcode가 맡고, 프로젝트 네비게이터의
Package Dependencies에 나타난다.

```swift
packages: [
    .remote(
        url: "https://github.com/pointfreeco/swift-composable-architecture",
        requirement: .exact("1.26.2")
    ),
]
```

해석 결과는 Tuist가 저장소 루트의 `.package.resolved`에 남긴다. 생성된 `.xcodeproj`는
커밋하지 않지만 이 파일은 커밋하므로, 이행 의존성까지 같은 버전으로 재현된다.

## 개발

Tuist 버전은 `.mise.toml`에 고정돼 있다.

```sh
mise install          # Tuist 4.208.0 설치
tuist generate        # Pico.xcworkspace 생성 후 Xcode 열기
```

테스트:

```sh
xcodebuild test -workspace Pico.xcworkspace -scheme Pico-Workspace \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipMacroValidation
```

### 알아둘 점

- TCA는 매크로 패키지라 Xcode에서 처음 빌드할 때 매크로를 신뢰할지 묻는다. 한 번 허용하면 되고,
  CI처럼 프롬프트를 띄울 수 없는 환경에서는 위처럼 `-skipMacroValidation`을 붙인다.
- 앱 모듈은 모두 `.staticFramework`다.
