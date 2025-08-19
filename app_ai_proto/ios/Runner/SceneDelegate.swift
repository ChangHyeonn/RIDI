import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    // Reuse the FlutterEngine from AppDelegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let flutterVC = FlutterViewController(engine: appDelegate.flutterEngine, nibName: nil, bundle: nil)

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = flutterVC
    self.window = window
    window.makeKeyAndVisible()
  }
}
