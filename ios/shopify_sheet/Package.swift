// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "shopify_sheet",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "shopify-sheet", targets: ["shopify_sheet"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Shopify/checkout-kit", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "shopify_sheet",
            dependencies: [
                .product(name: "ShopifyCheckoutKit", package: "checkout-kit"),
            ],
            path: "Sources/shopify_sheet",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
    ]
)
