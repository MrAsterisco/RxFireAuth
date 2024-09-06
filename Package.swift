// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RxFireAuth",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "RxFireAuth",
      targets: ["RxFireAuth"]),
  ],
  dependencies: [
    .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
    .package(name: "JWTDecode", url: "https://github.com/auth0/JWTDecode.swift", from: "2.0.0"),
    .package(name: "RxSwift", url: "https://github.com/ReactiveX/RxSwift", from: "6.0.0"),
		.package(name: "GoogleSignIn", url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "RxFireAuth",
      dependencies: [
        .product(name: "FirebaseAuth", package: "Firebase"),
        .product(name: "JWTDecode", package: "JWTDecode"),
        .product(name: "RxSwift", package: "RxSwift"),
        .product(name: "RxCocoa", package: "RxSwift"),
				.product(name: "GoogleSignIn", package: "GoogleSignIn")
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
