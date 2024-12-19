import 'package:flutter/material.dart';
import 'package:shopify_sheet/shopify_sheet.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ShopifyCheckoutDemo(),
    );
  }
}

class ShopifyCheckoutDemo extends StatefulWidget {
  @override
  State<ShopifyCheckoutDemo> createState() => _ShopifyCheckoutDemoState();
}

class _ShopifyCheckoutDemoState extends State<ShopifyCheckoutDemo> {
  final ShopifySheet _shopifySheet = ShopifySheet();

  @override
  void initState() {
    super.initState();

    // Listen to checkout events
    _shopifySheet.checkoutEvents.listen((event) {
      switch (event.type) {
        case ShopifySheetEventType.completed:
          print("Checkout Completed");
          break;
        case ShopifySheetEventType.canceled:
          print("Checkout Canceled");
          break;
        case ShopifySheetEventType.failed:
          print("Checkout Failed: ${event.error}");
          break;
          case ShopifySheetEventType.pixelEvent:
          print("Pixel Event: ${event.data}");
          break;
        case ShopifySheetEventType.unknown:
        default:
          print("Unknown Event: ${event.error}");
      }

    });
  }

  void _launchCheckout() {
    _shopifySheet.launchCheckout(
        'https://modish-2-0.myshopify.com/cart/c/Z2NwLWFzaWEtc291dGhlYXN0MTowMUpGOU0xRUtQSjhTWk1aMjY2VlZZWUZTMA?key=7877f0ef27e2a7006c63da8096ea7d58'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shopify Checkout Plugin")),
      body: Center(
        child: ElevatedButton(
          onPressed: _launchCheckout,
          child: const Text("Launch Checkout"),
        ),
      ),
    );
  }
}
