import UIKit
import AdWhaleSDK

/// 네이티브 — 템플릿 + 스타일 (`templateStyle`)
///
/// Android 샘플의 `StyledTemplateBindingNativeMainActivity` 에 대응한다.
///
/// 템플릿 구조는 그대로 두고 색·폰트만 앱 테마에 맞춘다.
/// `AdWhaleMediationNativeTemplateStyle.Builder` 로 만들어 `templateStyle` 에 대입하고
/// **`loadAd` 보다 먼저** 지정해야 한다.
///
/// | 스타일 항목 | 대상 |
/// |---|---|
/// | `mainBackground` | 템플릿 전체 배경 |
/// | `primaryText` | 제목(headline) |
/// | `secondaryText` | 본문(body) |
/// | `tertiaryText` | 광고주 / 부가 정보 |
/// | `callToAction` | CTA 버튼 |
final class StyledTemplateNativeViewController: NativeAdSampleViewController {

    private enum Theme: Int, CaseIterable {
        case dark, brand

        var title: String {
            switch self {
            case .dark:  return "다크"
            case .brand: return "브랜드"
            }
        }
    }

    private var theme: Theme = .dark
    private let themeControl = UISegmentedControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        addNote("templateStyle 은 loadAd 보다 먼저 지정해야 반영된다.")

        for theme in Theme.allCases {
            themeControl.insertSegment(withTitle: theme.title, at: theme.rawValue, animated: false)
        }
        themeControl.selectedSegmentIndex = 0
        themeControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.theme = Theme(rawValue: self.themeControl.selectedSegmentIndex) ?? .dark
        }, for: .valueChanged)
        addContent(themeControl)

        installNativeContainer(height: 380)

        addButton("스타일 적용해서 로드") { [weak self] in self?.loadNative() }
        addButton("네이티브 제거 (destroy)") { [weak self] in self?.destroyNativeAdView() }
    }

    private func loadNative() {
        let native = attachNativeAdView()

        // ── 스타일 지정 (loadAd 전) ──
        native.templateStyle = makeStyle(for: theme)

        adlog("네이티브(스타일) loadAd(template: MEDIUM) — theme=\(theme.title)")
        native.loadAd(template: .medium)
    }

    private func makeStyle(for theme: Theme) -> AdWhaleMediationNativeTemplateStyle {
        switch theme {
        case .dark:
            return AdWhaleMediationNativeTemplateStyle.Builder()
                .setMainBackgroundColor(UIColor(white: 0.11, alpha: 1))
                .setPrimaryTextColor(.white)
                .setPrimaryTextFont(.systemFont(ofSize: 16, weight: .bold))
                .setPrimaryTextBackgroundColor(.clear)
                .setSecondaryTextColor(UIColor(white: 0.78, alpha: 1))
                .setSecondaryTextFont(.systemFont(ofSize: 13))
                .setSecondaryTextBackgroundColor(.clear)
                .setTertiaryTextColor(UIColor(white: 0.6, alpha: 1))
                .setTertiaryTextFont(.systemFont(ofSize: 11))
                .setTertiaryTextBackgroundColor(.clear)
                .setCallToActionTextColor(.white)
                .setCallToActionTextFont(.systemFont(ofSize: 14, weight: .semibold))
                .setCallToActionBackgroundColor(UIColor(red: 0.16, green: 0.44, blue: 0.94, alpha: 1))
                .build()

        case .brand:
            return AdWhaleMediationNativeTemplateStyle.Builder()
                .setMainBackgroundColor(UIColor(red: 0.98, green: 0.96, blue: 0.91, alpha: 1))
                .setPrimaryTextColor(UIColor(red: 0.16, green: 0.13, blue: 0.09, alpha: 1))
                .setPrimaryTextFont(.systemFont(ofSize: 16, weight: .heavy))
                .setPrimaryTextBackgroundColor(.clear)
                .setSecondaryTextColor(UIColor(red: 0.36, green: 0.31, blue: 0.24, alpha: 1))
                .setSecondaryTextFont(.systemFont(ofSize: 13))
                .setSecondaryTextBackgroundColor(.clear)
                .setTertiaryTextColor(UIColor(red: 0.55, green: 0.5, blue: 0.42, alpha: 1))
                .setTertiaryTextFont(.systemFont(ofSize: 11))
                .setTertiaryTextBackgroundColor(.clear)
                .setCallToActionTextColor(UIColor(red: 0.15, green: 0.1, blue: 0.03, alpha: 1))
                .setCallToActionTextFont(.systemFont(ofSize: 14, weight: .bold))
                .setCallToActionBackgroundColor(UIColor(red: 1.0, green: 0.78, blue: 0.24, alpha: 1))
                .build()
        }
    }
}
