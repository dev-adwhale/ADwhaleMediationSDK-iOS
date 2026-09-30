import UIKit
import AdWhaleSDK

/// 팝업 광고 — `AdWhaleMediationPopupAd`
///
/// iOS 에서는 종료 팝업과 전환 팝업이 **하나의 클래스로 통합**되어 있다.
/// (iOS 쪽 네트워크가 둘을 구분하지 않는다. Android 의
///  `AdWhaleMediationExitPopupAd` / 전환 팝업이 여기로 합쳐진다)
///
/// ## AdFit 전용 · 로드/노출이 사실상 한 몸이다
/// AdFit `SuperboardPopUp` 에는 로드 API 가 없고 `present()` 만이 광고를 요청한다.
/// 그래서 `loadAd()` 성공은 **"팝업 준비까지만 성공"** 이라는 잠정 결과이고,
/// 재고가 있는지는 `show(from:)` 전까지 알 수 없다.
///
/// | 단계 | 콜백 | 의미 |
/// |---|---|---|
/// | `loadAd()` | `popupAd(_:didLoadWith:)` | 잠정 성공. 재고 미확인 |
/// | `show()` 성공 | `popupAdDidShow(_:)` | 실제 노출 |
/// | `show()` 재고 없음 | `popupAd(_:didFailToShowWithError:)` **statusCode 300** | 노출 시점에 광고 미충족 |
///
/// ⚠️ **팝업만** 노출 실패에 300 이 올 수 있다. 다른 애드폼의 노출 실패는 전부 200(연동 오류)이다.
/// 그래서 "팝업이 안 뜨면 앱 기본 동작으로 폴백" 하는 처리가 필수다.
class PopupSampleViewController: AdSampleViewController {

    override var defaultPlacementUid: String { SampleConfig.popupPlacementUid }

    private(set) var popupAd: AdWhaleMediationPopupAd?
    private(set) var isLoaded = false

    /// 팝업이 뜨지 못했을 때 실행할 앱 기본 동작.
    /// 하위 클래스가 재정의한다. (종료 확인 / 화면 전환 등)
    func handlePopupUnavailable(reason: String) {}

    /// 팝업이 닫혔을 때. 닫힌 이유에 따라 후속 동작을 결정한다.
    func handlePopupClosed(reason: AdWhalePopupCloseReason) {}

    /// 팝업 버튼 문구. 하위 클래스가 정한다.
    var primaryButtonText: String { "확인" }
    var secondaryButtonText: String { "취소" }
    var customDescription: String { "" }

    // MARK: - 연동 코드

    func loadPopup() {
        popupAd?.destroy()
        isLoaded = false

        let ad = AdWhaleMediationPopupAd(placementUid: placementUid)
        ad.delegate = self

        // 버튼 문구 / 안내 문구는 로드 전에 지정한다.
        ad.setCustomizeButtonText(primaryButtonText: primaryButtonText,
                                  secondaryButtonText: secondaryButtonText)
        if !customDescription.isEmpty {
            ad.setCustomDescription(customDescription)
        }

        popupAd = ad
        adlog("팝업 loadAd() — placement=\(placementUid)")
        ad.loadAd()
    }

    func showPopup() {
        guard let ad = popupAd, isLoaded else {
            adlog("팝업이 준비되지 않았습니다 → 앱 기본 동작으로 폴백")
            handlePopupUnavailable(reason: "not loaded")
            return
        }
        adlog("팝업 show(from:)")
        ad.show(from: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Android 의 exitPopupAd.resume(activity) 과 같은 자리.
        popupAd?.resume()
    }

    deinit {
        popupAd?.destroy()
    }
}

// MARK: - AdWhaleMediationPopupAdDelegate

extension PopupSampleViewController: AdWhaleMediationPopupAdDelegate {

    func popupAdDidLoad(_ ad: AdWhaleMediationPopupAd) {
        isLoaded = true
        adlog("팝업 onAdLoaded (잠정 성공 — 재고는 show 시점에 확정)")
    }

    func popupAd(_ ad: AdWhaleMediationPopupAd, didFailToLoadWithError statusCode: Int, message: String) {
        isLoaded = false
        adlog("팝업 onAdLoadFailed(\(statusCode)): \(message)")
    }

    func popupAdDidShow(_ ad: AdWhaleMediationPopupAd) {
        adlog("팝업 onAdShowed")
    }

    func popupAd(_ ad: AdWhaleMediationPopupAd, didFailToShowWithError statusCode: Int, message: String) {
        // 300 = 노출 시점에 채울 광고가 없음. 팝업에서만 나오는 정상 상황이다.
        adlog("팝업 onAdShowFailed(\(statusCode)): \(message) → 앱 기본 동작으로 폴백")
        isLoaded = false
        handlePopupUnavailable(reason: "showFailed(\(statusCode))")
    }

    func popupAdDidClick(_ ad: AdWhaleMediationPopupAd) {
        adlog("팝업 onAdClicked")
    }

    func popupAd(_ ad: AdWhaleMediationPopupAd, didCloseWithReason reason: AdWhalePopupCloseReason) {
        isLoaded = false
        adlog("팝업 onAdClosed(\(reason.reasonName))")
        handlePopupClosed(reason: reason)
    }
}
