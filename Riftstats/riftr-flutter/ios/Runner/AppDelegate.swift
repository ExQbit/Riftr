import Flutter
import UIKit
import UserNotifications
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // Stripe SDK looks up the window via UIApplication.shared.delegate?.window.
  // With Scene-based lifecycle the AppDelegate's window is nil by default,
  // so Stripe can't find the root view controller in the hierarchy.
  // This override bridges the scene window back to the app delegate.
  override var window: UIWindow? {
    get {
      guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let sceneWindow = scene.windows.first else {
        return super.window
      }
      return sceneWindow
    }
    set {
      super.window = newValue
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set delegate to self so firebase_messaging can swizzle the methods.
    // Don't override willPresent/didReceive — let swizzling handle it.
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Forward notification tap to super (FlutterAppDelegate) → firebase_messaging swizzling
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("NATIVE: didReceive notification tap — \(response.notification.request.content.userInfo)")
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  // Always show push notification banner in foreground — bypasses swizzling issues
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  // Silent push / background fetch — firebase_messaging uses this for data messages
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("NATIVE: didReceiveRemoteNotification \(userInfo)")
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Native rect detection for pHash card crop
    let channel = FlutterMethodChannel(
      name: "com.riftr.scanner/rect_detection",
      binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "RectDetection")!.messenger()
    )
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard call.method == "detectRect",
            let args = call.arguments as? [String: Any],
            let yPlane = args["yPlane"] as? FlutterStandardTypedData,
            let width = args["width"] as? Int,
            let height = args["height"] as? Int,
            let bytesPerRow = args["bytesPerRow"] as? Int else {
        result(nil)
        return
      }
      self?.detectRect(yPlane: yPlane.data, width: width, height: height, bytesPerRow: bytesPerRow, result: result)
    }
  }

  // MARK: - VNDetectRectanglesRequest

  private func detectRect(yPlane: Data, width: Int, height: Int, bytesPerRow: Int, result: @escaping FlutterResult) {
    guard let provider = CGDataProvider(data: yPlane as CFData),
          let cgImage = CGImage(
            width: width, height: height,
            bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
          ) else {
      result(nil)
      return
    }

    let request = VNDetectRectanglesRequest()
    request.minimumAspectRatio = 0.55
    request.maximumAspectRatio = 0.90
    request.minimumSize = 0.10
    request.maximumObservations = 10
    request.minimumConfidence = 0.2

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      do {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        // Find best card-ratio rectangle
        let cardRatio: Float = 0.716
        var bestScore: Float = 0
        var bestRect: [String: Int]? = nil

        if let observations = request.results as? [VNRectangleObservation] {
          for obs in observations {
            let box = obs.boundingBox
            let x = Int(box.origin.x * CGFloat(width))
            let y = Int((1.0 - box.origin.y - box.height) * CGFloat(height))
            let w = Int(box.width * CGFloat(width))
            let h = Int(box.height * CGFloat(height))
            guard w > 0 && h > 0 else { continue }

            let ratio = Float(w) / Float(h)
            let ratioDiff = abs(ratio - cardRatio)
            if ratioDiff > 0.20 { continue }

            let area = Float(w * h) / Float(width * height)
            let score = area * (1.0 - ratioDiff * 3)
            if score > bestScore {
              bestScore = score
              bestRect = ["x": x, "y": y, "w": w, "h": h]
            }
          }
        }

        if bestRect != nil {
          result(bestRect)
          return
        }

        result(nil)
      } catch {
        result(nil)
      }
    }
  }
}
