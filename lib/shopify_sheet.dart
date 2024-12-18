import 'package:shopify_sheet/shopify_sheet_platform_interface.dart';

/// Event data for Shopify Checkout
class ShopifySheetEvent {
  final ShopifySheetEventType type;
  final String? error;

  ShopifySheetEvent({required this.type, this.error});

  /// Factory to parse event data from native
  factory ShopifySheetEvent.fromNative(Map<String, dynamic> data) {
    final eventType = data['event'];
    final error = data['error'] as String?;

    switch (eventType) {
      case 'completed':
        return ShopifySheetEvent(type: ShopifySheetEventType.completed, error: error);
      case 'canceled':
        return ShopifySheetEvent(type: ShopifySheetEventType.canceled, error: error);
      case 'failed':
        return ShopifySheetEvent(type: ShopifySheetEventType.failed, error: error);
      default:
        return ShopifySheetEvent(type: ShopifySheetEventType.unknown, error: error);
    }
  }
}

/// Enum for Shopify Checkout event types
enum ShopifySheetEventType {
  completed,
  canceled,
  failed,
  unknown,
}

class ShopifySheet {
  Future<String?> getPlatformVersion() {
    return ShopifySheetPlatform.instance.getPlatformVersion();
  }

  Future<void> launchCheckout(String checkoutUrl) {
    return ShopifySheetPlatform.instance.launchCheckout(checkoutUrl);
  }

  /// Listen for checkout events
  Stream<ShopifySheetEvent> get checkoutEvents {
    return ShopifySheetPlatform.instance.checkoutEvents.map((event) {
      return ShopifySheetEvent.fromNative(event);
    });
  }
}
