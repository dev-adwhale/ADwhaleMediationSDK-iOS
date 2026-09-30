import SwiftUI
import AdWhaleSDK

/// 샘플 메인 화면.
///
/// Android 샘플의 `activity_sample_main.xml` + `SampleMainActivity` 에 대응한다.
///
/// | Android 버튼 | iOS 화면 |
/// |---|---|
/// | `etMediaUid` (Media Uid 입력) | 상단 Publisher UID 입력 + "이 UID 로 다시 초기화" |
/// | `programmatic banner` | 배너 — 일반 (`AdWhaleMediationAdView`) |
/// | `앱 전환 광고 테스트` | 팝업 — 전환 |
/// | `interstitial` | 전면 광고 |
/// | `Reward Ad` | 리워드 광고 |
/// | `App Open Ad` | 앱오프닝 광고 |
/// | `Native Ad (for Custom Binding)` | 네이티브 — 커스텀 바인딩 |
/// | `Native Ad (for Template Binding)` | 네이티브 — 템플릿 바인딩 |
/// | `Native Template Binding Ad (with Style)` | 네이티브 — 템플릿 + 스타일 |
/// | Back 키 종료 팝업 | 팝업 — 종료 |
struct ContentView: View {
    @EnvironmentObject private var bootstrap: AdWhaleBootstrap
    @State private var publisherUid = SampleConfig.publisherUid

    var body: some View {
        NavigationView {
            List {
                statusSection

                Section("배너") {
                    NavigationLink("배너 — 일반") { NormalBannerScreen() }
                }

                Section("전면 · 리워드 · 앱오프닝") {
                    NavigationLink("전면 광고") { InterstitialScreen() }
                    NavigationLink("리워드 광고") { RewardScreen() }
                    NavigationLink("앱오프닝 광고") { AppOpenScreen() }
                }

                Section("네이티브") {
                    NavigationLink("네이티브 — 템플릿 바인딩") { TemplateNativeScreen() }
                    NavigationLink("네이티브 — 템플릿 + 스타일") { StyledTemplateNativeScreen() }
                    NavigationLink("네이티브 — 커스텀 바인딩") { CustomBindingNativeScreen() }
                }

                Section("팝업") {
                    NavigationLink("팝업 — 종료") { ExitPopupScreen() }
                    NavigationLink("팝업 — 전환") { TransitionPopupScreen() }
                }
            }
            .navigationTitle("AdWhale iOS 샘플 (SwiftUI)")
        }
        .navigationViewStyle(.stack)
    }

    private var statusSection: some View {
        Section {
            HStack(spacing: 8) {
                Circle()
                    .fill(bootstrap.isInitialized ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text((bootstrap.isInitialized ? "SDK 초기화 완료 — " : "SDK 초기화 대기 — ")
                     + bootstrap.lastMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Publisher UID")
                    .font(.caption).bold()
                    .foregroundStyle(.secondary)
                TextField("publisher uid", text: $publisherUid)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("이 UID 로 다시 초기화") {
                    let uid = publisherUid.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !uid.isEmpty else {
                        adlog("Publisher UID 가 비어 있습니다.")
                        return
                    }
                    adlog("initialize(publisherUid: \(uid)) 호출")
                    bootstrap.reinitialize(publisherUid: uid)
                }
                .buttonStyle(.bordered)
            }
        } header: {
            Text("상태")
        } footer: {
            Text("UID 는 Config/AdWhale.xcconfig → Info.plist 로 주입된다. "
                 + "여기서 바꾸면 initialize(publisherUid:) 오버로드로 다시 초기화한다.")
        }
    }
}

#Preview {
    ContentView().environmentObject(AdWhaleBootstrap.shared)
}
