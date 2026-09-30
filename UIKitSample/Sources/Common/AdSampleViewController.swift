import UIKit

/// 애드폼 화면들의 공통 뼈대.
///
/// - 위쪽: 지면 UID 입력 필드 (Android 샘플의 `etPlacementUid` 대응)
/// - 가운데: 각 화면이 채우는 컨텐츠 영역
/// - 아래쪽: 콜백 로그 콘솔
///
/// SDK 사용법과는 무관한 샘플 UI 코드다. 실제 연동 코드는 각 하위 클래스를 볼 것.
class AdSampleViewController: UIViewController {

    /// 지면 UID 입력 필드. 화면 진입 시 `defaultPlacementUid` 로 채워진다.
    let placementUidField = UITextField()

    /// 각 화면이 자유롭게 쓰는 세로 스택.
    let contentStack = UIStackView()

    private let logConsole = LogConsoleView()
    private let scrollView = UIScrollView()
    /// 지면 UID 라벨 + 입력 필드를 묶은 행. 지면이 필요 없는 화면은 통째로 감춘다.
    private let placementRow = UIStackView()

    /// 하위 클래스가 지정하는 기본 지면 UID.
    var defaultPlacementUid: String { "" }

    /// 현재 입력된 지면 UID (비어 있으면 기본값).
    var placementUid: String {
        let text = placementUidField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? defaultPlacementUid : text
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildLayout()
        placementUidField.text = defaultPlacementUid
    }

    // MARK: - 하위 클래스용 헬퍼

    /// 컨텐츠 영역에 버튼을 추가한다.
    @discardableResult
    func addButton(_ title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.bordered()
        config.title = title
        config.cornerStyle = .medium
        button.configuration = config
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        contentStack.addArrangedSubview(button)
        return button
    }

    /// 컨텐츠 영역에 설명 문구를 추가한다.
    func addNote(_ text: String) {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        contentStack.addArrangedSubview(label)
    }

    /// 컨텐츠 영역에 임의의 뷰를 추가한다.
    func addContent(_ subview: UIView) {
        contentStack.addArrangedSubview(subview)
    }

    // MARK: - 레이아웃

    private func buildLayout() {
        let uidLabel = UILabel()
        uidLabel.text = "지면(Placement) UID"
        uidLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        uidLabel.textColor = .secondaryLabel

        placementUidField.borderStyle = .roundedRect
        placementUidField.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        placementUidField.autocapitalizationType = .none
        placementUidField.autocorrectionType = .no
        placementUidField.clearButtonMode = .whileEditing
        placementUidField.returnKeyType = .done
        placementUidField.addAction(UIAction { [weak self] _ in
            self?.placementUidField.resignFirstResponder()
        }, for: .editingDidEndOnExit)

        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.alignment = .fill

        placementRow.axis = .vertical
        placementRow.spacing = 4
        placementRow.addArrangedSubview(uidLabel)
        placementRow.addArrangedSubview(placementUidField)

        let inner = UIStackView(arrangedSubviews: [placementRow, contentStack])
        inner.axis = .vertical
        inner.spacing = 12
        inner.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.addSubview(inner)

        logConsole.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        view.addSubview(logConsole)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),

            inner.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 14),
            inner.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -14),
            inner.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),

            logConsole.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 10),
            logConsole.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            logConsole.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),
            logConsole.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8),
            logConsole.heightAnchor.constraint(equalToConstant: 170),
        ])
    }
}
