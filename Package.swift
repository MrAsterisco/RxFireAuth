// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "RxFireAuth",
  platforms: [
    .macOS(.v11),
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "RxFireAuth",
      targets: ["RxFireAuth"]),
  ],
  dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
    .package(url: "https://github.com/auth0/JWTDecode.swift", from: "3.0.0"),
    .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.0.0"),
		.package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "RxFireAuth",
      dependencies: [
        .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
        .product(name: "JWTDecode", package: "JWTDecode.swift"),
        .product(name: "RxSwift", package: "RxSwift"),
				.product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
      ],
      path: "RxFireAuth",
      sources: [
        ".",
        "Classes",
        "macOS"
      ]
    )
  ]
)
