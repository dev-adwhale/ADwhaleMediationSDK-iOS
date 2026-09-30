import SwiftUI
import AdWhaleSDK

/// 팝업 — 전환
///
/// Android 샘플의 `TransitionTestMainActivity` ("앱 전환 광고 테스트")에 대응한다.
///
/// 화면을 넘어가기 직전에 팝업을 띄우고, 닫히면 원래 가려던 화면으로 이동하는 패턴이다.
/// 핵심은 **팝업이 뜨든 안 뜨든 사용자의 이동은 반드시 일어나야 한다**는 것이다.
/// 그래서 노출 실패(300)와 닫힘 콜백 양쪽 모두에서 다음 화면으로 넘긴다.
struct TransitionPopupScreen: View {
    @StateObject private var controller = PopupController()
    @State private var placementUid = SampleConfig.popupPlacementUid
    @State private var navigates = false

    var body: some View {
        AdSampleScreen(title: "팝업 — 전환", placementUid: $placementUid) {
            SampleNote("전환 팝업은 '광고가 없어도 사용자는 이동해야 한다'가 원칙이다. "
                       + "노출 실패(300)와 닫힘 콜백 양쪽에서 다음 화면으로 넘긴다.")

            SampleButton("팝업 미리 로드 (loadAd)") { load() }
            SampleButton("다음 화면으로 이동 (팝업 경유)") { controller.show() }

            NavigationLink(isActive: $navigates) {
                TransitionDestinationScreen()
            } label: {
                EmptyView()
            }
            .hidden()
        }
        .onAppear {
            controller.onUnavailable = { _ in navigateNext() }
            controller.onClosed = { _ in
                navigateNext()
                load()
            }
            controller.resume()
            load()
        }
    }

    private func load() {
        controller.load(placementUid: placementUid,
                        primaryButtonText: "이동",
                        secondaryButtonText: "닫기",
                        description: "다음 화면으로 이동합니다.")
    }

    private func navigateNext() {
        guard !navigates else { return }
        adlog("전환 완료 — 다음 화면으로 이동")
        navigates = true
    }
}

struct TransitionDestinationScreen: View {
    var body: some View {
        VStack {
            Text("팝업을 거쳐 이동한 화면입니다.")
                .font(.callout)
        }
        .navigationTitle("전환된 화면")
        .navigationBarTitleDisplayMode(.inline)
    }
}
