import Flutter
import UIKit
import Security
import Darwin

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CurConvAccessClockPlugin") {
      CurConvAccessClockPlugin.register(with: registrar)
    }
  }
}

private class CurConvAccessClockPlugin: NSObject, FlutterPlugin {
  private static let service = "com.example.curconv.access"
  private static let account = "offline_lease"

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = CurConvAccessClockPlugin()
    let channel = FlutterMethodChannel(
      name: "curconv/access_clock",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "uptime":
      result(Int64(ProcessInfo.processInfo.systemUptime * 1000.0))

    case "bootIdentity":
      var bootTime = timeval()
      var size = MemoryLayout<timeval>.size
      let status = sysctlbyname("kern.boottime", &bootTime, &size, nil, 0)
      if status == 0 {
        result("ios-boot:\\(bootTime.tv_sec)")
      } else {
        // Conservative fallback: changing this value invalidates offline leases.
        result("ios-process:\\(ProcessInfo.processInfo.systemUptime)")
      }

    case "deviceInfo":
      let device = UIDevice.current
      let identifier = device.identifierForVendor?.uuidString ?? UUID().uuidString
      let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
      result([
        "device_id": identifier,
        "brand": "Apple",
        "model": device.localizedModel,
        "android_version": "iOS \\(device.systemVersion)",
        "app_version": version
      ])

    case "readLease":
      do {
        result(try readKeychain())
      } catch {
        result(FlutterError(code: "access-storage", message: "Offline permission could not be read.", details: nil))
      }

    case "writeLease":
      guard let args = call.arguments as? [String: Any],
            let lease = args["lease"] as? String else {
        result(FlutterError(code: "access-storage", message: "Missing lease.", details: nil))
        return
      }
      do {
        try writeKeychain(lease)
        result(nil)
      } catch {
        result(FlutterError(code: "access-storage", message: "Offline permission could not be stored.", details: nil))
      }

    case "clearLease":
      let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: Self.service,
        kSecAttrAccount as String: Self.account
      ]
      let status = SecItemDelete(query as CFDictionary)
      if status == errSecSuccess || status == errSecItemNotFound {
        result(nil)
      } else {
        result(FlutterError(code: "access-storage", message: "Offline permission could not be cleared.", details: nil))
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func readKeychain() throws -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: Self.account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess,
          let data = item as? Data,
          let value = String(data: data, encoding: .utf8) else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
    return value
  }

  private func writeKeychain(_ value: String) throws {
    let data = Data(value.utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: Self.account
    ]
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      var newItem = query
      attributes.forEach { newItem[$0.key] = $0.value }
      let addStatus = SecItemAdd(newItem as CFDictionary, nil)
      guard addStatus == errSecSuccess else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus))
      }
    } else if status != errSecSuccess {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
  }
}
