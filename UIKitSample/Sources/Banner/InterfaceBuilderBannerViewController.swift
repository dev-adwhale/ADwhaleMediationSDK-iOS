import UIKit
import AdWhaleSDK

/// XIB 로 배치한 배너 — Android 샘플의 `XmlBannerMainActivity` 에 대응한다.
///
/// Interface Builder 에서 `UIView` 를 하나 놓고
/// Identity Inspector 에서 다음을 지정하면 된다.
///
/// | 항목 | 값 |
/// |---|---|
/// | Class | `AdWhaleMediationAdView` |
/// | Module | `AdWhaleSDK` |
///
/// XIB 원본은 `Sources/Banner/IBBanner.xib` 이며, 텍스트 에디터로 열어 보면
/// `customClass="AdWhaleMediationAdView" customModule="AdWhaleSDK"` 한 줄이 전부다.
///
/// XIB 에서는 `placementUid` / `bannerSize` 같은 프로퍼티를 지정할 수 없으므로
/// (Objective-C 로 노출되지만 IBInspectable 이 아니다) 코드에서 채워 준다.
final class InterfaceBuilderBannerViewController: AdSampleViewController {

    override var defaultPlacementUid: String { SampleConfig.bannerPlacementUid }

    /// XIB 안의 `AdWhaleMediationAdView` 로 연결된 아웃렛.
    @IBOutlet private weak var bannerView: AdWhaleMediationAdView!
    /// XIB 의 루트 뷰.
    @IBOutlet private var bannerContentView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        addNote("XIB 에 배치한 AdWhaleMediationAdView 를 코드에서 설정 후 로드한다. "
                + "IB 에서는 Class=AdWhaleMediationAdView, Module=AdWhaleSDK 만 지정하면 된다.")

        // XIB 로드 — File's Owner 가 이 ViewController 다.
        _ = Bundle.main.loadNibNamed("IBBanner", owner: self, options: nil)
        bannerContentView.translatesAutoresizingMaskIntoConstraints = false
        bannerContentView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        addContent(bannerContentView)

        addButton("배너 로드") { [weak self] in self?.loadBanner() }
    }

    private func loadBanner() {
        // 뷰가 이미 계층에 붙어 있으므로 바로 로드해도 된다.
        bannerView.placementUid = placementUid
        bannerView.bannerSize = .banner320x50
        bannerView.delegate = self
        adlog("XIB 배너 loadAd() — placement=\(placementUid)")
        bannerView.loadAd()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bannerView?.resume()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bannerView?.pause()
    }

    deinit {
        bannerView?.destroy()
    }
}

// MARK: - AdWhaleMediationAdViewDelegate

extension InterfaceBuilderBannerViewController: AdWhaleMediationAdViewDelegate {

    func adViewDidReceiveAd(_ adView: AdWhaleMediationAdView) {
        adlog("XIB 배너 onAdLoaded")
    }

    func adView(_ adView: AdWhaleMediationAdView, didFailToLoadWithError statusCode: Int, message: String) {
        adlog("XIB 배너 onAdLoadFailed(\(statusCode)): \(message)")
    }

    func adViewDidClick(_ adView: AdWhaleMediationAdView) {
        adlog("XIB 배너 onAdClicked")
    }
}
