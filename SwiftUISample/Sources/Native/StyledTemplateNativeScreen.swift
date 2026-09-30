import SwiftUI
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
struct StyledTemplateNativeScreen: View {
    @State private var placementUid = SampleConfig.nativePlacementUid
    @State private var theme: NativeStyleTheme = .dark
    /// 현재 지면에 얹은 로드 요청. nil 이면 지면이 비어 있다.
    @State private var request: NativeAdRepresentable.Request?

    var body: some View {
        AdSampleScreen(title: "네이티브 — 템플릿 + 스타일", placementUid: $placementUid) {
            SampleNote("templateStyle 은 loadAd 보다 먼저 지정해야 반영된다.")

            Picker("테마", selection: $theme) {
                ForEach(NativeStyleTheme.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            NativeAdSlot(request: request, height: NativeTemplateHeight.of(.medium))

            SampleButton("스타일 적용해서 로드") {
                request = .template(.medium, placementUid: placementUid, style: theme.style)
            }
            SampleButton("네이티브 제거 (destroy)") { request = nil }
        }
    }
}

enum NativeStyleTheme: CaseIterable {
    case dark, brand

    var title: String {
        switch self {
        case .dark:  return "다크"
        case .brand: return "브랜드"
        }
    }

    var style: AdWhaleMediationNativeTemplateStyle {
        switch self {
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
