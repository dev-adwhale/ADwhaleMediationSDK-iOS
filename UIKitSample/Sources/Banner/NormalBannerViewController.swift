import UIKit
import AdWhaleSDK

/// 일반 배너 — `AdWhaleMediationAdView`
///
/// Android 샘플의 `ProgrammaticBannerMainActivity` 에 대응한다.
///
/// ## 프리로드 배너와의 차이
/// | | 일반 (`AdWhaleMediationAdView`) | 프리로드 (`AdWhaleMediationAdBannerView`) |
/// |---|---|---|
/// | 노출 시점 | 로드 성공 시 **자동 노출** | `show()` 를 부를 때 |
/// | 쓰는 곳 | 화면에 항상 떠 있는 배너 | 노출 타이밍을 앱이 정해야 할 때 |
///
/// ## 반드시 지킬 호출 순서
/// ```
/// addSubview(bannerView)   →   bannerView.loadAd()
/// ```
/// attach 하기 전에 `loadAd()` 를 부르면 SDK 가 parent ViewController 를 찾지 못해 실패한다.
final class NormalBannerViewController: AdSampleViewController {

    override var defaultPlacementUid: String { SampleConfig.bannerPlacementUid }

    /// 배너를 담을 컨테이너. 사이즈를 바꿀 때 이 안의 배너만 갈아 끼운다.
    private let bannerContainer = UIView()
    private var bannerView: AdWhaleMediationAdView?

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

        addNote("사이즈를 고르고 '배너 로드'를 누르면 해당 사이즈로 다시 로드한다. "
                + "배너가 로드에 성공하는 순간 자동으로 노출된다.")

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

        addButton("배너 로드") { [weak self] in self?.loadBanner() }
        addButton("배너 제거 (destroy)") { [weak self] in self?.destroyBanner() }
    }

    // MARK: - 연동 코드

    private func loadBanner() {
        // 이전 배너가 있으면 정리한다. destroy() 를 빠뜨리면 갱신 타이머가 계속 돈다.
        destroyBanner()

        let banner = AdWhaleMediationAdView()
        banner.placementUid = placementUid
        banner.bannerSize = selectedSize
        banner.delegate = self

        // Adaptive 배너는 노출될 컨테이너의 실제 너비를 알려줘야 한다.
        if selectedSize == .adaptiveAnchor {
            banner.adaptiveAnchorWidth = Int(bannerContainer.bounds.width)
        }

        banner.translatesAutoresizingMaskIntoConstraints = false
        bannerContainer.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: bannerContainer.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: bannerContainer.centerYAnchor),
        ])
        // 레이아웃이 확정된 뒤에 로드해야 parent ViewController 탐색이 안전하다.
        bannerContainer.layoutIfNeeded()

        bannerView = banner
        adlog("배너 loadAd() — placement=\(placementUid), size=\(selectedSize.sizeName)")
        banner.loadAd()
    }

    private func destroyBanner() {
        guard let banner = bannerView else { return }
        banner.destroy()
        banner.removeFromSuperview()
        bannerView = nil
        adlog("배너 destroy()")
    }

    // MARK: - 생명주기 연동
    //
    // 배너는 백그라운드에서 갱신 타이머를 돌릴 이유가 없다.
    // Android 의 onResume / onPause / onDestroy 와 같은 자리다.

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

extension NormalBannerViewController: AdWhaleMediationAdViewDelegate {

    func adViewDidReceiveAd(_ adView: AdWhaleMediationAdView) {
        adlog("배너 onAdLoaded")
    }

    func adView(_ adView: AdWhaleMediationAdView, didFailToLoadWithError statusCode: Int, message: String) {
        // 300 + "Previous ad is still showing." → 갱신 실패지만 기존 광고는 그대로 노출 중이다.
        //   이 경우 자체광고로 대체하면 안 된다. (README 의 "노출 유지" 표 참고)
        adlog("배너 onAdLoadFailed(\(statusCode)): \(message)")
    }

    func adViewDidClick(_ adView: AdWhaleMediationAdView) {
        adlog("배너 onAdClicked")
    }
}
