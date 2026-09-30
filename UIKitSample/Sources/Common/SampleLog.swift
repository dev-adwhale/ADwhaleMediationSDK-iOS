import Foundation

/// 화면에 그대로 찍히는 간단한 로그 버퍼.
///
/// 광고 SDK 연동에서 가장 자주 하는 실수는 "delegate 를 설정하지 않아 실패 콜백이
/// 아무 데도 전달되지 않는 것"이다. 그래서 이 샘플은 모든 콜백을 화면 하단
/// 로그 콘솔에 남긴다. 실제 앱에서는 필요 없는 구조다.
final class SampleLog {
    static let shared = SampleLog()

    /// 새 로그 줄이 추가되면 호출된다.
    var onAppend: ((String) -> Void)?

    private(set) var lines: [String] = []
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private init() {}

    func append(_ message: String) {
        let line = "[\(formatter.string(from: Date()))] \(message)"
        // 콜백은 어느 스레드에서 올지 보장되지 않는다. UI 갱신은 항상 메인에서.
        if Thread.isMainThread {
            store(line)
        } else {
            DispatchQueue.main.async { self.store(line) }
        }
    }

    func clear() {
        lines.removeAll()
        onAppend?("")
    }

    private func store(_ line: String) {
        print(line)
        lines.append(line)
        if lines.count > 300 { lines.removeFirst(lines.count - 300) }
        onAppend?(line)
    }
}

/// 짧게 쓰기 위한 전역 함수.
func adlog(_ message: String) {
    SampleLog.shared.append(message)
}
