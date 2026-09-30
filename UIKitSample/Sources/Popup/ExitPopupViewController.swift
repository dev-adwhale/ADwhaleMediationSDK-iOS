import UIKit
import AdWhaleSDK

/// 팝업 — 종료
///
/// Android 샘플에서 `SampleMainActivity` 가 Back 키를 가로채 띄우던 종료 팝업에 대응한다.
/// iOS 에는 Back 키가 없으므로 "앱 종료" 버튼으로 대신한다.
///
/// ## 실제 앱에서의 패턴
/// 1. 화면 진입(또는 앱 시작) 시 `loadAd()` 로 미리 준비한다.
/// 2. 사용자가 종료 동작을 하면 `show(from:)`.
/// 3. `primaryButton` 으로 닫혔으면 종료, 그 외에는 그대로 머문다.
/// 4. 팝업이 뜨지 못하면(`didFailToShowWithError` 300) 앱 기본 종료 확인 다이얼로그로 폴백한다.
///
/// > iOS 는 앱이 스스로 종료하는 것을 권장하지 않는다(App Store 심사 지적 사항).
/// > 이 샘플은 종료 대신 확인 다이얼로그까지만 보여 준다.
final class ExitPopupViewController: PopupSampleViewController {

    override var primaryButtonText: String { "종료" }
    override var secondaryButtonText: String { "취소" }
    override var customDescription: String { "정말 종료하시겠습니까?" }

    override func viewDidLoad() {
        super.viewDidLoad()

        addNote("실제 앱에서는 화면 진입 시 미리 loadAd() 해 두고, "
                + "종료 동작 시점에 show(from:) 한다. 팝업이 못 뜨면 기본 다이얼로그로 폴백한다.")

        addButton("팝업 미리 로드 (loadAd)") { [weak self] in self?.loadPopup() }
        addButton("앱 종료 시도 (show)") { [weak self] in self?.showPopup() }

        // 화면에 들어오면 바로 준비해 둔다.
        loadPopup()
    }

    override func handlePopupUnavailable(reason: String) {
        showFallbackExitDialog()
    }

    override func handlePopupClosed(reason: AdWhalePopupCloseReason) {
        switch reason {
        case .primaryButton:
            // 실제 앱이라면 여기서 종료 처리를 한다.
            adlog("종료 확인됨 (primaryButton)")
        default:
            adlog("종료 취소됨 (\(reason.reasonName))")
        }
        // 다음 회차를 위해 다시 준비한다.
        loadPopup()
    }

    private func showFallbackExitDialog() {
        let alert = UIAlertController(title: nil, message: "종료 하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "예", style: .destructive) { _ in
            adlog("기본 다이얼로그에서 종료 확인")
        })
        alert.addAction(UIAlertAction(title: "아니요", style: .cancel))
        present(alert, animated: true)
    }
}
