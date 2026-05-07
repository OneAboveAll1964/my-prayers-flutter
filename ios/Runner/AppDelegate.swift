import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // NOTE: do NOT call `UNUserNotificationCenter.current().delegate = self` here.
    // flutter_local_notifications sets itself as the notification center delegate
    // during init; if we override it before super.application(...) the plugin
    // never receives userNotificationCenter(_:willPresent:withCompletionHandler:)
    // and foreground notifications never display.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
