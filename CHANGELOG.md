## 0.0.1
* First Release of implementation of Android Sdk of Checkout Sheet Shopify iOS Coming Soon

## 0.0.2
* iOS Support added using Shopify iOS checkout sdk version 3.1.2

## 0.0.3
* Programmatically close checkout added

## 0.0.4 
* Readme Updated

## 0.0.5 
* update checkout-sheet-kit-android 3.5.1 + dependencies

## 0.0.6
* update checkout-sheet-kit-android 3.5.2

## 0.0.7
* update checkout-sheet-kit-android 3.5.3 + dependencies Android iOS plus added checkout sheet configuration

## 0.1.0
* implement android pixel events

## 0.1.1
* swift package manager support

## 0.1.2
* android: update checkout-sheet-kit 3.5.4 + dependencies

## 1.0.0
* Checkout Kit 4 (`com.shopify:checkout-kit` 4.0.0, `Shopify/checkout-kit` 4.0.0) replaces Checkout Sheet Kit 3 on Android and iOS
* BREAKING: `ShopifySheetEventType.pixelEvent` removed, Checkout Kit 4 no longer emits web pixel events; `completed` carries the checkout as `data` on both platforms
* `failed` events carry an `errorCode`
* Android: `title`, colors and `closeButtonTintColor` are applied
* iOS: minimum iOS 15; the plugin sources exist once, shared by Swift Package Manager and CocoaPods
