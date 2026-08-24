# Mac 툴 한계 (2026-08-24)

학습 본문(직업 티어·픽 규칙·법사 로그)은 [docs/data/2026-08-24/](data/2026-08-24/)에 있다. 여기는 왜 수동 3장 입력이 필요했는지다.

## 기존 앱

- **HearthArena Companion**: Windows / Overwolf 전용. Mac 오버레이 없음. 웹 드래프트는 영어 카드명.
- **HSTracker 3.6.5**: Mac 덱 오버레이는 됨. Arenasmith급 픽 점수 없음. 이 세션에서 삭제함. `log.config`가 Arena Tracker와 충돌할 수 있음.
- **Arena Tracker v25.10**: Mac 네이티브. 창 모드 + 화면 기록 필요. Intel 바이너리(Rosetta). HSReplay 데이터가 없으면 `getHSRFireCode`에서 `EXC_BAD_ACCESS`. 우회는 Extra stub JSON + `draftMethodHSR=false`. OCR이 카드명을 자주 틀림.

## 이 세션에서 한 일

OCR이 불안정해서 카드 3장 이름을 채팅으로 보내고, 학습 브리프로 픽을 골랐다. 화면을 주기적으로 캡처해 자동 조언하는 경로는 없었다.

## 앱에 가져오지 않는 것

GPL Arena Tracker 코드, All Rights Reserved HDT 코드, `HearthMirror`, HSReplay/HearthArena 스크래핑.
