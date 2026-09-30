# AdWhale Mediation iOS SDK — 샘플 앱

AdWhale Mediation iOS SDK 연동 예제입니다. **UIKit** 과 **SwiftUI** 두 가지 프로젝트로
같은 기능을 각각 구현해 두었습니다. 두 프로젝트 모두 Swift Package Manager 로 SDK 를 가져옵니다.

```
ADwhaleMediationSDK-iOS/
├── Config/                     # 지면 UID · AdMob App ID (두 프로젝트가 공유)
│   ├── AdWhale.xcconfig
│   └── Local.xcconfig.sample
├── UIKitSample/                # UIKit (UIViewController) 예제
│   ├── UIKitSample.xcodeproj
│   ├── Info.plist
│   └── Sources/
└── SwiftUISample/              # SwiftUI 예제
    ├── SwiftUISample.xcodeproj
    ├── Info.plist
    └── Sources/
```

---

## 설치 — Swift Package Manager

Xcode 에서 **File ▸ Add Package Dependencies…** 를 열고 아래 URL 을 입력합니다.

```
https://github.com/adwhale-sdk/adwhale-sdk-ios.git
```

또는 `Package.swift` 를 쓰는 프로젝트라면 이렇게 선언합니다.

```swift
dependencies: [
    .package(url: "https://github.com/adwhale-sdk/adwhale-sdk-ios.git", from: "1.0.0")
]
```

앱 타겟에 추가할 라이브러리는 **Core 1개 + 사용할 네트워크의 어댑터**입니다.
이 샘플은 배포되는 어댑터를 모두 붙였습니다.

| 라이브러리 | 역할 |
|---|---|
| `AdWhaleSDK` | Core SDK (필수) |
| `AdWhaleAdMobAdapter` | AdMob / Google Ad Manager |
| `AdWhaleCaulyAdapter` | Cauly |
| `AdWhaleAdFitAdapter` | AdFit (팝업 광고는 AdFit 전용) |
| `AdWhaleAdmizeAdapter` | Admize |
| `AdWhaleLevelPlayAdapter` | LevelPlay (ironSource) |

버전을 바꾸려면 Xcode 의 **Package Dependencies** 탭에서 `adwhale-sdk-ios` 의
Dependency Rule 을 수정하면 됩니다.

---

## 실행 방법

```bash
open UIKitSample/UIKitSample.xcodeproj
# 또는
open SwiftUISample/SwiftUISample.xcodeproj
```

1. Xcode 가 SPM 의존성(GoogleMobileAds / Cauly / AdFit / Admize / LevelPlay / UMP)을 자동으로 받습니다.
   최초 1회 네트워크가 필요합니다.
2. 시뮬레이터를 고르고 **Run (⌘R)**.
3. 실기기로 돌리려면 **Signing & Capabilities** 에서 본인 Development Team 을 지정하세요.
   (샘플에는 팀이 지정되어 있지 않습니다)

### 요구사항

| 항목 | 버전 |
|---|---|
| iOS | 15.0+ |
| Swift | 5.9+ |
| Xcode | 16.0+ |

---

## 키 값 (지면 UID) 바꾸기

모든 UID 는 `Config/AdWhale.xcconfig` 한 곳에 있습니다.
Android 샘플의 `res/values/strings.xml` 과 같은 자리입니다.

```
Config/AdWhale.xcconfig  →  Info.plist 변수 치환  →  SampleConfig.swift
```

| Android | iOS (이 샘플) |
|---|---|
| `res/values/strings.xml` | `Config/AdWhale.xcconfig` |
| `AndroidManifest.xml` 의 `<meta-data>` | `Info.plist` |
| `local.properties` (git 미추적) | `Config/Local.xcconfig` (git 미추적) |

> ⚠️ **이 저장소에는 실제 키가 들어 있지 않습니다.**
> `Config/AdWhale.xcconfig` 의 값은 모두 자리표시자이므로, 발급받은 키로 바꾸기 전에는
> 광고가 나오지 않습니다. Android 샘플의 `strings.xml` 과 같은 상태입니다.

