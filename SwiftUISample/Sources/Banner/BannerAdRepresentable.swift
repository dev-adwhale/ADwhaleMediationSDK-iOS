import SwiftUI
import AdWhaleSDK

/// 배너 광고를 SwiftUI 에 얹는 `UIViewRepresentable`.
///
/// ## 소유 구조
/// 광고 인스턴스는 **이 Representable 이 소유**한다.
/// `makeUIView` 에서 만들고, SwiftUI 가 뷰를 걷어낼 때 `dismantleUIView` 에서 `destroy()` 한다.
/// 화면(Screen)이 광고를 바깥에서 붙잡고 있으면 SwiftUI 가 뷰를 걷어내도 인스턴스가 남아
/// 해제되지 않는다.
///
/// ## 다시 로드하려면
/// `request` 를 새로 만들고 `.id(request.id)` 를 붙인다.
/// SwiftUI 가 이전 Representable 을 걷어내면서(=`destroy()`) 새 것을 만든다(=새 로드).
struct BannerAdRepresentable: UIViewRepresentable {

    /// 로드 요청 1건. `id` 가 바뀌는 것이 곧 "다시 로드"다.
    struct Request: Identifiable {
        let id = UUID()
        let placementUid: String
        let size: AdWhaleBannerSize
    }

    let request: Request

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        // 1. 인스턴스 생성
        let banner = AdWhaleMediationAdView()

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

        // 5. 로드 — 뷰가 window 계층에 붙은 다음 프레임에 호출
        let request = self.request
        DispatchQueue.main.async {
            // Adaptive 배너는 노출될 컨테이너의 실제 너비를 알려줘야 한다.
            // (0 이거나 설정하지 않으면 디바이스 전체 너비를 쓴다)
            if request.size == .adaptiveAnchor {
                banner.adaptiveAnchorWidth = Int(container.bounds.width)
            }
            adlog("배너 loadAd() — placement=\(request.placementUid), size=\(request.size.sizeName)")
            banner.loadAd()
        }
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) { }

    // 6. 폐기
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.banner?.destroy()
        // dismantleUIView 는 SwiftUI 가 뷰 그래프를 무효화하는 도중에 호출된다.
        // 그 안에서 @Published 를 건드리면 "view update 중 publish" 가 되어 크래시한다.
        // (샘플 로그 콘솔이 ObservableObject 라서 생기는 제약이다)
        DispatchQueue.main.async { adlog("배너 destroy()") }
    }

    final class Coordinator: NSObject, AdWhaleMediationAdViewDelegate {
        var banner: AdWhaleMediationAdView?

        func adViewDidReceiveAd(_ adView: AdWhaleMediationAdView) {
            adlog("배너 onAdLoaded")
        }

        func adView(_ adView: AdWhaleMediationAdView, didFailToLoadWithError statusCode: Int, message: String) {
            // 300 + "Previous ad is still showing." → 갱신 실패지만 기존 광고는 그대로 노출 중이다.
            //   이 경우 자체광고로 대체하면 안 된다.
            adlog("배너 onAdLoadFailed(\(statusCode)): \(message)")
        }

        func adViewDidClick(_ adView: AdWhaleMediationAdView) {
            adlog("배너 onAdClicked")
        }
    }
}

/// 배너 지면 자리. 로드 전에는 빈 영역, 로드 후에는 광고가 들어간다.
struct BannerAdSlot: View {
    let request: BannerAdRepresentable.Request?
    let height: CGFloat

    var body: some View {
        Group {
            if let request {
                BannerAdRepresentable(request: request)
                    .id(request.id)   // id 가 바뀌면 이전 광고는 destroy, 새 광고는 load
            } else {
                Color.clear
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
