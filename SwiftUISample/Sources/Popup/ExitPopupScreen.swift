import SwiftUI
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
/// 4. 팝업이 뜨지 못하면(`didFailToShowWithError` 300) 앱 기본 확인 다이얼로그로 폴백한다.
///
/// > iOS 는 앱이 스스로 종료하는 것을 권장하지 않는다(App Store 심사 지적 사항).
/// > 이 샘플은 종료 대신 확인 다이얼로그까지만 보여 준다.
struct ExitPopupScreen: View {
    @StateObject private var controller = PopupController()
    @State private var placementUid = SampleConfig.popupPlacementUid
    @State private var showsFallbackDialog = false

    var body: some View {
        AdSampleScreen(title: "팝업 — 종료", placementUid: $placementUid) {
            SampleNote("실제 앱에서는 화면 진입 시 미리 loadAd() 해 두고, "
                       + "종료 동작 시점에 show(from:) 한다. 팝업이 못 뜨면 기본 다이얼로그로 폴백한다.")

            SampleButton("팝업 미리 로드 (loadAd)") { load() }
            SampleButton("앱 종료 시도 (show)") { controller.show() }
        }
        .alert("종료 하시겠습니까?", isPresented: $showsFallbackDialog) {
            Button("예", role: .destructive) { adlog("기본 다이얼로그에서 종료 확인") }
            Button("아니요", role: .cancel) {}
        }
        .onAppear {
            controller.onUnavailable = { _ in showsFallbackDialog = true }
            controller.onClosed = { reason in
                switch reason {
                case .primaryButton:
                    // 실제 앱이라면 여기서 종료 처리를 한다.
                    adlog("종료 확인됨 (primaryButton)")
                default:
                    adlog("종료 취소됨 (\(reason.reasonName))")
                }
                // 다음 회차를 위해 다시 준비한다.
                load()
            }
            controller.resume()
            load()
        }
    }

    private func load() {
        controller.load(placementUid: placementUid,
                        primaryButtonText: "종료",
                        secondaryButtonText: "취소",
                        description: "정말 종료하시겠습니까?")
    }
}