| 항목 | 발급처 |
|---|---|
| `ADWHALE_PUBLISHER_UID` · `ADWHALE_PLACEMENT_*` | ADwhale Mediation SDK 가이드 문서 또는 AdWhale 미디에이션 콘솔 |
| `ADWHALE_ADMOB_APP_ID` | Google AdMob 콘솔 |

`AdWhale.xcconfig` 를 직접 고치는 대신, 커밋되지 않는 로컬 오버라이드를 만들 수도 있습니다.

```bash
cp Config/Local.xcconfig.sample Config/Local.xcconfig
# 바꾸고 싶은 항목만 남기고 값 수정
```

---

## 앱에 필수인 설정 3가지

`Info.plist` 를 참고하세요. 샘플에서는 xcconfig 로 값을 주입하고 있습니다.

```xml
<!-- 1. Publisher UID — SDK 가 직접 읽는 유일한 키 -->
<key>net.adwhale.sdk.mediation.PUBLISHER_UID</key>
<string>YOUR_PUBLISHER_UID</string>

<!-- 2. AdMob 어댑터를 링크했다면 필수. 없으면 실행 시점에 크래시한다 -->
<key>GADApplicationIdentifier</key>
<string>YOUR_ADMOB_APP_ID</string>

<!-- 3. IDFA 를 쓰려면 ATT 문구 필수 -->
<key>NSUserTrackingUsageDescription</key>
<string>사용자 맞춤 광고를 제공하기 위해 광고 식별자(IDFA)에 접근합니다.</string>
```

그리고 앱 타겟의 **Other Linker Flags** 에 `-ObjC` 가 필요합니다.
(두 샘플 프로젝트에는 이미 설정되어 있습니다) 이 플래그가 없으면 링커가
Objective-C 어댑터를 제거해 런타임에 워터폴이 파트너 네트워크로 넘어가지 않습니다.

---

## 초기화 순서

```swift
ATT 권한 요청  →  어댑터 register()  →  AdWhaleMediationAds.initialize()
```

- ATT 를 먼저: SDK 는 `ATTrackingManager` 상태를 확인만 하고 팝업은 앱이 직접 띄웁니다.
  초기화 뒤에 허용을 받으면 그 세션의 첫 요청은 IDFA 없이 나갑니다.
- `register()` 를 빠뜨리면 그 네트워크는 워터폴에서 통째로 건너뜁니다.
- `initialize()` 없이 광고를 로드하면 전부 초기화 실패(200)로 떨어집니다.

구현은 `Sources/App/AdWhaleBootstrap.swift` 를 보세요. (두 프로젝트 모두 동일한 이름)

---

## 화면 구성 — Android 샘플과의 대응표

