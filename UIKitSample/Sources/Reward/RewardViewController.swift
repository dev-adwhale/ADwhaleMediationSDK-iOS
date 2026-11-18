import UIKit
import AdWhaleSDK

/// 리워드 광고 — `AdWhaleMediationRewardAd`
///
/// Android 샘플의 `ProgrammaticRewardAdMainActivity` 에 대응한다.
///
/// ## delegate 가 3개인 이유
/// | delegate | 언제 |
/// |---|---|
/// | `AdWhaleMediationRewardAdLoadDelegate` | 로드 성공 / 실패 (`loadAd(loadDelegate:)` 인자) |
/// | `AdWhaleRewardedFullScreenDelegate` | 노출 / 클릭 / 닫힘 / 노출 실패 |
/// | `AdWhaleUserEarnedRewardDelegate` | **보상 지급 시점** (`show(from:rewardDelegate:)` 인자) |
///
/// 보상 지급은 `userDidEarnReward` 에서만 판단해야 한다.
/// 광고를 닫았다는 사실(`rewardedAdDidDismiss`)은 보상 조건이 아니다.
///
/// ## SSV (Server-Side Verification)
/// `setUserId` / `setCustomData` 는 AdMob · AdManager · Cauly(Cauly SDK 3.1.25 이상)에서 동작한다.
/// 그 외 네트워크에서는 무시된다.
/// - AdMob · AdManager 는 `show()` 직전의 최신 값이 적용된다.
/// - Cauly 는 로드 요청 때 값을 실으므로 `loadAd()` 전에 설정해야 반영된다.
/// 그래서 이 샘플은 로드 전에 넣고, show 직전에 한 번 더 넣는다.
final class RewardViewController: AdSampleViewController {

    override var defaultPlacementUid: String { SampleConfig.rewardPlacementUid }

    private var rewardAd: AdWhaleMediationRewardAd?
    private var isLoaded = false

    private let userIdField = UITextField()
    private let customDataField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()

        addNote("SSV 값(userId / customData)은 AdMob · AdManager · Cauly(3.1.25 이상)에서 전달된다. Cauly 는 loadAd 전에 설정한 값만 전달되므로 로드 전에 입력한다.")

        userIdField.placeholder = "SSV userId (선택)"
        userIdField.borderStyle = .roundedRect
        userIdField.font = .systemFont(ofSize: 13)
        userIdField.autocapitalizationType = .none
        addContent(userIdField)

        customDataField.placeholder = "SSV customData 의 value (선택)"
        customDataField.borderStyle = .roundedRect
        customDataField.font = .systemFont(ofSize: 13)
        customDataField.autocapitalizationType = .none
        addContent(customDataField)

        addButton("리워드 로드 (loadAd)") { [weak self] in self?.loadAd() }
        addButton("리워드 노출 (show)") { [weak self] in self?.showAd() }
    }

    // MARK: - 연동 코드

    private func loadAd() {
        rewardAd?.destroy()
        isLoaded = false

        let ad = AdWhaleMediationRewardAd(placementUid: placementUid)
        // 노출·클릭·닫힘 콜백용. 로드 콜백은 loadAd(loadDelegate:) 인자로 넘긴다.
        ad.fullScreenDelegate = self
        rewardAd = ad

        // Cauly 는 로드 요청 때 SSV 값을 실으므로 loadAd() 전에 넣는다.
        applySSV(to: ad)
        adlog("리워드 loadAd() — placement=\(placementUid)")
        ad.loadAd(loadDelegate: self)
    }

    private func showAd() {
        guard let ad = rewardAd, isLoaded else {
            adlog("아직 로드되지 않았습니다. loadAd() 를 먼저 호출하세요.")
            return
        }

        // AdMob · AdManager 는 show 직전 값이 반영된다. (Cauly 에는 영향 없음)
        applySSV(to: ad)

        adlog("리워드 show(from:rewardDelegate:)")
        ad.show(from: self, rewardDelegate: self)
    }

    /// 입력한 SSV 값을 광고 인스턴스에 넣는다.
    private func applySSV(to ad: AdWhaleMediationRewardAd) {
        let userId = (userIdField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !userId.isEmpty {
            ad.setUserId(userId)
            adlog("리워드 setUserId(\(userId))")
        }
        let customData = (customDataField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !customData.isEmpty {
            ad.setCustomData(["sample": customData])
            adlog("리워드 setCustomData([\"sample\": \(customData)])")
        }
    }

    deinit {
        rewardAd?.destroy()
    }
}

// MARK: - 로드 콜백

extension RewardViewController: AdWhaleMediationRewardAdLoadDelegate {

    func rewardedAdDidLoad(_ ad: AdWhaleMediationRewardAd) {
        isLoaded = true
        adlog("리워드 onAdLoaded")
    }

    func rewardedAd(_ ad: AdWhaleMediationRewardAd, didFailToLoadWithError statusCode: Int, message: String) {
        isLoaded = false
        adlog("리워드 onAdLoadFailed(\(statusCode)): \(message)")
    }
}

// MARK: - 전체화면 콜백

extension RewardViewController: AdWhaleRewardedFullScreenDelegate {

    func rewardedAdDidShow(_ ad: AdWhaleMediationRewardAd) {
        adlog("리워드 onAdShowed")
    }

    func rewardedAd(_ ad: AdWhaleMediationRewardAd, didFailToShowWithError statusCode: Int, message: String) {
        adlog("리워드 onAdShowFailed(\(statusCode)): \(message)")
    }

    func rewardedAdDidClick(_ ad: AdWhaleMediationRewardAd) {
        adlog("리워드 onAdClicked")
    }

    func rewardedAdDidDismiss(_ ad: AdWhaleMediationRewardAd) {
        isLoaded = false
        adlog("리워드 onAdDismissed — 보상 판단은 여기서 하지 않는다")
    }
}

// MARK: - 보상 지급 콜백

extension RewardViewController: AdWhaleUserEarnedRewardDelegate {

    func userDidEarnReward(_ rewardItem: AdWhaleMediationRewardItem) {
        // 실제 앱에서는 여기서 서버에 보상 지급을 요청한다.
        adlog("보상 지급 — type=\(rewardItem.rewardType), amount=\(rewardItem.rewardAmount)")
    }
}
