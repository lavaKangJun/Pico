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

## 개발

Tuist 버전은 `.mise.toml`에 고정돼 있다.

```sh
mise install          # Tuist 4.208.0 설치
tuist install         # SPM 의존성 내려받기
tuist generate        # Pico.xcworkspace 생성 후 Xcode 열기
```

테스트:

```sh
xcodebuild test -workspace Pico.xcworkspace -scheme Pico-Workspace \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### 알아둘 점

- Tuist 4.174 이하는 SPM traits를 읽지 못해 swift-navigation의 `CasePaths` 의존성이 그래프에서
  빠진다. 이 프로젝트가 Tuist 4.208을 고정하는 이유다.
- 모듈은 모두 `.staticFramework`이고, 외부 패키지도 `baseProductType: .staticFramework`로 묶는다.
