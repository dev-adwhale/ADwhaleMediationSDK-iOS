import Foundation

/// 샘플에서 사용하는 Publisher / Placement UID 모음.
///
/// ## 값이 오는 경로
/// ```
/// Config/AdWhale.xcconfig ─→ Info.plist 변수 치환 ─→ SampleConfig (이 파일)
/// ```
/// Android 샘플의 `res/values/strings.xml` → `R.string` 경로와 같은 모양이다.
///
/// | Android | iOS (이 샘플) |
/// |---|---|
/// | `res/values/strings.xml` | `Config/AdWhale.xcconfig` |
/// | `AndroidManifest.xml <meta-data>` | `Info.plist` |
/// | `local.properties` (git 미추적) | `Config/Local.xcconfig` (git 미추적) |
///
/// > `AdWhaleSampleConfig` 딕셔너리는 SDK 규격이 아니라 이 샘플만의 구조다.
/// > SDK 가 Info.plist 에서 직접 읽는 키는 `net.adwhale.sdk.mediation.PUBLISHER_UID` 하나뿐이다.
enum SampleConfig {

    // MARK: - Info.plist 읽기

    private static let dictionary: [String: Any] = {
        Bundle.main.object(forInfoDictionaryKey: "AdWhaleSampleConfig") as? [String: Any] ?? [:]
    }()

    /// xcconfig 가 빌드 구성에 연결되지 않았거나 값이 비어 있으면 치환되지 않은
    /// `$(ADWHALE_...)` 문자열이 그대로 들어온다. 그 경우 `fallback` 을 쓰고 경고를 남긴다.
    ///
    /// > 이 저장소의 기본값은 실제 키가 아니라 자리표시자다.
    /// > `Config/AdWhale.xcconfig` 에 발급받은 키를 넣어야 광고가 나온다.
    private static func resolve(_ key: String, _ fallback: String) -> String {
        guard let raw = dictionary[key] as? String else {
            print("[SampleConfig] Info.plist AdWhaleSampleConfig.\(key) 없음 → 기본값 사용")
            return fallback
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty || value.contains("$(") {
            print("[SampleConfig] \(key) 가 치환되지 않았습니다(\"\(raw)\") → 기본값 사용. "
                  + "Config/AdWhale.xcconfig 가 base configuration 으로 연결됐는지 확인하세요.")
            return fallback
        }
        return value
    }

    // MARK: - Publisher UID

    /// Publisher UID.
    ///
    /// SDK 는 이 값을 `Info.plist` 에서 직접 읽으므로 평소에는 코드에서 넘길 필요가 없다.
    /// 코드로 넘기고 싶다면 `AdWhaleMediationAds.initialize(publisherUid:completion:)` 를 쓴다.
    /// (샘플 메인 화면의 "이 UID 로 다시 초기화" 버튼이 그 경로를 보여준다)
    static let publisherUid: String = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "net.adwhale.sdk.mediation.PUBLISHER_UID") as? String
        let value = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty || value.contains("$(") {
            print("[SampleConfig] PUBLISHER_UID 가 치환되지 않았습니다 → 기본값 사용")
            return "ADwhale Mediation SDK 가이드 내 키값 참조"
        }
        return value
    }()

    // MARK: - Placement UID (애드폼별)

    static let bannerPlacementUid       = resolve("BannerPlacementUid", "ADwhale Mediation SDK 가이드 내 키값 참조")
    static let interstitialPlacementUid = resolve("InterstitialPlacementUid", "ADwhale Mediation SDK 가이드 내 키값 참조")
    static let rewardPlacementUid       = resolve("RewardPlacementUid", "ADwhale Mediation SDK 가이드 내 키값 참조")
    static let nativePlacementUid       = resolve("NativePlacementUid", "ADwhale Mediation SDK 가이드 내 키값 참조")
    static let appOpenPlacementUid      = resolve("AppOpenPlacementUid", "ADwhale Mediation SDK 가이드 내 키값 참조")
    /// 팝업(종료 / 전환 공용) 지면 UID
    static let popupPlacementUid        = resolve("PopupPlacementUid", "ADwhale Mediation SDK 가이드 내 키값 참조")

    // MARK: - 진단

    static var summary: String {
        """
        publisherUid=\(publisherUid)
        banner=\(bannerPlacementUid) interstitial=\(interstitialPlacementUid) reward=\(rewardPlacementUid)
        native=\(nativePlacementUid) appOpen=\(appOpenPlacementUid) popup=\(popupPlacementUid)
        """
    }
}