Android 샘플([ADwhaleMediationSDK-Android](https://github.com/dev-adwhale/ADwhaleMediationSDK-Android))
의 `activity_sample_main.xml` 버튼과 맞춰 두었습니다.

| Android 버튼 | UIKitSample | SwiftUISample |
|---|---|---|
| `programmatic banner` | 배너 — 일반 | 배너 — 일반 |
| `xml banner` | 배너 — XIB (Interface Builder) | (해당 없음) |
| `interstitial` | 전면 광고 | 전면 광고 |
| `Reward Ad` | 리워드 광고 | 리워드 광고 |
| `App Open Ad` | 앱오프닝 광고 | 앱오프닝 광고 |
| `Native Ad (for Custom Binding)` | 네이티브 — 커스텀 바인딩 | 네이티브 — 커스텀 바인딩 |
| `Native Ad (for Template Binding)` | 네이티브 — 템플릿 바인딩 | 네이티브 — 템플릿 바인딩 |
| `Native Template Binding Ad (with Style)` | 네이티브 — 템플릿 + 스타일 | 네이티브 — 템플릿 + 스타일 |
| `앱 전환 광고 테스트` | 팝업 — 전환 | 팝업 — 전환 |
| Back 키 종료 팝업 | 팝업 — 종료 | 팝업 — 종료 |
| `etMediaUid` 입력 | 상단 Publisher UID 입력 | 상단 Publisher UID 입력 |

> SwiftUI 에는 레이아웃 XML 이 없어 `xml banner` 에 대응하는 화면이 없습니다.
> 코드로 붙이는 방식(배너 — 일반)이 SwiftUI 의 유일한 경로입니다.

---

## 클래스 대응표 (Android ↔ iOS)

| 애드폼 | Android | iOS |
|---|---|---|
| 배너 (자동 노출) | `AdWhaleMediationAdView` | `AdWhaleMediationAdView` |
| 배너 (프리로드) | — | `AdWhaleMediationAdBannerView` |
| 전면 | `AdWhaleMediationInterstitialAd` | `AdWhaleMediationInterstitialAd` |
| 리워드 | `AdWhaleMediationRewardAd` | `AdWhaleMediationRewardAd` |
| 네이티브 | `AdWhaleMediationNativeAdView` | `AdWhaleMediationNativeAdView` |
| 앱오프닝 | `AdWhaleMediationAppOpenAd` | `AdWhaleMediationAppOpenAd` |
| 종료 팝업 | `AdWhaleMediationExitPopupAd` | `AdWhaleMediationPopupAd` |
| 전환 팝업 | (별도 클래스) | `AdWhaleMediationPopupAd` (동일 클래스) |

iOS 에서는 종료 팝업과 전환 팝업이 하나의 클래스로 통합되어 있습니다.
iOS 쪽 네트워크가 둘을 구분하지 않기 때문입니다.

프리로드 배너(`AdWhaleMediationAdBannerView`)는 iOS 에만 있는 클래스입니다.
로드와 노출을 분리해 원하는 시점에 `show()` 할 수 있으며, 이 샘플에는 화면을 두지 않았습니다.

---

## 콜백 · 에러 코드

| 코드 | 의미 | 대표 상황 | 대응 |
|:---:|---|---|---|
| **100** | 성공 | `initialize()` 완료 | — |
| **200** | **연동 오류** | 초기화 누락, `placementUid` 미설정, 미로드 상태의 `show()`, window 에 없는 VC | 코드 수정 필요. 재시도해도 동일 실패 |
| **300** | **광고 미충족** | 워터폴 전체 소진 | 정상 상황. 자체광고 대체 등 후처리 |

### 알아 두면 좋은 세 가지

**1. 배너 · 네이티브의 "노출 유지" 갱신 실패**

자동 갱신 중 실패(300)해도 이미 노출 중인 광고는 그대로 유지됩니다.

| 메시지 | 상태 | 대응 |
|---|---|---|
| `... Previous ad is still showing.` | 이번 갱신만 실패, 광고는 노출 중 | **아무것도 하지 않기** |
| (해당 문구 없음) | 보여줄 광고 없음 | 자체광고 대체 |

**2. 팝업만 노출 실패에 300 이 온다**

AdFit `SuperboardPopUp` 은 로드 API 가 없고 `present()` 만이 광고를 요청합니다.
그래서 `loadAd()` 성공은 "팝업 준비까지만 성공"인 잠정 결과이고, 재고는 `show()` 시점에 확정됩니다.
**팝업이 뜨지 못해도 앱 기본 동작(종료 확인 / 화면 전환)은 반드시 일어나야 합니다.**
샘플의 `PopupController` / `PopupSampleViewController` 가 그 폴백을 구현하고 있습니다.

**3. delegate 를 설정하지 않으면 실패 콜백이 어디에도 가지 않습니다**

"광고도 안 나오고 콜백도 없다" 면 먼저 이것을 확인하세요.
SDK 가 `통지할 리스너가 없습니다` 경고 로그를 남깁니다.
샘플은 모든 콜백을 화면 하단 로그 콘솔에 찍어 둡니다.

---

## AdMob 미디에이션 파트너 어댑터

InMobi, AppLovin, Vungle, DT Exchange, Mintegral, Pangle, Unity, Moloco 등
AdMob 미디에이션 파트너 어댑터는 AdWhale SDK 패키지에 포함되지 않습니다.
Android SDK 와 마찬가지로 **앱이 직접 SPM 패키지로 추가**합니다.
버전은 AdWhale SDK 저장소 README 의 버전표대로 고정하세요.

---

## 라이선스

[LICENSE](LICENSE) 참고.
