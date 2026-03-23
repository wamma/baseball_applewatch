import Flutter
import UIKit
import WidgetKit

private let kAppGroupID = "group.baseball.myteam"

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Flutter에서 팀 선택 시 App Group에 저장 → 위젯 갱신
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.example.baseball/widget",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
            if call.method == "saveTeam" {
                let team = call.arguments as? String ?? ""
                UserDefaults(suiteName: kAppGroupID)?.set(team, forKey: "myTeam")
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
