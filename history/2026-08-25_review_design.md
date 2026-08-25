# 2026-08-25 review design

## 한 일

[docs/design.md](../docs/design.md)를 정책·연구·학습 스냅샷과 대조해 검토했다. P0/P1만 설계·정책에 반영했다. 앱 코드는 없다.

## 왜

공개 정책과 단계 분리는 충분하다. 스파이크 착수 스펙으로는 `log.config`, 투기장 `기본 가치` 출처, Visibility 섭취 규칙이 비어 있다.

## 결론

방향은 유지한다. 스파이크 전에 아래를 문서에 고정한다.

## 잘된 점

- 금지선이 [policy.md](../docs/policy.md)와 같다: 자동 클릭, 메모리, 패킷, 숨은 정보, 로그 삭제, 스크래핑, 광고/페이월.
- 모듈 경계: LogReader → GameState → Visibility → UI/Advice.
- 데이터는 build-pinned. 런타임에서 `/latest`를 직접 소비하지 않는다. 모르는 build는 fail-closed.
- 2026-08-24 학습 스냅샷과 런타임 경로를 분리했다.
- 이 Mac에 Xcode가 없음을 숨기지 않았다.
- 공개 바이너리 게이트(Developer ID, Blizzard 승인)가 있다.

## P0

### 1. `log.config`

설계는 로그를 읽기 전용 tail만 했다. Hearthstone은 `log.config` 없으면 `Power.log` / `Arena.log`를 쓰지 않는다.

- 설정: `~/Library/Preferences/Blizzard/Hearthstone/log.config`
- 로그: 보통 `/Applications/Hearthstone/Logs/` (설치 경로에 따라 다름)

앱은 `Power` / `Arena` / `LoadingScreen`만 merge 생성한다. 로그 파일은 삭제·truncate하지 않는다. 기존 Arena Tracker 섹션은 덮어쓰지 않는다. Verbose는 켜지 않는다. 숨은 CardID 유출을 키우지 않기 위해서다. 첫 실행에 HS 재시작 안내가 필요하다.

### 2. 투기장 `기본 가치`

런타임은 HSReplay/HearthArena를 긁지 않는다. HearthstoneJSON은 비용·타입·텍스트·mechanics만 주고 점수는 없다. 2026-08-24 세션 품질은 이 엔진으로 재현되지 않는다.

로컬 휴리스틱: 코스트, 타입, attack/health, rarity, mechanics, 직업 규칙 테이블. 선택으로 사용자 가져오기 점수 파일. 앱이 웹을 긁지 않는다. 학습 스냅샷은 런타임 입력이 아니다.

### 3. Visibility

`Power.log`는 상대 손·덱·비밀 엔터티를 남긴다. Verbose면 CardID가 더 샌다.

파서는 원문을 읽는다. Visibility 경계 밖으로 비공개 필드를 보내지 않는다.

- 허용: 내 손, 공개 보드, 공개된 상대 카드
- 금지: 상대 손/덱/비밀, 미공개 CardID
- 저장·추천·디버그 UI도 같은 필터
- BattleTag, account hi/lo는 섭취 즉시 버림

## P1

- OCR은 후순위. [research.md](../docs/research.md)에서 실패했다. 스파이크 1순위는 수동 3장 입력.
- Accessibility / Automation / FDA 요청 없음은 비샌드박스 기준. Screen Recording은 OCR용으로만. 거부 시 수동.
- HSTracker는 덱스트링 + 로그 문법만 vendor. 오버레이는 새로 짠다. MIT 고지 유지.
- 소스는 공개돼도 Release 바이너리의 투기장/처방형 조언은 기본 OFF.
- 첫 코드는 `Core/*` + SwiftPM + `swift test`. `App/`는 Xcode 이후.
- p95 500ms, 이벤트 손실 0은 MVP/안정화. 스파이크는 경로 입증만.

## P2 (나중에)

이벤트 목록, 오버레이 기하, koKR/enUS 카드명 테이블, 투기장 vs 정규 덱 모델, feature flag 종류, lethal 범위, 첫 실행 UX.

## 넣은 것

- 이 기록
- design.md / policy.md의 P0·P1 문구
- README 링크

## 넣지 않은 것

앱 코드, Swift 패키지, CI, Notion 페이지, P2 상세 스펙.
