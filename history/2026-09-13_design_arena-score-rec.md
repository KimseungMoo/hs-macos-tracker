# 2026-09-13 design arena-score-rec

## 한 일

투기장 픽·30장 추천을 Arena 숫자 점수만 쓰도록 바꿨다. 커브·시너지·매치업·가능한 덱 조합 계산은 빼냈다.

카드 등급(레터)이 다를 때는 숫자를 유일한 비교 키로 고정했다. 레터는 표시용이다. 직업 점수가 있으면 공통 점수보다 앞선다. 숫자가 없으면 추천하지 않는다.

## 왜

모든 덱 상황을 계산하는 방식은 입력이 없고 규칙이 늘어난다. 가져온 점수 파일만으로도 픽/차선/30장을 고를 수 있다.

## 넣은 것

- `Core/GameState/ArenaScore.swift`와 테스트
- [docs/arena-score-rec.md](../docs/arena-score-rec.md)
- design.md 3단계, ideas.md §3, README 링크

## 넣지 않은 것

점수 파일 로더, HSReplay/HearthArena 스크래핑, 로컬 휴리스틱 대체 점수, 레터-only 랭킹.
