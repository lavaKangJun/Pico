# PICO

피아노 코드를 찾아보고 소리로 확인하는 iOS 앱.

코드 이름은 아는데 어떤 건반을 눌러야 할지 모를 때, 반대로 손에 익은 코드의 이름이
궁금할 때 쓴다. 12음마다 코드를 펼쳐 보여 주고, 건반 위에 구성음을 표시하고, 바로
소리로 들려준다.

## 기능

- **코드 찾기** — 12개 루트 × 28가지 코드 성질. 구성음과 도수(R/♭3/5…), 계이름을
  확인하고 건반 위에서 짚어 본다. 전위와 옥타브를 바꿔 가며 들을 수 있다.
- **소리** — 동시에 또는 아르페지오로 재생. 건반을 하나씩 눌러 볼 수도 있다.
- **표기 전환** — C♯과 D♭처럼 같은 소리의 두 표기를 오갈 수 있다. 표기를 바꿔도
  소리는 그대로다.
- **코드 진행** — 팝 진행, 캐논, 투 파이브 원, 12마디 블루스 등 9가지를 원하는 조로
  옮겨 듣는다. (코드는 살아 있지만 지금은 화면에서 빠져 있다)

한국어로 쓰고 영어 · 日本語 · 简体中文 · 繁體中文을 지원한다.

## 실행

Tuist 버전은 `.mise.toml`에 고정돼 있다.

```sh
mise install          # Tuist 설치
tuist generate        # Pico.xcworkspace 생성 후 Xcode 열기
```

테스트:

```sh
xcodebuild test -workspace Pico.xcworkspace -scheme Pico-Workspace \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipMacroValidation
```

## 만든 방법

Tuist · TCA · SwiftUI. 모듈은 `App → ChordFeature → ChordCore` 한 방향으로 의존하고,
`ChordCore`는 SwiftUI를 모른다.

```
Sources/
  App/            앱 진입점
  ChordFeature/   TCA 리듀서 + SwiftUI 뷰
  ChordCore/      음악 이론 도메인 + 오디오
```

빌드 명령, 모듈 규칙, TCA 사용 방식, 번역과 광고 설정 같은 세부는 [CLAUDE.md](CLAUDE.md)에
정리해 뒀다.

## 라이선스

[MIT](LICENSE)
