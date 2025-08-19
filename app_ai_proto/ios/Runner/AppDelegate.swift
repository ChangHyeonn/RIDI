import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // iOS 18.6 호환성을 위한 설정
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // iOS 18.6 검은 화면 문제 해결
    if #available(iOS 15.0, *) {
      // iOS 15+ 에서는 자동으로 처리됨
    } else {
      // iOS 14 이하에서의 호환성 설정
      window?.backgroundColor = UIColor.white
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
