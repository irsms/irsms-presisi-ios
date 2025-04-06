import Flutter
import UIKit
import GoogleMaps
// import MapboxMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Inisialisasi Google Maps SDK dengan API Key Anda
    GMSServices.provideAPIKey("AIzaSyAOhYsmTmd7YWwCSFz-MQMRb2ACqlmIA68")

    // Inisialisasi Mapbox dengan Access Token Anda
    // let resourceOptions = ResourceOptionsManager.default
    // resourceOptions.update(resourceOptions: ResourceOptions(accessToken: "sk.eyJ1IjoiaXlhbWlmIiwiYSI6ImNsbWcxZzk0bzI3NXozZW81emRya3gyc28ifQ.evBB05GTKDRSf_j720ejJQ"))


    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
