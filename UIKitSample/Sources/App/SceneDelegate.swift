import UIKit

/// 화면(window) 구성.
///
/// iOS 27 부터 UIScene 을 쓰지 않는 앱은 실행 직후 종료되므로, window 는 AppDelegate 가 아닌
/// 이 SceneDelegate 에서 만든다. (Info.plist 의 `UIApplicationSceneManifest` 와 짝을 이룬다)
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: SampleMainViewController())
        window.makeKeyAndVisible()
        self.window = window
    }
}
