import UIKit
import AdWhaleSDK

/// 팝업 — 전환
///
/// Android 샘플의 `TransitionTestMainActivity` ("앱 전환 광고 테스트")에 대응한다.
///
/// 화면을 넘어가기 직전에 팝업을 띄우고, 닫히면 원래 가려던 화면으로 이동하는 패턴이다.
/// 핵심은 **팝업이 뜨든 안 뜨든 사용자의 이동은 반드시 일어나야 한다**는 것이다.
/// 그래서 `didFailToShowWithError`(300) 와 `didCloseWithReason` 양쪽 모두에서 다음 화면으로 넘긴다.
final class TransitionPopupViewController: PopupSampleViewController {

    override var primaryButtonText: String { "이동" }
    override var secondaryButtonText: String { "닫기" }
    override var customDescription: String { "다음 화면으로 이동합니다." }

    /// 팝업 처리 결과와 무관하게 이동이 한 번만 일어나도록 하는 가드.
    private var didNavigate = false

    override func viewDidLoad() {
        super.viewDidLoad()

        addNote("전환 팝업은 '광고가 없어도 사용자는 이동해야 한다'가 원칙이다. "
                + "노출 실패(300)와 닫힘 콜백 양쪽에서 다음 화면으로 넘긴다.")

        addButton("팝업 미리 로드 (loadAd)") { [weak self] in self?.loadPopup() }
        addButton("다음 화면으로 이동 (팝업 경유)") { [weak self] in
            self?.didNavigate = false
            self?.showPopup()
        }

        loadPopup()
    }

    override func handlePopupUnavailable(reason: String) {
        navigateToNextScreen()
    }

    override func handlePopupClosed(reason: AdWhalePopupCloseReason) {
        navigateToNextScreen()
        loadPopup()
    }

    private func navigateToNextScreen() {
        guard !didNavigate else { return }
        didNavigate = true

        adlog("전환 완료 — 다음 화면으로 이동")
        let next = UIViewController()
        next.title = "전환된 화면"
        next.view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "팝업을 거쳐 이동한 화면입니다."
        label.font = .systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        next.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: next.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: next.view.centerYAnchor),
        ])

        navigationController?.pushViewController(next, animated: true)
    }
}
