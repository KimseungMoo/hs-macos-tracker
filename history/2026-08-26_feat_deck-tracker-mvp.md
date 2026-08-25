# 2026-08-26 feat deck-tracker-mvp

## 한 일

설계 2단계 덱 트래커 MVP.

- `Core/Deck/Deckstring` import
- `MatchState` reducer: 잔여, 턴, 마나, 공개 보드
- `DrawOdds.nextDraw` = count / remaining. 투기장 오퍼 확률 없음
- `PowerLogParser`: PowerTaskList + DebugPrintGame만. GameState.DebugPrintPower는 무시
- 미매핑 드로우·gap → remaining unknown
- Tracker UI/오버레이에 잔여·확률 표시
- 테스트: 덱스트링, 확률, reducer, parser

## 넣지 않은 것

- 카드 데이터팩, OCR, 투기장 추천, 처방형 조언
- HSTracker 파서 이식

## 브랜치

`feat/tech-spike` (push 안 함)
