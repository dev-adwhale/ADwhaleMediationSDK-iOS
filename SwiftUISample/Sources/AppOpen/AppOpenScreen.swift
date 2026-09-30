import SwiftUI
import AdWhaleSDK

/// 앱오프닝 광고 — `AdWhaleMediationAppOpenAd`
///
/// Android 샘플의 `ProgrammaticAppOpenMainActivity` 에 대응한다.
///
/// ## 실제 앱에서의 쓰임
/// 앱오프닝은 "앱이 백그라운드에서 돌아왔을 때" 띄우는 애드폼이다.
/// 그래서 보통 로드는 미리 해 두고, `willEnterForeground` / `didBecomeActive` 에서 노출한다.
struct AppOpenScreen: View {
    @StateObject private var controller = AppOpenController()
    @State private var placementUid = SampleConfig.appOpenPlacementUid

    var body: some View {
        AdSampleScreen(title: "앱오프닝 광고", placementUid: $placementUid) {
            SampleNote("'앱 복귀 시 자동 노출'을 켠 뒤 로드하고, 홈으로 나갔다가 앱으로 돌아오면 노출된다.")

            Toggle("앱 복귀 시 자동 노출", isOn: $controller.showOnForeground)
                .font(.callout)

            SampleButton("앱오프닝 로드 (loadAd)") { controller.load(placementUid: placementUid) }
            SampleButton("앱오프닝 노출 (show)") { controller.show() }
        }
        .onAppear { controller.isOnScreen = true }
        .onDisappear { controller.isOnScreen = false }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            controller.handleDidBecomeActive()
        }
    }
}

final class AppOpenController: NSObject, ObservableObject, AdWhaleMediationAppOpenAdDelegate {

    @Published var showOnForeground = false
    var isOnScreen = false

    private var ad: AdWhaleMediationAppOpenAd?

    func load(placementUid: String) {
        ad?.destroy()

        let ad = AdWhaleMediationAppOpenAd(placementUid: placementUid)
        ad.delegate = self
        self.ad = ad

        adlog("앱오프닝 loadAd() — placement=\(placementUid)")
        ad.loadAd()
    }

    func show() {
        guard let ad, ad.isAdAvailable else {
            adlog("노출할 앱오프닝 광고가 없습니다. loadAd() 를 먼저 호출하세요.")
            return
        }
        guard let host = TopViewController.find() else {
            adlog("최상단 ViewController 를 찾지 못했습니다.")
            return
        }
        adlog("앱오프닝 show(from:)")
        ad.show(from: host)
    }

    func handleDidBecomeActive() {
        guard showOnForeground, isOnScreen else { return }
        // 활성화 직후에는 화면 계층이 정리되는 중일 수 있어 한 틱 미룬다.
        DispatchQueue.main.async { [weak self] in self?.show() }
    }

    deinit { ad?.destroy() }

    // MARK: - AdWhaleMediationAppOpenAdDelegate

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
        ad.loadAd()
    }
}
