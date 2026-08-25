# macOS Hearthstone 덱 트래커 설계

## 목표와 경계

- macOS 14+ / Apple Silicon부터 시작한다.
- GitHub 공개 저장소, MIT. HSTracker에서 재사용한 MIT 코드의 저작권 고지는 따로 보존한다.
- 자동 클릭, 메모리 읽기, 패킷 가로채기, 숨은 정보 활용은 금지한다. 인플레이는 화면에서 확인 가능한 상태에 대한 조언만 한다.
- 개인용 프로토타입은 진행한다. 투기장 추천·처방형 조언의 공개 배포는 Blizzard 서면 승인 전 차단한다.

정책 상세는 [policy.md](policy.md).

## 이 Mac의 툴체인 (2026-08-26)

- Xcode 26.0.1 (17A400) at `/Applications/Xcode-26.0.1.app`
- `xcode-select` → 그 Developer 디렉터리
- Swift 6.2 (swiftlang-6.2.0.19.9)
- Apple Developer Program($99)은 로컬 빌드에 필요 없다. unsigned 바이너리는 실험용으로만 표시한다.

2026-08-24 스냅샷은 Xcode.app 없음 + CLT 16.4 + Swift 6.1.2였다. Electron/Tauri는 MVP 경로가 아니다.

## 공개·수익 모델

- 앱과 모든 기능은 무료. Premium, 기능 잠금, 후원 인터스티셜, 보상형 광고 없음.
- 수익은 GitHub Sponsors 등 외부 자발 후원만. 후원 여부가 기능·지원·데이터 접근에 영향을 주지 않는다.
- 앱과 오버레이에 광고 SDK, 추적기, 스폰서 배너 없음.
- Apple Developer Program 가입 전에는 소스 빌드가 기본이다. unsigned 바이너리는 실험용으로만 표시한다.
- Sponsors 링크는 README와 웹 문서에만 둔다. Blizzard API를 포함한 공개판의 후원 문구는 서면 확인 후 활성화한다.

## 최소 아키텍처

- `App/`: SwiftUI 설정·상태 UI와 AppKit 클릭스루 `NSPanel` 오버레이
- `Core/LogReader/`: `Power.log`, `Arena.log`, `LoadingScreen.log`를 삭제·truncate 없이 읽는 tailer. rotation, 재접속, 부분 라인 처리
- `Core/GameState/`: typed event와 순수 reducer
- `Core/Visibility/`: 추천 앞에서 상대 손·덱·비밀 등 비공개 필드 제거
- `Data/CardCatalog/`: 게임 빌드에 고정한 카드 메타데이터와 로컬 캐시
- `Features/Tracker/`, `Features/Arena/`, `Features/Advice/`: feature flag로 분리

HSTracker의 MIT 로그 파서·덱스트링·오버레이만 선별 재사용한다. `HearthMirror`, 위험 entitlement, 로그 삭제, GPL Arena Tracker, All Rights Reserved HDT 코드는 가져오지 않는다.

## 구현 단계

1. **기술 스파이크**
   - 로그 위치·빌드 감지, 읽기 전용 tailing, 창 모드 오버레이
   - ScreenCaptureKit으로 Hearthstone 창만 선택, Vision OCR로 koKR/enUS 카드명. 화면 기록 거부 시 수동 입력
2. **덱 트래커 MVP**
   - 덱 코드 import, 내 덱 잔여, 공개된 상대 카드, 턴·마나·공개 보드
   - 경기 중: 확정된 내 덱과 이미 뽑힌 카드로 잔여 드로우 확률을 계산한다 (예: 남은 20장 중 Fireball 2장 → 다음 드로우 2/20). 상대 덱·손·비밀 확률은 계산하지 않는다
   - 로그 누락·재접속·미지원 빌드는 추정하지 않고 `unknown`
