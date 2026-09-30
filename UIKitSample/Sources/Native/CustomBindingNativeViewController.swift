import UIKit
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
/// - 각 뷰의 폰트·색·모서리 등 "생김새"는 앱이 소유한다. 여기서 지정한 그대로 나온다.
/// - 넘기지 않은 항목(예: `mediaView` 생략)은 그냥 표시되지 않는다.
final class CustomBindingNativeViewController: NativeAdSampleViewController {

    // 앱이 소유하는 뷰들. 생김새는 전부 여기서 정한다.
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.backgroundColor = .quaternarySystemFill
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.numberOfLines = 2
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        return label
    }()

    private let mediaContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .quaternarySystemFill
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        // 높이를 직접 지정하지 않으면 SDK 가 180 으로 잡아 준다.
        view.heightAnchor.constraint(equalToConstant: 170).isActive = true
        return view
    }()

    private let ctaButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        button.configuration = config
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        addNote("아이콘 / 제목 / 본문 / 미디어 / CTA 뷰를 앱이 만들어 바인더에 넘긴다. "
                + "SDK 가 에셋을 채우고 클릭·노출 측정을 붙인다.")

        installNativeContainer(height: 380)

        addButton("커스텀 바인딩으로 로드") { [weak self] in self?.loadNative() }
        addButton("네이티브 제거 (destroy)") { [weak self] in self?.destroyNativeAdView() }
    }

    private func loadNative() {
        let native = attachNativeAdView()

        // ── 바인더 구성 ──
        let binder = AdWhaleMediationNativeAdBindingHelper.Builder()
            .setIconView(iconView)
            .setTitleView(titleLabel)
            .setBodyView(bodyLabel)
            .setMediaView(mediaContainer)
            .setCallToActionView(ctaButton)
            .build()

        adlog("네이티브 loadAd(binder:) — placement=\(placementUid)")
        native.loadAd(binder: binder)
    }
}
