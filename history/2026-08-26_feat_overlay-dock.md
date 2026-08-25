# 2026-08-26 feat overlay-dock

## 한 일

설계 5단계 안정화 최소분.

- `GameWindowLocator`: on-screen Hearthstone 창. 없으면 nil
- `OverlayLayout`: Quartz→AppKit, 오른쪽 도킹, 스크린 clamp
- 오버레이 0.5s follow. Spaces `canJoinAllSpaces`. 클릭스루 유지
- `Tools/package_unsigned.sh` unsigned ZIP

## 넣지 않은 것

- 전체화면 공식 지원
- Developer ID / 공증 / Sparkle
- Accessibility
