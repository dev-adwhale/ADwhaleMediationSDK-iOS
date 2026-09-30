import SwiftUI
import AdWhaleSDK

/// 네이티브 — 커스텀 바인딩 (`loadAd(binder:)`)
///
/// Android 샘플의 `ProgrammaticCustomBindingNativeMainActivity` 에 대응한다.
///
/// ## 템플릿 방식과의 차이
/// 앱이 뷰를 직접 만들고, 그 뷰들을 `AdWhaleMediationNativeAdBindingHelper` 에 등록한다.
/// SDK 는 각 뷰에 광고 에셋(제목 / 본문 / 아이콘 / 미디어 / CTA)을 채우고
/// 클릭 처리와 노출 측정을 붙여서 `AdWhaleMediationNativeAdView` 안에 배치한다.
///
/// ## 중요
/// - 바인더에 넘기는 뷰는 **화면 계층에 직접 붙이지 않는다.** SDK 가 배치한다.
/// - 바인더에 넘기는 것은 SwiftUI 뷰가 아니라 `UILabel` / `UIButton` 같은 **UIKit 뷰**다.
///   SwiftUI 프로젝트라도 이 부분만은 UIKit 뷰를 만들어야 한다.
/// - 각 뷰의 폰트·색·모서리 등 "생김새"는 앱이 소유한다. 여기서 지정한 그대로 나온다.
struct CustomBindingNativeScreen: View {
    @StateObject private var binderViews = CustomBinderViews()
    @State private var placementUid = SampleConfig.nativePlacementUid
    /// 현재 지면에 얹은 로드 요청. nil 이면 지면이 비어 있다.
    @State private var request: NativeAdRepresentable.Request?

    var body: some View {
        AdSampleScreen(title: "네이티브 — 커스텀 바인딩", placementUid: $placementUid) {
            SampleNote("아이콘 / 제목 / 본문 / 미디어 / CTA 뷰를 앱이 만들어 바인더에 넘긴다. "
                       + "SwiftUI 앱이라도 이 뷰들은 UIKit 뷰여야 한다.")

            NativeAdSlot(request: request, height: 380)

            SampleButton("커스텀 바인딩으로 로드") {
                request = .binder(binderViews.makeBinder(), placementUid: placementUid)
            }
            SampleButton("네이티브 제거 (destroy)") { request = nil }
        }
    }
}

/// 커스텀 바인딩에 넘길 UIKit 뷰 모음.
///
/// 뷰 인스턴스가 매 렌더마다 새로 만들어지지 않도록 `@StateObject` 로 붙잡아 둔다.
final class CustomBinderViews: ObservableObject {

    let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.backgroundColor = .quaternarySystemFill
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.numberOfLines = 2
        return label
    }()

    let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        return label
    }()

    let mediaContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .quaternarySystemFill
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        // 높이를 직접 지정하지 않으면 SDK 가 180 으로 잡아 준다.
        view.heightAnchor.constraint(equalToConstant: 170).isActive = true
        return view
    }()

    let ctaButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        button.configuration = config
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        return button
    }()

    func makeBinder() -> AdWhaleMediationNativeAdBindingHelper {
        AdWhaleMediationNativeAdBindingHelper.Builder()
            .setIconView(iconView)
            .setTitleView(titleLabel)
            .setBodyView(bodyLabel)
            .setMediaView(mediaContainer)
            .setCallToActionView(ctaButton)
            .build()
    }
}
