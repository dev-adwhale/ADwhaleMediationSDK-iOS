import UIKit
import AdWhaleSDK

/// 전면 광고 — `AdWhaleMediationInterstitialAd`
///
/// Android 샘플의 `ProgrammaticInterstitialMainActivity` 에 대응한다.
///
/// ## 흐름
/// ```
/// loadAd()  →  interstitial(_:didLoadWith:)  →  show(from:)  →  ...DidShow → ...DidClose
/// ```
/// - `show(from:)` 에 넘기는 ViewController 는 반드시 `view.window != nil` 이어야 한다.
///   화면을 이미 벗어난 VC 를 넘기면 `didFailToShowWithError`(200) 가 온다.
/// - 로드 완료 콜백을 받기 전에 `show()` 하면 역시 200 이다.
final class InterstitialViewController: AdSampleViewController {

    override var defaultPlacementUid: String { SampleConfig.interstitialPlacementUid }

    private var interstitialAd: AdWhaleMediationInterstitialAd?
    private var isLoaded = false
    private var showAutomatically = false

    private let autoShowSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()

        addNote("전면 광고는 인스턴스 1개당 1회 노출이다. 다시 보려면 새로 로드해야 한다.")

        let autoRow = UIStackView(arrangedSubviews: [makeLabel("로드되면 바로 노출"), UIView(), autoShowSwitch])
        autoRow.axis = .horizontal
        autoRow.alignment = .center
        autoShowSwitch.addAction(UIAction { [weak self] _ in
            self?.showAutomatically = self?.autoShowSwitch.isOn ?? false
        }, for: .valueChanged)
        addContent(autoRow)

        addButton("전면 로드 (loadAd)") { [weak self] in self?.loadAd() }
        addButton("전면 노출 (show)") { [weak self] in self?.showAd() }
        addButton("로드 취소 (cancelAd)") { [weak self] in
            self?.interstitialAd?.cancelAd()
            adlog("전면 cancelAd()")
        }
    }

    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        return label
    }

    // MARK: - 연동 코드

    private func loadAd() {
        // 이전 인스턴스는 정리하고 새로 만든다.
        interstitialAd?.destroy()
        isLoaded = false

        let ad = AdWhaleMediationInterstitialAd(placementUid: placementUid)
        ad.delegate = self
        interstitialAd = ad

        adlog("전면 loadAd() — placement=\(placementUid)")
        ad.loadAd()
    }

    private func showAd() {
        guard let ad = interstitialAd, isLoaded else {
            adlog("아직 로드되지 않았습니다. loadAd() 를 먼저 호출하세요.")
            return
        }
        adlog("전면 show(from:)")
        ad.show(from: self)
    }

    deinit {
        interstitialAd?.destroy()
    }
}

// MARK: - AdWhaleMediationInterstitialDelegate

extension InterstitialViewController: AdWhaleMediationInterstitialDelegate {

    func interstitialDidLoad(_ ad: AdWhaleMediationInterstitialAd) {
        isLoaded = true
        adlog("전면 onAdLoaded")
        if showAutomatically {
            ad.show(from: self)
        }
    }

    func interstitial(_ ad: AdWhaleMediationInterstitialAd, didFailToLoadWithError statusCode: Int, message: String) {
        isLoaded = false
        // 300 = 워터폴을 다 돌았는데 채울 광고가 없음 (정상 상황). 자체광고 대체 등을 고려한다.
        // 200 = 연동 오류. 재시도해도 같은 결과이므로 코드를 고쳐야 한다.
        adlog("전면 onAdLoadFailed(\(statusCode)): \(message)")
    }

    func interstitialDidShow(_ ad: AdWhaleMediationInterstitialAd) {
        adlog("전면 onAdShowed")
    }

    func interstitial(_ ad: AdWhaleMediationInterstitialAd, didFailToShowWithError statusCode: Int, message: String) {
        adlog("전면 onAdShowFailed(\(statusCode)): \(message)")
    }

    func interstitialDidClick(_ ad: AdWhaleMediationInterstitialAd) {
        adlog("전면 onAdClicked")
    }

    func interstitialDidClose(_ ad: AdWhaleMediationInterstitialAd) {
        // 한 번 노출된 인스턴스는 재사용하지 않는다.
        isLoaded = false
        adlog("전면 onAdClosed")
    }
}
