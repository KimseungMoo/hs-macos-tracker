# hs-macos-tracker

Apple Silicon Mac용 Hearthstone 덱 트래커·투기장 조언 앱.

**Step 5** — 창모드/보더리스 오버레이 도킹 + unsigned ZIP. 전체화면 공식 지원 아님.

Blizzard 공식 제품 아님.

## 빌드·실행

요구: macOS 14+, Xcode 26+ (Swift 6), Apple Silicon.

```bash
python3 Tools/generate_xcodeproj.py

xcodebuild -project HSMacOSTracker.xcodeproj -scheme HSMacOSTracker \
  -destination 'platform=macOS,arch=arm64' build

xcodebuild -project HSMacOSTracker.xcodeproj -scheme HSMacOSTracker \
  -destination 'platform=macOS,arch=arm64' test

open ~/Library/Developer/Xcode/DerivedData/HSMacOSTracker-*/Build/Products/Debug/HSMacOSTracker.app

# unsigned ZIP (실험용)
bash Tools/package_unsigned.sh
```

Unsigned 실험용 빌드.

## 지금 동작하는 것

- 클릭스루 오버레이 + 읽기 전용 로그 tail
- 덱 코드 import (`Deckstring`)
- `PowerTaskList`만 파싱. 로그 구멍·미매핑 드로우 → 잔여 `unknown`
- 내 잔여 장수와 다음 드로우 확률 (`count / remaining`)
- 공개된 상대 카드·보드. 상대 손·덱·비밀 없음
- 카드 카탈로그는 비어 있음. 이름은 `#dbfId` 또는 `CardID`
- 투기장: `Arena.log`로 draft/redraft 감지. 3장은 수동 입력. 1픽은 전설+버킷(`Face 5 | Extra 2 | Extra 3`) 평균. 잘린 이름(`…`)은 거부(호버 풀네임). 이후는 `Name cost tags`

- 인플레이: 마나 낭비, 공개 위협/제거 리마인더, 내 드로우 확률. 치명타는 체력·딜 숫자가 있을 때만. 처방형 flag off
- 오버레이: 하스 창(windowed/borderless) 오른쪽 도킹, 0.5s 추적. 창 없으면 위치 유지 + `unknown`. Accessibility 없음

## 아직 아님

- 처방형 인플레이 조언 (카드·대상·순서)
- 히어로 체력/보드 공격력 로그 파싱 (치명타 숫자는 아직 비어 있음)
- 다음 오퍼·풀 확률
- ScreenCaptureKit OCR, build-pinned 데이터팩

## 문서

- [docs/design.md](docs/design.md)
- [docs/policy.md](docs/policy.md)

앱·기능 무료. 광고·페이월 없음.

## 라이선스

MIT — [LICENSE](LICENSE)
