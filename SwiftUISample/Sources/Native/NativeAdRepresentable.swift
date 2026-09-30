import SwiftUI
import AdWhaleSDK

/// 네이티브 광고를 SwiftUI 에 얹는 `UIViewRepresentable`.
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
struct NativeAdRepresentable: UIViewRepresentable {

    /// 로드 요청 1건. `id` 가 바뀌는 것이 곧 "다시 로드"다.
    struct Request: Identifiable {
        let id = UUID()
        let placementUid: String
        let mode: Mode

        enum Mode {
            case template(AdWhaleNativeTemplate, AdWhaleMediationNativeTemplateStyle?)
            case binder(AdWhaleMediationNativeAdBindingHelper)
        }

        static func template(_ template: AdWhaleNativeTemplate,
                             placementUid: String,
                             style: AdWhaleMediationNativeTemplateStyle? = nil) -> Request {
            Request(placementUid: placementUid, mode: .template(template, style))
        }

        static func binder(_ binder: AdWhaleMediationNativeAdBindingHelper,
                           placementUid: String) -> Request {
            Request(placementUid: placementUid, mode: .binder(binder))
        }
    }

    let request: Request

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        // 1. 인스턴스 생성
        let native = AdWhaleMediationNativeAdView()

        // 2. 지면 등록 / 3. 델리게이트 등록
        native.placementUid = request.placementUid
        native.delegate = context.coordinator

        // 4. (선택) 템플릿 스타일 — loadAd 보다 먼저 지정해야 반영된다.
        if case let .template(_, style) = request.mode {
            native.templateStyle = style
        }

        native.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(native)   // ★ loadAd() 보다 먼저
        NSLayoutConstraint.activate([
            native.topAnchor.constraint(equalTo: container.topAnchor),
            native.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            native.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            native.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        context.coordinator.native = native

        // 5. 로드 — 뷰가 window 계층에 붙은 다음 프레임에 호출
        let mode = request.mode
        let placementUid = request.placementUid
        DispatchQueue.main.async {
            switch mode {
            case let .template(template, _):
                adlog("네이티브 loadAd(template: \(template.templateName)) — placement=\(placementUid)")
                native.loadAd(template: template)
            case let .binder(binder):
                adlog("네이티브 loadAd(binder:) — placement=\(placementUid)")
                native.loadAd(binder: binder)
            }
        }
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) { }

    // 7. 폐기
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.native?.destroy()
        // dismantleUIView 는 SwiftUI 가 뷰 그래프를 무효화하는 도중에 호출된다.
        // 그 안에서 @Published 를 건드리면 "view update 중 publish" 가 되어 크래시한다.
        // (샘플 로그 콘솔이 ObservableObject 라서 생기는 제약이다)
        DispatchQueue.main.async { adlog("네이티브 destroy()") }
    }

    final class Coordinator: NSObject, AdWhaleMediationNativeAdDelegate {
        var native: AdWhaleMediationNativeAdView?

        func nativeAdDidLoad(_ adView: AdWhaleMediationNativeAdView) {
            adlog("네이티브 onAdLoaded")
            // 네이티브는 배너와 달리 최초 노출을 매체사가 직접 붙인다.
            // 한 번 show() 된 뒤의 자동 갱신은 SDK 가 알아서 교체 노출한다.
            adView.show()   // 6. 노출 (로드 완료 후)
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
}

/// 네이티브 지면 자리. 로드 전에는 빈 영역, 로드 후에는 광고가 들어간다.
///
/// 배경·모서리 처리를 한 곳에 모아 세 화면이 같은 모양을 쓰게 한다.
struct NativeAdSlot: View {
    let request: NativeAdRepresentable.Request?
    let height: CGFloat

    var body: some View {
        Group {
            if let request {
                NativeAdRepresentable(request: request)
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

/// 템플릿별 권장 표시 높이. (SDK 어댑터가 그리는 레이아웃 기준)
enum NativeTemplateHeight {
    static func of(_ template: AdWhaleNativeTemplate) -> CGFloat {
        switch template {
        case .small:      return 100
        case .medium:     return 380
        case .fullscreen: return 540
        @unknown default: return 380
        }
    }
}
