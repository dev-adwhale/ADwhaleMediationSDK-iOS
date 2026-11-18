import SwiftUI
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
struct PreloadBannerScreen: View {
    @State private var placementUid = SampleConfig.bannerPlacementUid
    @State private var size: AdWhaleBannerSize = .banner320x50
    /// 현재 지면에 얹은 로드 요청. nil 이면 지면이 비어 있다.
    @State private var request: PreloadBannerRepresentable.Request?
    /// 값이 바뀔 때마다 배너의 show() 를 한 번 호출한다.
    @State private var showCount = 0

    private let sizes: [AdWhaleBannerSize] = [
        .banner320x50, .banner320x100, .banner300x250, .banner250x250, .adaptiveAnchor,
    ]

    var body: some View {
        AdSampleScreen(title: "배너 — 프리로드", placementUid: $placementUid) {
            SampleNote("'배너 미리 로드'를 누르면 광고를 받아 두기만 하고 화면에는 보이지 않는다. "
                       + "로드가 끝난 뒤 '배너 노출 (show)'를 눌러야 노출되고, 그때부터 자동 갱신된다.")

            Picker("사이즈", selection: $size) {
                ForEach(sizes, id: \.self) { size in
                    Text(Self.label(for: size)).tag(size)
                }
            }
            .pickerStyle(.segmented)

            Group {
                if let request {
                    PreloadBannerRepresentable(request: request, showCount: showCount)
                        .id(request.id)   // id 가 바뀌면 이전 광고는 destroy, 새 광고는 load
                } else {
                    Color.clear
                }
            }
            .frame(height: CGFloat(size.height))
            .frame(maxWidth: .infinity)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            SampleButton("배너 미리 로드 (loadAd)") {
                request = PreloadBannerRepresentable.Request(placementUid: placementUid, size: size,
                                                             initialShowCount: showCount)
            }
            SampleButton("배너 노출 (show)") {
                guard request != nil else {
                    adlog("배너가 없습니다. '배너 미리 로드'를 먼저 누르세요.")
                    return
                }
                showCount += 1
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

/// 프리로드 배너를 SwiftUI 에 얹는 `UIViewRepresentable`.
///
/// 광고 인스턴스는 일반 배너(`BannerAdRepresentable`)와 같이 **이 Representable 이 소유**한다.
/// 노출 시점은 `showCount` 로 전달받아, 값이 바뀔 때 `updateUIView` 에서 `show()` 를 호출한다.
struct PreloadBannerRepresentable: UIViewRepresentable {

    /// 로드 요청 1건. `id` 가 바뀌는 것이 곧 "다시 로드"다.
    struct Request: Identifiable {
        let id = UUID()
        let placementUid: String
        let size: AdWhaleBannerSize
        /// 요청을 만든 시점의 showCount. 이보다 커져야 show() 를 부른다.
        let initialShowCount: Int
    }

    let request: Request
    let showCount: Int

    func makeCoordinator() -> Coordinator { Coordinator(shownCount: request.initialShowCount) }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        // 1. 인스턴스 생성
        let banner = AdWhaleMediationAdBannerView()

        // 2. 지면 등록 / 3. 사이즈 설정 / 4. 델리게이트 등록
        banner.placementUid = request.placementUid
        banner.bannerSize = request.size
        banner.delegate = context.coordinator

        banner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(banner)   // ★ loadAd() 보다 먼저
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        context.coordinator.banner = banner

        // 5. 로드 — 뷰가 window 계층에 붙은 다음 프레임에 호출 (노출은 하지 않는다)
        let request = self.request
        DispatchQueue.main.async {
            // Adaptive 배너는 노출될 컨테이너의 실제 너비를 알려줘야 한다.
            if request.size == .adaptiveAnchor {
                banner.adaptiveAnchorWidth = Int(container.bounds.width)
            }
            adlog("프리로드 배너 loadAd() — placement=\(request.placementUid), size=\(request.size.sizeName) (노출하지 않음)")
            banner.loadAd()
        }
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 6. 노출 — '배너 노출 (show)' 버튼을 누를 때마다 한 번
        let coordinator = context.coordinator
        guard showCount > coordinator.shownCount, let banner = coordinator.banner else { return }
        coordinator.shownCount = showCount
        // updateUIView 는 뷰 갱신 도중이라, 로그(@Published)와 show() 는 다음 프레임에 처리한다.
        DispatchQueue.main.async {
            // 로드 전이면 banner(_:didFailToShowWithError:message:) 로 200 이 온다.
            adlog("프리로드 배너 show()")
            banner.show()
        }
    }

    // 7. 폐기
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.banner?.destroy()
        // dismantleUIView 안에서 @Published 를 건드리면 크래시하므로 로그는 다음 프레임에 남긴다.
        DispatchQueue.main.async { adlog("프리로드 배너 destroy()") }
    }

    final class Coordinator: NSObject, AdWhaleMediationAdBannerViewDelegate {
        var banner: AdWhaleMediationAdBannerView?
        var shownCount: Int

        init(shownCount: Int) {
            self.shownCount = shownCount
        }

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
}
