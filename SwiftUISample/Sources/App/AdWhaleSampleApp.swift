import SwiftUI

@main
struct AdWhaleSampleApp: App {
    @StateObject private var bootstrap = AdWhaleBootstrap.shared

    init() {
        adlog("샘플 시작\n\(SampleConfig.summary)")
        // SDK 초기화 (register → initialize → GDPR 동의)
        AdWhaleBootstrap.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bootstrap)
        }
    }
}
