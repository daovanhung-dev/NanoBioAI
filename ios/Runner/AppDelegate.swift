import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var realtimeVoiceAudio: RealtimeVoiceAudioController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      realtimeVoiceAudio = RealtimeVoiceAudioController(
        messenger: controller.binaryMessenger
      )
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    realtimeVoiceAudio?.dispose()
    realtimeVoiceAudio = nil
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    // Stop and deactivate the AVAudioSession as soon as the app enters the
    // background. The Dart lifecycle observer closes the Live WebSocket too;
    // this native guard prevents an in-flight callback from retaining audio.
    realtimeVoiceAudio?.dispose()
    super.applicationDidEnterBackground(application)
  }
}
