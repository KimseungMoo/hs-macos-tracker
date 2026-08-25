# 2026-08-26 feat tech-spike

## 한 일

design step 1 기술 스파이크 구현.

- `HSMacOSTracker.xcodeproj` + `Tools/generate_xcodeproj.py`
- `App/`: SwiftUI 설정 UI, click-through `NSPanel` 오버레이
- `Core/LogReader/`: read-only tail (`LogTailReader`, `LogLineBuffer`, `LogPaths`, `MultiLogTailService`)
- `Core/GameState/GameBuildDetector`: LoadingScreen 명시 마커만; 없으면 unknown
- `Core/Visibility/`: `FeatureFlags` stub, `ScreenCaptureGate` (preflight only)
- `Features/*`, `Data/CardCatalog/`: step 2 stub
- `Tests/LogReaderTests.swift`: partial line·rotation·build detection

## 검증

```bash
python3 Tools/generate_xcodeproj.py
xcodebuild -project HSMacOSTracker.xcodeproj -scheme HSMacOSTracker \
  -destination 'platform=macOS,arch=arm64' build test
```

2026-08-26: build + test 6/6 pass (Xcode 26.0.1, macOS 15.7.3 arm64).

## 넣지 않은 것 (step 2)

- 덱 트래커 / Arena draft / 인플레이 조언 로직
- ScreenCaptureKit stream + Vision OCR
- Card catalog / reducer / visibility filter 본 구현
- HSTracker 코드 이식, 커밋

## 브랜치

`feat/tech-spike` (push 안 함)
