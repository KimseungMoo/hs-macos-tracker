# hs-macos-tracker

Apple Silicon Mac용 Hearthstone 덱 트래커·투기장 조언 앱의 설계와 학습 스냅샷.

`Core/` SwiftPM 라이브러리가 있다. `App/` SwiftUI 오버레이와 Xcode 프로젝트는 아직 없다.

이 프로젝트는 Blizzard의 공식 제품이 아니다.

## 지금 있는 것

- [docs/design.md](docs/design.md) — 아키텍처와 구현 단계
- [docs/policy.md](docs/policy.md) — 금지 행위와 공개 배포 게이트
- [docs/research.md](docs/research.md) — Mac 기존 툴 한계
- [docs/data/2026-08-24/](docs/data/2026-08-24/) — 2026-08-24 지하 투기장 실시간 픽에 쓴 학습 데이터
- [history/2026-08-25_review_design.md](history/2026-08-25_review_design.md) — 설계 검토와 P0/P1 반영
- `Core/` — LogReader, GameState, Visibility (SwiftPM)
- `Data/CardCatalog`, `Features/{Tracker,Arena,Advice}` — 덱 잔여·투기장 휴리스틱·결정론 조언
- `hs-core` — Xcode 없이 로그 파일을 읽는 CLI

## 목표

1. 투기장 덱 추천
2. 인플레이 실시간 조언 (화면에 보이는 상태만)
3. 하스스톤 업데이트 반영 (build-pinned 데이터팩)

앱과 기능은 무료. 광고·페이월 없음. 후원은 GitHub Sponsors 등 외부 자발 후원만.

## 데이터 출처 고지

`docs/data/2026-08-24/`는 그날 픽 조언에 쓴 **요약과 픽 로그**다.

- 직업 승률: [HSReplay Underground Arena](https://hsreplay.net/arena/) Last 1 Day (2026-08-24)
- 카드 점수: [HearthArena tierlist](https://www.heartharena.com/tierlist) (같은 날)
- 포맷: [Hearthstone Wiki Arena](https://hearthstone.wiki.gg/wiki/Arena) Season 47

제3자 점수표 전체는 재배포하지 않는다. 앱 런타임도 HSReplay/HearthArena를 스크래핑하지 않는다.

## 빌드 상태

네이티브 SwiftUI/AppKit `.app`은 **Xcode 26.0.1** 기준이다. `Core/*`와 `hs-core`는 Xcode 없이 `swift test` / `swift run`으로 돌린다.

```
swift test
swift run hs-core --catalog Data/CardCatalog/sample-pack.json --pick '화염구|얼음 화살|얼음 방패'
```

투기장 추천은 `--enable-arena`와 핀된 build(예: `--loading`)가 있어야 켜진다. 처방형 조언은 `--enable-prescriptive`. 둘 다 기본 OFF.

Electron/Tauri는 MVP 경로가 아니다. `App/` 오버레이는 Xcode 26.0.1에서 연다.

## 라이선스

MIT. 자세한 내용은 [LICENSE](LICENSE).
