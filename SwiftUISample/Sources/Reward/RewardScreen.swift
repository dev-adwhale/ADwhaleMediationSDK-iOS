import SwiftUI
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
/// `setUserId` / `setCustomData` 는 **AdMob 전용**이며 `show()` 시점의 최신 값이 적용된다.
struct RewardScreen: View {
    @StateObject private var controller = RewardController()
    @State private var placementUid = SampleConfig.rewardPlacementUid
    @State private var userId = ""
    @State private var customData = ""

    var body: some View {
        AdSampleScreen(title: "리워드 광고", placementUid: $placementUid) {
            SampleNote("SSV 값(userId / customData)은 AdMob 전용이며 show() 시점의 값이 전달된다.")

            TextField("SSV userId (선택)", text: $userId)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            TextField("SSV customData 의 value (선택)", text: $customData)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            SampleButton("리워드 로드 (loadAd)") { controller.load(placementUid: placementUid) }
            SampleButton("리워드 노출 (show)") { controller.show(userId: userId, customData: customData) }
        }
    }
}

final class RewardController: NSObject, ObservableObject {
    private var ad: AdWhaleMediationRewardAd?
    private var isLoaded = false

    func load(placementUid: String) {
        ad?.destroy()
        isLoaded = false

        let ad = AdWhaleMediationRewardAd(placementUid: placementUid)
        // 노출·클릭·닫힘 콜백용. 로드 콜백은 loadAd(loadDelegate:) 인자로 넘긴다.
        ad.fullScreenDelegate = self
        self.ad = ad

        adlog("리워드 loadAd() — placement=\(placementUid)")
        ad.loadAd(loadDelegate: self)
    }

    func show(userId: String, customData: String) {
        guard let ad, isLoaded else {
            adlog("아직 로드되지 않았습니다. loadAd() 를 먼저 호출하세요.")
            return
        }
        guard let host = TopViewController.find() else {
            adlog("최상단 ViewController 를 찾지 못했습니다.")
            return
        }

        // SSV 값은 show 직전에 넣어도 반영된다.
        let trimmedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedUserId.isEmpty {
            ad.setUserId(trimmedUserId)
            adlog("리워드 setUserId(\(trimmedUserId))")
        }
        let trimmedCustomData = customData.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCustomData.isEmpty {
            ad.setCustomData(["sample": trimmedCustomData])
            adlog("리워드 setCustomData([\"sample\": \(trimmedCustomData)])")
        }

        adlog("리워드 show(from:rewardDelegate:)")
        ad.show(from: host, rewardDelegate: self)
    }

    deinit { ad?.destroy() }
}

// MARK: - 로드 콜백

extension RewardController: AdWhaleMediationRewardAdLoadDelegate {

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

extension RewardController: AdWhaleRewardedFullScreenDelegate {

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

extension RewardController: AdWhaleUserEarnedRewardDelegate {

    func userDidEarnReward(_ rewardItem: AdWhaleMediationRewardItem) {
        // 실제 앱에서는 여기서 서버에 보상 지급을 요청한다.
        adlog("보상 지급 — type=\(rewardItem.rewardType), amount=\(rewardItem.rewardAmount)")
    }
}
