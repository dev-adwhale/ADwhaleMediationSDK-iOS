import UIKit
import AdWhaleSDK

/// 프리로드 배너 — `AdWhaleMediationAdBannerView`
///
/// 광고를 **미리 로드해 두었다가 원하는 시점에 `show()` 로 노출**하는 배너다.
/// 화면이 열리기 전에 광고를 준비해 두면, 화면이 열리는 즉시 공백 없이 광고를 보여줄 수 있다.
///
/// ## 일반 배너와의 차이
/// | | 일반 (`AdWhaleMediationAdView`) | 프리로드 (`AdWhaleMediationAdBannerView`) |
/// |---|---|---|
/// | 노출 시점 | 로드 성공 즉시 | `show()` 호출 시 |
/// | 갱신 광고 노출 | 자동 | 최초 `show()` 이후 자동 |
/// | 클릭 콜백 | `adViewDidClick(_:)` | `bannerDidClick(_:)` |
///
/// ## 반드시 지킬 호출 순서
/// ```
/// addSubview(bannerView)   →   bannerView.loadAd()   →   (로드 성공 후) bannerView.show()
/// ```
/// - `loadAd()` 만 호출하면 광고가 노출되지 않는다. (SDK 1.1.0 부터)
/// - `show()` 를 부르기 전에는 자동 갱신이 보류되어, 미리 받아 둔 광고가 다른 광고로 바뀌지 않는다.
/// - 로드되기 전에 `show()` 를 부르면 `banner(_:didFailToShowWithError:message:)` 로 200 이 온다.
final class PreloadBannerViewController: AdSampleViewController {

    override var defaultPlacementUid: String { SampleConfig.bannerPlacementUid }

    /// 배너를 담을 컨테이너. 사이즈를 바꿀 때 이 안의 배너만 갈아 끼운다.
    private let bannerContainer = UIView()
    private var bannerView: AdWhaleMediationAdBannerView?

    private let sizes: [(String, AdWhaleBannerSize)] = [
        ("320x50", .banner320x50),
        ("320x100", .banner320x100),
        ("300x250", .banner300x250),
        ("250x250", .banner250x250),
        ("Adaptive", .adaptiveAnchor),
    ]
    private var selectedSize: AdWhaleBannerSize = .banner320x50

    private let sizeControl = UISegmentedControl()
    private var containerHeight: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        addNote("'배너 미리 로드'를 누르면 광고를 받아 두기만 하고 화면에는 보이지 않는다. "
                + "로드가 끝난 뒤 '배너 노출 (show)'를 눌러야 노출되고, 그때부터 자동 갱신된다.")

        for (index, item) in sizes.enumerated() {
            sizeControl.insertSegment(withTitle: item.0, at: index, animated: false)
        }
        sizeControl.selectedSegmentIndex = 0
        sizeControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.selectedSize = self.sizes[self.sizeControl.selectedSegmentIndex].1
            self.containerHeight.constant = CGFloat(self.selectedSize.height)
        }, for: .valueChanged)
        addContent(sizeControl)

        bannerContainer.backgroundColor = .tertiarySystemBackground
        bannerContainer.layer.cornerRadius = 6
        containerHeight = bannerContainer.heightAnchor.constraint(equalToConstant: 50)
        containerHeight.isActive = true
        addContent(bannerContainer)

        addButton("배너 미리 로드 (loadAd)") { [weak self] in self?.loadBanner() }
        addButton("배너 노출 (show)") { [weak self] in self?.showBanner() }
        addButton("배너 제거 (destroy)") { [weak self] in self?.destroyBanner() }
    }

    // MARK: - 연동 코드

    private func loadBanner() {
        // 이전 배너가 있으면 정리한다. destroy() 를 빠뜨리면 갱신 타이머가 계속 돈다.
        destroyBanner()

        let banner = AdWhaleMediationAdBannerView()
        banner.placementUid = placementUid
        banner.bannerSize = selectedSize
        banner.delegate = self

        // Adaptive 배너는 노출될 컨테이너의 실제 너비를 알려줘야 한다.
        if selectedSize == .adaptiveAnchor {
            banner.adaptiveAnchorWidth = Int(bannerContainer.bounds.width)
        }

        // 화면 계층에 먼저 붙인다. (loadAd() 보다 먼저)
        banner.translatesAutoresizingMaskIntoConstraints = false
        bannerContainer.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: bannerContainer.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: bannerContainer.centerYAnchor),
        ])
        bannerContainer.layoutIfNeeded()

        bannerView = banner
        adlog("프리로드 배너 loadAd() — placement=\(placementUid), size=\(selectedSize.sizeName) (노출하지 않음)")
        banner.loadAd()
    }

    private func showBanner() {
        guard let banner = bannerView else {
            adlog("배너가 없습니다. '배너 미리 로드'를 먼저 누르세요.")
            return
        }
        // 로드 전이면 banner(_:didFailToShowWithError:message:) 로 200 이 온다.
        adlog("프리로드 배너 show()")
        banner.show()
    }

    private func destroyBanner() {
        guard let banner = bannerView else { return }
        banner.destroy()
        banner.removeFromSuperview()
        bannerView = nil
        adlog("프리로드 배너 destroy()")
    }

    // MARK: - 생명주기 연동

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

// MARK: - AdWhaleMediationAdBannerViewDelegate

extension PreloadBannerViewController: AdWhaleMediationAdBannerViewDelegate {

    func bannerDidReceiveAd(_ bannerView: AdWhaleMediationAdBannerView) {
        // 바로 보여주려면 여기서 show() 를 호출한다. 이 샘플은 버튼으로 노출 시점을 정한다.
        adlog("프리로드 배너 onAdLoaded — 이제 show() 로 노출할 수 있습니다")
    }

    func banner(_ bannerView: AdWhaleMediationAdBannerView,
                didFailToLoadWithError statusCode: Int, message: String) {
        // 300 + "Previous ad is still showing." → 갱신 실패지만 기존 광고는 그대로 노출 중이다.
        adlog("프리로드 배너 onAdLoadFailed(\(statusCode)): \(message)")
    }

    func banner(_ bannerView: AdWhaleMediationAdBannerView,
                didFailToShowWithError statusCode: Int, message: String) {
        adlog("프리로드 배너 onAdShowFailed(\(statusCode)): \(message)")
    }

    func bannerDidClick(_ bannerView: AdWhaleMediationAdBannerView) {
        adlog("프리로드 배너 onAdClicked")
    }
}
