# Pico

피아노 코드를 찾아보고 소리로 확인하는 iOS 앱. Tuist · TCA · SwiftUI로 만들었다.

## 기능

- **코드 찾기** — 루트 12음 × 28가지 코드 성질을 골라 구성음, 도수(R/♭3/5…), 계이름을 확인하고 건반 위에서 짚어 본다. 전위·옥타브 조절, 동시에/아르페지오 재생, 건반 개별 타건 지원.
- **코드 진행** — 팝 진행, 캐논, 투 파이브 원, 12마디 블루스 등 9가지 진행을 원하는 조로 옮겨 듣는다. BPM 조절과 한 코드씩 순차 재생.

소리는 사운드폰트 없이 `AVAudioEngine` 위에서 배음을 쌓아 만든다. (`ChordSynthesizer`)

## 구조

```
Sources/
  App/            앱 진입점 (단일 Store)
  ChordFeature/   TCA 리듀서 + SwiftUI 뷰
  ChordCore/      음악 이론 도메인 + 오디오 의존성
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
