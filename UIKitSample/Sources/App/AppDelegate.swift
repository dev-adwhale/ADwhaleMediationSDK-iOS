import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        adlog("샘플 시작\n\(SampleConfig.summary)")

        // SDK 초기화 (ATT → register → initialize)
        AdWhaleBootstrap.start()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UINavigationController(rootViewController: SampleMainViewController())
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
