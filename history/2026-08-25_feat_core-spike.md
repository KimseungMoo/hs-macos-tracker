# 2026-08-25 feat core-spike

## 한 일

스파이크 경로를 SwiftPM `Core/`로 구현했다. LogReader, GameState, Visibility, 수동 3장 입력, `swift test`.

## 왜

설계상 첫 코드는 `Core/*`다. 이 에이전트는 Linux라 Xcode를 쓸 수 없다. `App/` 오버레이는 보류.

## 확인

- 이 환경: Ubuntu 24.04 x86_64. `xcodebuild` 없음. Swift 6.3.3 (Swiftly).
- 사용자 Mac(설계 기록): Xcode.app 없음, CLT + Swift 6.1.2. `Package.swift` tools version은 6.1.

## 넣은 것

- `log.config` merge (Power/Arena/LoadingScreen, Verbose 추가 없음)
- 읽기 전용 tail (부분 라인, truncate 시 리셋, 파일 축소 없음)
- Power/Arena/LoadingScreen 파서 + reducer
- Visibility: 상대 손 차단, 계정 식별자 redact
- 수동 3장 입력 (high confidence)
- Release flag 기본 OFF

## 넣지 않은 것

`App/` 오버레이, OCR, HSTracker vendor, 투기장 점수 엔진, Xcode 프로젝트.
