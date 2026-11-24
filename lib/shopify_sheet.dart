import 'dart:convert';
import 'dart:ui';

import 'package:shopify_sheet/shopify_sheet_platform_interface.dart';

/// Event data for Shopify Checkout
class ShopifySheetEvent {
  final ShopifySheetEventType type;

  /// Human-readable failure message ([ShopifySheetEventType.failed] only).
  final String? error;

  /// Machine-readable failure code ([ShopifySheetEventType.failed] only), the same on both platforms:
  /// `storefront_password_required`, `customer_account_required`, `cart_expired`, `cart_completed`, `invalid_cart`,
  /// `http_error`, `network_error`, `web_content_process_terminated`, `sdk_error` or `unknown`.
  final String? errorCode;

  /// The checkout as JSON in the Embedded Checkout Protocol shape ([ShopifySheetEventType.completed] only): `id`,
  /// `status`, `currency`, `line_items`, `totals` (amounts in minor units), `order` (`id`, `permalink_url`), ...
  final Map<String, dynamic>? data;

  ShopifySheetEvent({
    required this.type,
    this.error,
    this.errorCode,
    this.data,
  });

  /// Factory to parse event data from native
  factory ShopifySheetEvent.fromNative(Map<String, dynamic> data) {
    final error = data['error'] as String?;
    final errorCode = data['errorCode'] as String?;
    final checkout = data['checkout'] as String?;

    switch (data['event']) {
      case 'completed':
        return ShopifySheetEvent(
          type: ShopifySheetEventType.completed,
          data: checkout == null ? null : jsonDecode(checkout) as Map<String, dynamic>,
        );
      case 'canceled':
        return ShopifySheetEvent(type: ShopifySheetEventType.canceled);
      case 'failed':
        return ShopifySheetEvent(type: ShopifySheetEventType.failed, error: error, errorCode: errorCode);
      default:
        return ShopifySheetEvent(type: ShopifySheetEventType.unknown, error: error);
    }
  }
}

/// Enum for Shopify Checkout event types
enum ShopifySheetEventType {
  /// The order was placed. The confirmation page stays visible until the buyer closes the sheet ([canceled]).
  completed,

  /// The sheet was closed, by the buyer or by the SDK after a [failed] checkout.
  canceled,

  /// The checkout failed; a [canceled] follows when the sheet closes.
  failed,
  unknown,
}

class ShopifySheet {
  Future<String?> getPlatformVersion() {
    return ShopifySheetPlatform.instance.getPlatformVersion();
  }

  Future<void> launchCheckout(
      String checkoutUrl, {
        ShopifySheetConfiguration? configuration,
      }) {
    return ShopifySheetPlatform.instance.launchCheckout(
      checkoutUrl,
      configuration: configuration,
    );
  }

  /// Listen for checkout events
  Stream<ShopifySheetEvent> get checkoutEvents {
    return ShopifySheetPlatform.instance.checkoutEvents.map((event) {
      return ShopifySheetEvent.fromNative(event);
    });
  }

  Future<void> closeCheckout() {
    return ShopifySheetPlatform.instance.closeCheckout();
  }
}




/// Configuration class for Shopify Checkout Sheet
class ShopifySheetConfiguration {
  /// Title text for the checkout sheet
  final String? title;

  /// Header background color (hex string format: "#RRGGBB")
  final String? titleBarBackgroundColor;

  /// Background color behind the checkout web content (hex string format: "#RRGGBB")
  final String? backgroundColor;

  /// Progress indicator color (hex string format: "#RRGGBB")
  final String? tintColor;

  /// Close button tint color (hex string format: "#RRGGBB")
  final String? closeButtonTintColor;

  /// Enable preloading of checkout
  final bool? preload;

  /// Color scheme preference (light, dark, automatic, or web). `web` keeps the storefront's own checkout branding.
  final String? colorScheme;

  ShopifySheetConfiguration({
    this.title,
    this.titleBarBackgroundColor,
    this.backgroundColor,
    this.tintColor,
    this.closeButtonTintColor,
    this.preload,
    this.colorScheme = 'automatic',
  });

  /// Convert Flutter Color to hex string
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Create configuration with Flutter Colors
  factory ShopifySheetConfiguration.fromColors({
    String? title,
    Color? titleBarBackgroundColor,
    Color? backgroundColor,
    Color? tintColor,
    Color? closeButtonTintColor,
    bool? preload,
    String? colorScheme,
  }) {
    return ShopifySheetConfiguration(
      title: title,
      titleBarBackgroundColor: titleBarBackgroundColor != null ? colorToHex(titleBarBackgroundColor) : null,
      backgroundColor: backgroundColor != null ? colorToHex(backgroundColor) : null,
      tintColor: tintColor != null ? colorToHex(tintColor) : null,
      closeButtonTintColor: closeButtonTintColor != null ? colorToHex(closeButtonTintColor) : null,
      preload: preload,
      colorScheme: colorScheme ?? 'automatic',
    );
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      if (title != null) 'title': title,
      if (titleBarBackgroundColor != null) 'titleBarBackgroundColor': titleBarBackgroundColor,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (tintColor != null) 'tintColor': tintColor,
      if (closeButtonTintColor != null) 'closeButtonTintColor': closeButtonTintColor,
      if (preload != null) 'preload': preload,
      if (colorScheme != null) 'colorScheme': colorScheme,
    };
  }
}