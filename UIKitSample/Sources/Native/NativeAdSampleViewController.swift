import UIKit
import AdWhaleSDK

/// 네이티브 광고 3개 화면의 공통 부분.
///
/// - 네이티브 뷰 컨테이너와 높이 제약
/// - 델리게이트 콜백 로깅
/// - 생명주기(resume / pause / destroy) 연동
///
/// 로드 방식(템플릿 / 스타일 / 커스텀 바인딩)만 하위 클래스가 정한다.
class NativeAdSampleViewController: AdSampleViewController {

    override var defaultPlacementUid: String { SampleConfig.nativePlacementUid }

    /// 네이티브 광고 뷰. `AdWhaleMediationNativeAdView` 가 스스로 소재를 그린다.
    private(set) var nativeAdView: AdWhaleMediationNativeAdView?

    /// 네이티브 컨테이너 (높이를 하위 클래스가 조절한다)
    let nativeContainer = UIView()
    private var containerHeight: NSLayoutConstraint?

    /// 컨텐츠 스택의 현재 위치에 네이티브 컨테이너를 붙인다.
    /// 컨트롤 배치 순서를 하위 클래스가 정할 수 있도록 viewDidLoad 에서 자동으로 붙이지 않는다.
    func installNativeContainer(height: CGFloat) {
        nativeContainer.backgroundColor = .tertiarySystemBackground
        nativeContainer.layer.cornerRadius = 6
        containerHeight = nativeContainer.heightAnchor.constraint(equalToConstant: height)
        containerHeight?.isActive = true
        addContent(nativeContainer)
    }

    /// 네이티브 컨테이너 높이. 템플릿 종류에 따라 다르다.
    func setNativeHeight(_ height: CGFloat) {
        containerHeight?.constant = height
    }

    /// 새 `AdWhaleMediationNativeAdView` 를 만들어 컨테이너에 붙인다.
    ///
    /// 배너와 마찬가지로 **addSubview 가 loadAd 보다 먼저**다.
    @discardableResult
    func attachNativeAdView() -> AdWhaleMediationNativeAdView {
        destroyNativeAdView()

        let native = AdWhaleMediationNativeAdView()
        native.placementUid = placementUid
        native.delegate = self
        native.translatesAutoresizingMaskIntoConstraints = false

        nativeContainer.addSubview(native)
        NSLayoutConstraint.activate([
            native.topAnchor.constraint(equalTo: nativeContainer.topAnchor),
            native.bottomAnchor.constraint(equalTo: nativeContainer.bottomAnchor),
            native.leadingAnchor.constraint(equalTo: nativeContainer.leadingAnchor),
            native.trailingAnchor.constraint(equalTo: nativeContainer.trailingAnchor),
        ])
        nativeContainer.layoutIfNeeded()

        nativeAdView = native
        return native
    }

    func destroyNativeAdView() {
        guard let native = nativeAdView else { return }
        native.destroy()
        native.removeFromSuperview()
        nativeAdView = nil
        adlog("네이티브 destroy()")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nativeAdView?.resume()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        nativeAdView?.pause()
    }

    deinit {
        nativeAdView?.destroy()
    }
}

// MARK: - AdWhaleMediationNativeAdDelegate

extension NativeAdSampleViewController: AdWhaleMediationNativeAdDelegate {

    func nativeAdDidLoad(_ adView: AdWhaleMediationNativeAdView) {
        adlog("네이티브 onAdLoaded")
        // 네이티브는 배너와 달리 최초 노출을 매체사가 직접 붙인다.
        // 한 번 show() 된 뒤의 자동 갱신은 SDK 가 알아서 교체 노출한다.
        adView.show()
    }

    func nativeAd(_ adView: AdWhaleMediationNativeAdView, didFailToLoadWithError statusCode: Int, message: String) {
        // 배너와 동일하게, 자동 갱신 실패(300) 이면서 메시지에
        // "Previous ad is still showing." 이 있으면 기존 광고는 계속 노출 중이다.
        adlog("네이티브 onAdLoadFailed(\(statusCode)): \(message)")
    }

    func nativeAd(_ adView: AdWhaleMediationNativeAdView, didFailToShowWithError statusCode: Int, message: String) {
        adlog("네이티브 onAdShowFailed(\(statusCode)): \(message)")
    }

    func nativeAdDidClick(_ adView: AdWhaleMediationNativeAdView) {
        adlog("네이티브 onAdClicked")
    }

    func nativeAdDidClose(_ adView: AdWhaleMediationNativeAdView) {
        adlog("네이티브 onAdClosed")
    }
}
