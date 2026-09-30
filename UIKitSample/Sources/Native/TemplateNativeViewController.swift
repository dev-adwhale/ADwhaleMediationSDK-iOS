import UIKit
import AdWhaleSDK

/// 네이티브 — 템플릿 바인딩 (`loadAd(template:)`)
///
/// Android 샘플의 `ProgrammaticTemplateBindingNativeMainActivity` 에 대응한다.
///
/// SDK 가 제공하는 고정 템플릿에 소재를 채워 그려 준다. 앱은 뷰를 만들 필요가 없고,
/// 노출할 영역의 크기만 잡아 주면 된다.
///
/// | 템플릿 | 권장 높이 |
/// |---|---|
/// | `.small` | 100 |
/// | `.medium` | 380 |
/// | `.fullscreen` | 540 |
final class TemplateNativeViewController: NativeAdSampleViewController {

    private let templates: [(String, AdWhaleNativeTemplate)] = [
        ("Small", .small),
        ("Medium", .medium),
        ("Fullscreen", .fullscreen),
    ]
    private var selectedTemplate: AdWhaleNativeTemplate = .medium
    private let templateControl = UISegmentedControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        addNote("템플릿을 고르고 '네이티브 로드'를 누른다. 소재는 SDK 가 템플릿에 맞춰 그린다.")

        for (index, item) in templates.enumerated() {
            templateControl.insertSegment(withTitle: item.0, at: index, animated: false)
        }
        templateControl.selectedSegmentIndex = 1
        templateControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.selectedTemplate = self.templates[self.templateControl.selectedSegmentIndex].1
            self.setNativeHeight(Self.height(for: self.selectedTemplate))
        }, for: .valueChanged)

        addContent(templateControl)
        installNativeContainer(height: Self.height(for: selectedTemplate))

        addButton("네이티브 로드") { [weak self] in self?.loadNative() }
        addButton("네이티브 제거 (destroy)") { [weak self] in self?.destroyNativeAdView() }
    }

    private func loadNative() {
        let native = attachNativeAdView()
        adlog("네이티브 loadAd(template: \(selectedTemplate.templateName)) — placement=\(placementUid)")
        native.loadAd(template: selectedTemplate)
    }

    private static func height(for template: AdWhaleNativeTemplate) -> CGFloat {
        switch template {
        case .small:      return 100
        case .medium:     return 380
        case .fullscreen: return 540
        @unknown default: return 380
        }
    }
}
