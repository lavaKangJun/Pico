#!/bin/zsh
#
# 빌드 번호를 올리고 App Store 제출용 아카이브를 만든다.
#
#   ./Scripts/release.sh                 빌드 번호 +1 → 아카이브
#   ./Scripts/release.sh --version 1.1.0 버전까지 같이 올린다
#   ./Scripts/release.sh --no-bump       번호를 그대로 두고 다시 아카이브한다
#
# 버전과 빌드 번호의 단일 출처는 Project.swift의 marketingVersion·buildNumber다.
# 아카이브가 실패하면 올린 번호를 되돌린다 — 쓰지도 않은 번호를 버릴 이유가 없다.
#
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT_FILE="Project.swift"
WORKSPACE="Pico.xcworkspace"
SCHEME="Pico"
# 자동 서명에 필요하다. 인증서 CN의 4Q2LXTZ8U9가 아니라 OU의 값이 팀 ID다.
TEAM="${DEVELOPMENT_TEAM:-KPUSDZ4348}"

bump=true
new_version=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-bump) bump=false; shift ;;
    --version) new_version="${2:?--version 뒤에 버전을 적는다}"; shift 2 ;;
    -h|--help) sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "모르는 옵션: $1" >&2; exit 1 ;;
  esac
done

# 스토어 버전은 1.0.0처럼 세 자리로 쓴다. 두 자리로 적어도 애플이 받기는 하지만
# 빌드 번호와 함께 1.0.0(1)로 읽히게 형식을 맞춘다.
if [[ -n "$new_version" && ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "버전은 1.0.0 형식으로 적는다: $new_version" >&2
  exit 1
fi

read_constant() {  # read_constant <상수 이름>
  grep -E "^private let $1 = \"" "$PROJECT_FILE" | sed -E 's/.*= "(.*)"/\1/'
}

write_constant() {  # write_constant <상수 이름> <값>
  # macOS sed는 -i에 인자가 필요하다. 백업 파일은 바로 지운다.
  sed -i '' -E "s/^private let $1 = \".*\"/private let $1 = \"$2\"/" "$PROJECT_FILE"
}

old_build=$(read_constant buildNumber)
old_version=$(read_constant marketingVersion)

[[ -n "$new_version" ]] && write_constant marketingVersion "$new_version"
if $bump; then
  write_constant buildNumber "$((old_build + 1))"
fi

version=$(read_constant marketingVersion)
build=$(read_constant buildNumber)
# 1.0.0(1)처럼 스토어에서 읽는 형식 그대로 이름 짓는다.
archive="build/Pico-$version($build).xcarchive"

rollback() {
  write_constant marketingVersion "$old_version"
  write_constant buildNumber "$old_build"
  echo ""
  echo "실패했으므로 버전을 $old_version($old_build)로 되돌렸다."
}
trap rollback ERR

echo "==> $version($build) 아카이브"
[[ -n "$(git status --porcelain --untracked-files=no)" ]] &&
  echo "    (커밋하지 않은 변경이 있다. 아카이브에는 지금 작업 트리 상태가 들어간다)"

# 파일 목록이 바뀌었을 수 있으니 항상 다시 생성한다. Tuist는 생성 시점의 목록을 고정한다.
mise x -- tuist generate --no-open

rm -rf "$archive"
xcodebuild archive \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$archive" \
  -skipMacroValidation \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM" \
  | grep -E '^(\*\*|note:|error:|warning: Crashlytics)|Validation succeeded|ARCHIVE' || true

# 파이프 때문에 xcodebuild의 종료 코드가 묻히므로 산출물로 성공을 판단한다.
if [[ ! -d "$archive/Products/Applications/Pico.app" ]]; then
  echo "아카이브가 만들어지지 않았다." >&2
  exit 1
fi

trap - ERR

echo ""
echo "==> 완료: $archive"
echo "    dSYM: $(ls "$archive/dSYMs" 2>/dev/null | tr '\n' ' ')"
echo ""
echo "다음: Xcode > Window > Organizer에서 Distribute App으로 올린다."
echo "      Project.swift의 버전 변경을 커밋해 둔다."
