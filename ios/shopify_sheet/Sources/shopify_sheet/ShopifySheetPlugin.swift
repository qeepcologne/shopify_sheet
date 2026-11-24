import Flutter
import UIKit
import ShopifyCheckoutKit

public class ShopifySheetPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    fileprivate var eventSink: FlutterEventSink?
    private var checkoutViewController: UIViewController?
    private var checkoutDelegate: CheckoutEvents?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "shopify_sheet", binaryMessenger: registrar.messenger())
        let instance = ShopifySheetPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(name: "shopify_sheet_events", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "launchCheckout":
            guard let args = call.arguments as? [String: Any],
                  let checkoutUrl = args["checkoutUrl"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid or missing arguments", details: nil))
                return
            }
            let config = args["config"] as? [String: Any] ?? [:]
            presentCheckout(url: checkoutUrl, config: config, result: result)
        case "closeCheckout":
            closeCheckout(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    private func presentCheckout(url: String, config: [String: Any], result: @escaping FlutterResult) {
        guard let checkoutURL = URL(string: url) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid Checkout URL", details: nil))
            return
        }

        Task { @MainActor in
            guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first?.rootViewController else {
                result(FlutterError(code: "INVALID_CONTEXT", message: "No valid root view controller", details: nil))
                return
            }

            Self.applyConfiguration(config)
            //the sdk holds its delegate weakly
            let delegate = CheckoutEvents(plugin: self)
            self.checkoutDelegate = delegate
            self.checkoutViewController = ShopifyCheckout.present(
                checkout: checkoutURL,
                from: rootViewController,
                delegate: delegate
            )
            result("Checkout Launched")
        }
    }

    @MainActor
    private static func applyConfiguration(_ config: [String: Any]) {
        ShopifyCheckout.configure { configuration in
            let customize: (inout CheckoutColors) -> Void = { colors in
                if let color = hexToUIColor(config["titleBarBackgroundColor"]) { colors.headerBackgroundColor = color }
                if let color = hexToUIColor(config["backgroundColor"]) { colors.webViewBackgroundColor = color }
                if let color = hexToUIColor(config["tintColor"]) { colors.progressIndicatorColor = color }
                if let color = hexToUIColor(config["closeButtonTintColor"]) { colors.closeIconTintColor = color }
            }

            switch config["colorScheme"] as? String {
            case "web":
                var colors = CheckoutColors()
                customize(&colors)
                configuration.appearance = .storefront(colors: colors)
            case "light":
                configuration.appearance = .app(CheckoutColorScheme.light().customize(customize))
            case "dark":
                configuration.appearance = .app(CheckoutColorScheme.dark().customize(customize))
            default:
                configuration.appearance = .app(CheckoutColorScheme.automatic().customize(customize))
            }

            if let title = config["title"] as? String {
                configuration.title = title
            }
            if let preload = config["preload"] as? Bool {
                configuration.preloading.enabled = preload
            }
        }
    }

    private func closeCheckout(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            if let checkoutViewController = self.checkoutViewController {
                checkoutViewController.dismiss(animated: true) {
                    self.checkoutViewController = nil
                    result("Checkout Closed")
                }
            } else {
                result(FlutterError(code: "NO_ACTIVE_CHECKOUT", message: "No active checkout to close", details: nil))
            }
        }
    }

    fileprivate func checkoutDidDismiss() {
        checkoutViewController = nil
    }
}

/// `CheckoutDelegate` is main-actor isolated, so the conformance lives on its own main-actor type instead of the plugin.
@MainActor
private final class CheckoutEvents: CheckoutDelegate {
    private weak var plugin: ShopifySheetPlugin?

    init(plugin: ShopifySheetPlugin) {
        self.plugin = plugin
    }

    func checkoutDidComplete(_ event: CheckoutCompleteEvent) {
        var payload: [String: Any] = ["event": "completed"]
        do {
            let json = try JSONEncoder().encode(event.checkout)
            payload["checkout"] = String(data: json, encoding: .utf8)
        } catch {
            NSLog("ShopifySheetPlugin: error serializing checkout: \(error)")
        }
        plugin?.eventSink?(payload)
    }

    /// The buyer closed the sheet, or the SDK closed it after a terminal failure (reported through `checkoutDidFail` first),
    /// reported as `canceled`, the event name this plugin has always used for it.
    func checkoutDidDismiss() {
        plugin?.checkoutDidDismiss()
        plugin?.eventSink?(["event": "canceled"])
    }

    func checkoutDidFail(_ event: CheckoutFailureEvent) {
        plugin?.eventSink?([
            "event": "failed",
            "error": event.error.message,
            "errorCode": event.error.code.rawValue,
        ])
    }
}

private func hexToUIColor(_ value: Any?) -> UIColor? {
    guard let hex = value as? String else {
        return nil
    }
    let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0
    guard hexSanitized.count == 6, Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
        return nil
    }

    let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
    let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
    let blue = CGFloat(rgb & 0x0000FF) / 255.0

    return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
}
