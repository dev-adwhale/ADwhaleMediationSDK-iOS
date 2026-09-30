import UIKit
import AdWhaleSDK

/// 샘플 메인 화면.
///
/// Android 샘플의 `activity_sample_main.xml` + `SampleMainActivity` 에 대응한다.
///
/// | Android 버튼 | iOS 화면 |
/// |---|---|
/// | `etMediaUid` (Media Uid 입력) | 상단 Publisher UID 입력 + "이 UID 로 다시 초기화" |
/// | `programmatic banner` | 배너 — 일반 (`AdWhaleMediationAdView`) |
/// | `xml banner` | 배너 — XIB (Interface Builder) |
/// | `앱 전환 광고 테스트` | 팝업 — 전환 |
/// | `interstitial` | 전면 광고 |
/// | `Reward Ad` | 리워드 광고 |
/// | `App Open Ad` | 앱오프닝 광고 |
/// | `Native Ad (for Custom Binding)` | 네이티브 — 커스텀 바인딩 |
/// | `Native Ad (for Template Binding)` | 네이티브 — 템플릿 바인딩 |
/// | `Native Template Binding Ad (with Style)` | 네이티브 — 템플릿 + 스타일 |
/// | Back 키 종료 팝업 | 팝업 — 종료 |
final class SampleMainViewController: UIViewController {

    private struct Row {
        let title: String
        let make: () -> UIViewController
    }

    private struct Section {
        let header: String
        let rows: [Row]
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let statusLabel = UILabel()
    private let statusDot = UIView()
    private let publisherUidField = UITextField()

    private let sections: [Section] = [
        Section(header: "배너", rows: [
            Row(title: "배너 — 일반", make: { NormalBannerViewController() }),
            Row(title: "배너 — XIB (Interface Builder)", make: { InterfaceBuilderBannerViewController() }),
        ]),
        Section(header: "전면 · 리워드 · 앱오프닝", rows: [
            Row(title: "전면 광고", make: { InterstitialViewController() }),
            Row(title: "리워드 광고", make: { RewardViewController() }),
            Row(title: "앱오프닝 광고", make: { AppOpenViewController() }),
        ]),
        Section(header: "네이티브", rows: [
            Row(title: "네이티브 — 템플릿 바인딩", make: { TemplateNativeViewController() }),
            Row(title: "네이티브 — 템플릿 + 스타일", make: { StyledTemplateNativeViewController() }),
            Row(title: "네이티브 — 커스텀 바인딩", make: { CustomBindingNativeViewController() }),
        ]),
        Section(header: "팝업", rows: [
            Row(title: "팝업 — 종료", make: { ExitPopupViewController() }),
            Row(title: "팝업 — 전환", make: { TransitionPopupViewController() }),
        ]),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AdWhale iOS 샘플 (UIKit)"
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableHeaderView = makeHeaderView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        AdWhaleBootstrap.onStateChanged = { [weak self] in self?.renderStatus() }
        renderStatus()
    }

    // MARK: - 헤더 (SDK 상태 + Publisher UID)

    private func makeHeaderView() -> UIView {
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.layer.cornerRadius = 5
        statusDot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        statusDot.heightAnchor.constraint(equalToConstant: 10).isActive = true

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .secondaryLabel

        let statusRow = UIStackView(arrangedSubviews: [statusDot, statusLabel])
        statusRow.axis = .horizontal
        statusRow.spacing = 8
        statusRow.alignment = .center

        let uidLabel = UILabel()
        uidLabel.text = "Publisher UID"
        uidLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        uidLabel.textColor = .secondaryLabel

        publisherUidField.text = SampleConfig.publisherUid
        publisherUidField.borderStyle = .roundedRect
        publisherUidField.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        publisherUidField.autocapitalizationType = .none
        publisherUidField.autocorrectionType = .no
        publisherUidField.returnKeyType = .done
        publisherUidField.addAction(UIAction { [weak self] _ in
            self?.publisherUidField.resignFirstResponder()
        }, for: .editingDidEndOnExit)

        let reinitButton = UIButton(type: .system)
        var config = UIButton.Configuration.bordered()
        config.title = "이 UID 로 다시 초기화"
        config.cornerStyle = .medium
        reinitButton.configuration = config
        reinitButton.addAction(UIAction { [weak self] _ in self?.reinitializeTapped() }, for: .touchUpInside)

        let note = UILabel()
        note.text = "UID 는 Config/AdWhale.xcconfig → Info.plist 로 주입된다. "
                  + "여기서 바꾸면 initialize(publisherUid:) 오버로드로 다시 초기화한다."
        note.font = .systemFont(ofSize: 11)
        note.textColor = .tertiaryLabel
        note.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [statusRow, uidLabel, publisherUidField, reinitButton, note])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 210))
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -32),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])
        return container
    }

    private func renderStatus() {
        statusDot.backgroundColor = AdWhaleBootstrap.isInitialized ? .systemGreen : .systemOrange
        statusLabel.text = (AdWhaleBootstrap.isInitialized ? "SDK 초기화 완료 — " : "SDK 초기화 대기 — ")
            + AdWhaleBootstrap.lastMessage
    }

    private func reinitializeTapped() {
        let uid = (publisherUidField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else {
            adlog("Publisher UID 가 비어 있습니다.")
            return
        }
        publisherUidField.resignFirstResponder()
        adlog("initialize(publisherUid: \(uid)) 호출")
        AdWhaleBootstrap.reinitialize(publisherUid: uid)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension SampleMainViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        var content = cell.defaultContentConfiguration()
        content.text = row.title
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        let vc = row.make()
        vc.title = row.title
        navigationController?.pushViewController(vc, animated: true)
    }
}
