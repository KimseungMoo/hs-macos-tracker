# 2026-08-25 feat core-until-test

## 한 일

Xcode/`App/` 없이 실제 로그 테스트 직전까지의 Core를 넣었다. 덱스트링, 잔여 덱, 공개 보드/마나, 투기장 휴리스틱, 결정론 조언, `hs-core` CLI.

## 왜

이 환경과 사용자 Mac 모두 Xcode가 없다. 설계상 `App/` 전 단계는 SwiftPM으로 끝낸다.

## 넣은 것

- `Data/CardCatalog` + 작은 sample-pack (테스트/CLI용, 전체 티어 덤프 아님)
- 덱스트링 encode/decode
- Tracker 잔여·공개 상대 카드
- Arena 추천: 고신뢰 3장 + build pin + flag. Release 기본 OFF
- Advice: lethal / 미사용 마나 / 공개 위협·제거. 처방형은 flag
- `swift run hs-core` 로 로그 파일 섭취

## 넣지 않은 것

`App/` 오버레이, OCR, 실제 Hearthstone 프로세스 연동, HSReplay 스크래핑, CI.
