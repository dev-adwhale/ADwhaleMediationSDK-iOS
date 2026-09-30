import UIKit

/// 화면 하단에 붙는 로그 콘솔.
/// 샘플 확인용이며 SDK 연동과는 무관하다.
final class LogConsoleView: UIView {

    private let textView = UITextView()
    private let clearButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8

        let title = UILabel()
        title.text = "콜백 로그"
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        title.textColor = .secondaryLabel

        clearButton.setTitle("지우기", for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 12)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        textView.backgroundColor = .clear
        textView.textColor = .label

        let header = UIStackView(arrangedSubviews: [title, UIView(), clearButton])
        header.axis = .horizontal
        header.alignment = .center

        let stack = UIStackView(arrangedSubviews: [header, textView])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])

        render()
    }

    /// 화면에 올라온 콘솔이 로그 구독자가 된다.
    /// (화면을 push/pop 해도 항상 현재 보이는 콘솔이 갱신되도록)
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        SampleLog.shared.onAppend = { [weak self] _ in self?.render() }
        render()
    }

    private func render() {
        textView.text = SampleLog.shared.lines.suffix(120).joined(separator: "\n")
        let end = NSRange(location: max(0, (textView.text as NSString).length - 1), length: 1)
        textView.scrollRangeToVisible(end)
    }

    @objc private func clearTapped() {
        SampleLog.shared.clear()
        render()
    }
}
