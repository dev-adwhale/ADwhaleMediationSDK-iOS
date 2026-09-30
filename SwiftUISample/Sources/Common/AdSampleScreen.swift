import SwiftUI

/// 애드폼 화면들의 공통 뼈대.
///
/// - 위쪽: 지면 UID 입력 필드
/// - 가운데: 각 화면이 채우는 컨텐츠
/// - 아래쪽: 콜백 로그 콘솔
///
/// SDK 사용법과는 무관한 샘플 UI 코드다.
struct AdSampleScreen<Content: View>: View {
    let title: String
    /// 지면 UID 바인딩. 지면을 쓰지 않는 화면은 `nil` 을 넘긴다.
    let placementUid: Binding<String>?
    let content: () -> Content

    init(title: String,
         placementUid: Binding<String>? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.placementUid = placementUid
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let placementUid {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("지면(Placement) UID")
                                .font(.caption).bold()
                                .foregroundStyle(.secondary)
                            TextField("placement uid", text: placementUid)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12, design: .monospaced))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                    }
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            LogConsoleView()
                .padding(.bottom, 8)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 샘플 화면에서 쓰는 보조 문구.
struct SampleNote: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 샘플 화면에서 쓰는 기본 버튼.
struct SampleButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}
