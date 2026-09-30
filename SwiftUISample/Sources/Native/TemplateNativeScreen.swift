import SwiftUI
import AdWhaleSDK

/// 네이티브 — 템플릿 바인딩 (`loadAd(template:)`)
///
/// Android 샘플의 `ProgrammaticTemplateBindingNativeMainActivity` 에 대응한다.
///
/// SDK 가 제공하는 고정 템플릿에 소재를 채워 그려 준다. 앱은 뷰를 만들 필요가 없고,
/// 노출할 영역의 크기만 잡아 주면 된다.
struct TemplateNativeScreen: View {
    @State private var placementUid = SampleConfig.nativePlacementUid
    @State private var template: AdWhaleNativeTemplate = .medium
    /// 현재 지면에 얹은 로드 요청. nil 이면 지면이 비어 있다.
    @State private var request: NativeAdRepresentable.Request?

    private let templates: [AdWhaleNativeTemplate] = [.small, .medium, .fullscreen]

    var body: some View {
        AdSampleScreen(title: "네이티브 — 템플릿 바인딩", placementUid: $placementUid) {
            SampleNote("템플릿을 고르고 '네이티브 로드'를 누른다. 소재는 SDK 가 템플릿에 맞춰 그린다.")

            Picker("템플릿", selection: $template) {
                ForEach(templates, id: \.self) { template in
                    Text(template.templateName.capitalized).tag(template)
                }
            }
            .pickerStyle(.segmented)

            NativeAdSlot(request: request, height: NativeTemplateHeight.of(template))

            SampleButton("네이티브 로드") {
                request = .template(template, placementUid: placementUid)
            }
            SampleButton("네이티브 제거 (destroy)") { request = nil }
        }
    }
}
