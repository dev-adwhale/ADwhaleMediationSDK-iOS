import SwiftUI

/// 화면 하단에 붙는 로그 콘솔.
/// 샘플 확인용이며 SDK 연동과는 무관하다.
struct LogConsoleView: View {
    @ObservedObject private var log = SampleLog.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("콜백 로그")
                    .font(.caption).bold()
                    .foregroundStyle(.secondary)
                Spacer()
                Button("지우기") { log.clear() }
                    .font(.caption)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(Array(log.lines.suffix(120).enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(size: 10, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                    }
                }
                .onChange(of: log.lines.count) { _ in
                    proxy.scrollTo(max(0, min(119, log.lines.count - 1)), anchor: .bottom)
                }
            }
        }
        .padding(10)
        .frame(height: 170)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
    }
}
