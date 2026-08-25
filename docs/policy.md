# 정책 경계

## 금지

- 자동 클릭, 입력 주입, 매크로
- 프로세스 메모리 읽기 (`HearthMirror` 등)
- 패킷 가로채기
- 상대 손·덱·비밀 등 화면에 없는 정보로 조언
- 로그 파일 삭제·truncate
- 앱/오버레이 광고 SDK, 추적기, 스폰서 배너
- Premium, 기능 잠금, 후원 인터스티셜
- HSReplay / HearthArena 스크래핑을 런타임 데이터로 사용
- Blizzard 공식 제품·제휴로 오인될 이름과 자산

## 허용하는 입력

- 읽기 전용 로그 tail (`Power.log`, `Arena.log`, `LoadingScreen.log`)
- 사용자가 보낸 카드 이름 또는 수동 수정
- ScreenCaptureKit + Vision OCR (화면 기록 거부 시 수동 입력으로 동작)
- 권리와 TTL을 확인한 뒤 adapter 뒤의 Blizzard API / HearthstoneJSON

인플레이 조언은 visibility filter를 통과한 공개 상태만 쓴다. 확정된 내 덱의 잔여 드로우 확률은 허용한다. 상대 손·덱·비밀 확률과 투기장 미오퍼 풀 확률은 허용하지 않는다.

## 수익

앱과 모든 기능은 무료다. 후원 여부가 기능·지원 우선순위·데이터 접근에 영향을 주지 않는다.

GitHub Sponsors 링크는 README와 프로젝트 웹 문서에만 둔다. Blizzard API를 포함한 공개판의 후원 문구는 Blizzard 서면 확인 후 활성화한다.

Blizzard API 데이터는 광고·홍보·타기팅에 쓰지 않는다.

## 배포 게이트

개인용 프로토타입은 진행한다. 아래는 서면 승인 전 공개 배포를 막는다.

- 투기장 추천
- 특정 카드·대상·순서를 제안하는 처방형 인플레이 조언

Apple Developer Program 가입 전에는 소스 빌드가 기본이다. unsigned 바이너리는 실험용으로만 표시한다. 일반 공개 바이너리는 Developer ID 서명·공증 후 제공한다.

## 저장소에 넣지 않는 것

Blizzard 자산, API secret, 개인 로그, 스크린샷, 서명 인증서, 제3자 점수표 전체 덤프.
