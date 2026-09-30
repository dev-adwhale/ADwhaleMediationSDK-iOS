import SwiftUI
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
struct NormalBannerScreen: View {
    @State private var placementUid = SampleConfig.bannerPlacementUid
    @State private var size: AdWhaleBannerSize = .banner320x50
    /// 현재 지면에 얹은 로드 요청. nil 이면 지면이 비어 있다.
    @State private var request: BannerAdRepresentable.Request?

    private let sizes: [AdWhaleBannerSize] = [
        .banner320x50, .banner320x100, .banner300x250, .banner250x250, .adaptiveAnchor,
    ]

    var body: some View {
        AdSampleScreen(title: "배너 — 일반", placementUid: $placementUid) {
            SampleNote("사이즈를 고르고 '배너 로드'를 누르면 해당 사이즈로 다시 로드한다. "
                       + "배너가 로드에 성공하는 순간 자동으로 노출된다.")

            Picker("사이즈", selection: $size) {
                ForEach(sizes, id: \.self) { size in
                    Text(Self.label(for: size)).tag(size)
                }
            }
            .pickerStyle(.segmented)

            BannerAdSlot(request: request, height: CGFloat(size.height))

            SampleButton("배너 로드") {
                request = BannerAdRepresentable.Request(placementUid: placementUid, size: size)
            }
            SampleButton("배너 제거 (destroy)") { request = nil }
        }
    }

    private static func label(for size: AdWhaleBannerSize) -> String {
        switch size {
        case .banner320x50:   return "320x50"
        case .banner320x100:  return "320x100"
        case .banner300x250:  return "300x250"
        case .banner250x250:  return "250x250"
        case .adaptiveAnchor: return "Adaptive"
        @unknown default:     return size.sizeName
        }
    }
}
