# 2026-08-26 feat arena-local-pick

## 한 일

설계 3단계 투기장 로컬 3장 추천.

- `ArenaDraftDetector`: draft / redraft / idle. 오퍼 카드는 추정하지 않음
- `ArenaCard.parse`: `Name cost tags` 수동 입력. 코스트 없으면 unknown
- `ArenaScorer`: 기본 50 + 커브 구멍 + 제거/드로우/생존 + 태그 시너지(2장부터) + 중복 페널티
- 3장 모두 고신뢰일 때만 pick / alt / reasons
- 다음 오퍼·풀 확률 없음

## 넣지 않은 것

- OCR, HearthArena/HSReplay 점수, 카드 데이터팩
- 처방형 인플레이 조언

## 추가 (전설 버킷)

1픽은 얼굴 전설이 아니라 버킷 평균. 입력 `Legendary 5 | Extra 2 minion | Extra 3`. 세 칸 중 일부만 버킷이면 추천 안 함. 이후 픽은 얼굴만.

전설 클릭 시 버킷은 이름 미리보기만. 긴 이름은 잘림. 상세는 호버. `...`/`…` 이름은 parse 실패(고신뢰 아님).

## 브랜치

`feat/tech-spike` (push 안 함)
