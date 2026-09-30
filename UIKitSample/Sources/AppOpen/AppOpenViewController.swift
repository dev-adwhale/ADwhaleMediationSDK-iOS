import UIKit
import AdWhaleSDK

/// 앱오프닝 광고 — `AdWhaleMediationAppOpenAd`
///
/// Android 샘플의 `ProgrammaticAppOpenMainActivity` 에 대응한다.
///
/// ## 실제 앱에서의 쓰임
/// 앱오프닝은 "앱이 백그라운드에서 돌아왔을 때" 띄우는 애드폼이다.
/// 그래서 보통 로드는 미리 해 두고, `didBecomeActiveNotification` 에서 노출한다.
/// 이 화면은 그 패턴을 스위치로 켜고 끌 수 있게 해 두었다.
///
/// ## 주의
/// - 노출 직후 다음 회차를 위해 다시 로드해 두는 것이 일반적이다.
/// - `show(from:)` 의 VC 는 window 에 붙어 있어야 한다. 앱이 막 활성화되는 타이밍에는
///   최상단 VC 가 바뀌는 중일 수 있으므로 한 틱 미뤄서 호출한다.
final class AppOpenViewController: AdSampleViewController {

    override var defaultPlacementUid: String { SampleConfig.appOpenPlacementUid }

    private var appOpenAd: AdWhaleMediationAppOpenAd?
    private var showOnForeground = false
    private let foregroundSwitch = UISwitch()
    private var observer: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        addNote("'앱 복귀 시 자동 노출'을 켠 뒤 로드하고, 홈으로 나갔다가 앱으로 돌아오면 노출된다.")

        let row = UIStackView(arrangedSubviews: [makeLabel("앱 복귀 시 자동 노출"), UIView(), foregroundSwitch])
        row.axis = .horizontal
        row.alignment = .center
        foregroundSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.showOnForeground = self.foregroundSwitch.isOn
            adlog("앱 복귀 자동 노출: \(self.showOnForeground)")
        }, for: .valueChanged)
        addContent(row)

        addButton("앱오프닝 로드 (loadAd)") { [weak self] in self?.loadAd() }
        addButton("앱오프닝 노출 (show)") { [weak self] in self?.showAd() }

        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDidBecomeActive()
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
        appOpenAd?.destroy()

        let ad = AdWhaleMediationAppOpenAd(placementUid: placementUid)
        ad.delegate = self
        appOpenAd = ad

        adlog("앱오프닝 loadAd() — placement=\(placementUid)")
        ad.loadAd()
    }

    private func showAd() {
        guard let ad = appOpenAd, ad.isAdAvailable else {
            adlog("노출할 앱오프닝 광고가 없습니다. loadAd() 를 먼저 호출하세요.")
            return
        }
        adlog("앱오프닝 show(from:)")
        ad.show(from: self)
    }

    private func handleDidBecomeActive() {
        guard showOnForeground, view.window != nil else { return }
        // 활성화 직후에는 화면 계층이 정리되는 중일 수 있어 한 틱 미룬다.
        DispatchQueue.main.async { [weak self] in self?.showAd() }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        appOpenAd?.destroy()
    }
}

// MARK: - AdWhaleMediationAppOpenAdDelegate

extension AppOpenViewController: AdWhaleMediationAppOpenAdDelegate {

    func appOpenAdDidLoad(_ ad: AdWhaleMediationAppOpenAd) {
        adlog("앱오프닝 onAdLoaded")
    }

    func appOpenAd(_ ad: AdWhaleMediationAppOpenAd, didFailToLoadWithError statusCode: Int, message: String) {
        adlog("앱오프닝 onAdLoadFailed(\(statusCode)): \(message)")
    }

    func appOpenAdDidShow(_ ad: AdWhaleMediationAppOpenAd) {
        adlog("앱오프닝 onAdShowed")
    }

    func appOpenAd(_ ad: AdWhaleMediationAppOpenAd, didFailToShowWithError statusCode: Int, message: String) {
        adlog("앱오프닝 onAdShowFailed(\(statusCode)): \(message)")
    }

    func appOpenAdDidClick(_ ad: AdWhaleMediationAppOpenAd) {
        adlog("앱오프닝 onAdClicked")
    }

    func appOpenAdDidDismiss(_ ad: AdWhaleMediationAppOpenAd) {
        adlog("앱오프닝 onAdDismissed — 다음 회차를 위해 다시 로드한다")
        // 실제 앱에서도 닫힌 직후 미리 받아 두는 것이 일반적이다.
        ad.loadAd()
    }
}
