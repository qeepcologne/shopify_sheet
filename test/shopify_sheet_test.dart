import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shopify_sheet/shopify_sheet.dart';
import 'package:shopify_sheet/shopify_sheet_method_channel.dart';
import 'package:shopify_sheet/shopify_sheet_platform_interface.dart';

class MockShopifySheetPlatform
    with MockPlatformInterfaceMixin
    implements ShopifySheetPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');



  @override
  // TODO: implement checkoutEvents
  Stream<Map<String, dynamic>> get checkoutEvents => throw UnimplementedError();

  @override
  Future<void> closeCheckout() => throw UnimplementedError();

  @override
  Future<void> launchCheckout(String checkoutUrl, {ShopifySheetConfiguration? configuration}) {
    // TODO: implement launchCheckout
    throw UnimplementedError();
  }
}

void main() {
  final ShopifySheetPlatform initialPlatform = ShopifySheetPlatform.instance;

  test('$MethodChannelShopifySheet is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelShopifySheet>());
  });

  test('getPlatformVersion', () async {
    ShopifySheet shopifySheetPlugin = ShopifySheet();
    MockShopifySheetPlatform fakePlatform = MockShopifySheetPlatform();
    ShopifySheetPlatform.instance = fakePlatform;

    expect(await shopifySheetPlugin.getPlatformVersion(), '42');
  });

  test('completed carries the decoded checkout', () {
    final event = ShopifySheetEvent.fromNative({
      'event': 'completed',
      'checkout': '{"id":"c1","currency":"EUR","totals":[{"type":"total","amount":1299}],"order":{"id":"o1"}}',
    });
    expect(event.type, ShopifySheetEventType.completed);
    expect(event.data?['order'], {'id': 'o1'});
    expect((event.data?['totals'] as List).single['amount'], 1299);
  });

  test('failed carries message and code', () {
    final event = ShopifySheetEvent.fromNative({
      'event': 'failed',
      'error': 'Web content process terminated.',
      'errorCode': 'web_content_process_terminated',
    });
    expect(event.type, ShopifySheetEventType.failed);
    expect(event.error, 'Web content process terminated.');
    expect(event.errorCode, 'web_content_process_terminated');
  });
}
