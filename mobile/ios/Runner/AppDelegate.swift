import Flutter
import UIKit
import FirebaseCore
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBTzZVtm0j7PyCGPy7xKlHG0R5W_4dHAX0")
    FirebaseApp.configure()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "goitc.aba_pay_launcher",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "openInstalledApp",
            let args = call.arguments as? [String: Any],
            let bundleId = args["bundleId"] as? String,
            let urlString = args["url"] as? String,
            let url = URL(string: urlString)
      else {
        result(false)
        return
      }
      result(GoITCOpenInstalledApp(bundleId, url))
    }
  }
}