3. **투기장 덱 추천**
   - `Arena.log`로 draft/redraft 감지. OCR 또는 수동 입력으로 3장 확정
   - 외부 비공개 점수 API 대신 로컬 규칙: 기본 가치 + 마나 곡선 + 제거/드로우/생존 + 태그 시너지 + 중복 페널티
   - 세 카드가 모두 고신뢰일 때만 추천·차선·이유·confidence
   - 1픽은 큐레이트 전설 버킷. 얼굴 전설이 아니라 버킷(전설+포함 카드) 평균으로 고른다. 버킷을 쓰기 시작했으면 세 칸 모두 채운다. 일부만 알면 추천하지 않는다
   - 1픽 버킷 UI: 전설을 클릭하면 포함 카드 **이름 미리보기**가 뜬다. 긴 이름은 잘린다. 카드 상세는 마우스 호버 툴팁에서만 확실하다. 잘린 이름(`…`)은 고신뢰가 아니므로 추천하지 않는다. OCR도 리스트 텍스트가 아니라 호버 프리뷰를 쓴다
   - 아직 안 나온 오퍼·남은 풀 확률·기대값은 계산하지 않는다. 지금 3장(또는 1픽 버킷) + 이미 집은 카드만
4. **인플레이 실시간 조언**
   - 처음에는 치명타 가능성, 마나 미사용, 공개 위협·제거기 리마인더, 내 잔여 드로우 확률 표시 같은 결정론적 조언만
   - 처방형(특정 카드·대상·순서, 또는 확률을 이유로 한 수 지시)은 flag로 격리. 입력 자동화 없음
5. **안정화**
   - windowed/borderless 공식 지원. 오버레이는 하스 창 오른쪽에 붙고, 창을 따라간다. 창 없으면 `unknown` (전체화면은 공식 지원 아님)
   - Quartz→AppKit 좌표 + 창이 있는 스크린으로 clamp (Retina·외부 모니터). Spaces는 `canJoinAllSpaces`
   - 초기에는 소스 빌드와 수동 ZIP (`Tools/package_unsigned.sh`). Developer ID·공증·Sparkle은 승인된 공개 배포 단계
6. **오픈소스 공개**
   - 재현 가능한 빌드, 최소 기여 가이드, 라이선스·제3자 고지, 익명화 fixture
   - GitHub Actions는 빌드·테스트·데이터 diff까지. 승인되지 않은 추천 데이터나 바이너리 자동 배포 없음

## Hearthstone 업데이트 반영

- `Tools/UpdateData/`가 카드 데이터 build를 감지하고 build-pinned snapshot을 받는다. 런타임에서 `/latest`를 직접 소비하지 않는다.
- 카드 텍스트·수치 변경은 테스트 통과 후 로컬 데이터팩 후보. Arena pool, 로그 문법, 규칙 의미 변경은 diff 검토 후 수동 승인.
- `Tests/Fixtures/`에 익명화 golden 로그와 koKR/enUS OCR 이미지.
- 모르는 게임 build면 추천을 끄고 추적 가능한 사실만 표시. 마지막 정상 데이터팩은 보존.
- HSReplay/HearthArena scraping은 사용하지 않는다. Blizzard API·HearthstoneJSON은 권리와 TTL 확인 후 adapter 뒤에서만.

2026-08-24 픽 세션은 웹 티어를 사람이 읽고 조언했다. 그 스냅샷은 [data/2026-08-24/](data/2026-08-24/)에 있다. 앱의 런타임 엔진과 같은 경로가 아니다.

## 검증 기준

- arm64 네이티브. Accessibility·Automation·Full Disk Access 요청 없음
- 로그 rotation·재접속·부분 라인에서 이벤트 손실·중복 0건, 표시 지연 p95 500ms 이하
- 숨은 엔터티가 UI·추천 입력·저장소로 전달되는 테스트 0건
- OCR fixture에서 잘못된 카드로 추천 0건. 불확실하면 수동 수정 요청
- 1픽 버킷 잘린 이름(`…`)으로 추천 0건. 호버 풀네임 또는 수동 확정만
- 오버레이가 게임 클릭을 막는 사례 0건
- 미지원 build·손상 데이터팩은 첫 추천 전 fail-closed
- 기본 로컬 처리. 스크린샷 저장·업로드 없음. 계정 식별자 저장 없음

## 후순위

투기장 다음 오퍼·남은 풀 확률, Windows, Electron/Tauri, 클라우드 LLM, 자체 통계 서버, 자동 업데이트, App Store는 MVP에서 제외한다.

일반 공개 바이너리 배포 시에만 Apple Developer Program, Developer ID·공증, Blizzard 승인, 데이터 공급 계약을 게이트로 추가한다.

광고, 유료 기능, 후원자 전용 기능은 계획에서 제외한다.
