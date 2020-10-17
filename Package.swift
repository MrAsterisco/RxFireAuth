// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RxFireAuth",
  platforms: [
    .macOS(.v10_11),
    .iOS(.v9)
  ],
  products: [
    .library(
      name: "RxFireAuth",
      targets: ["RxFireAuth"]),
  ],
  dependencies: [
    .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk", .branch("6.34-spm-beta")),
    .package(name: "JWTDecode", url: "https://github.com/auth0/JWTDecode.swift", from: "2.4.0"),
    .package(name: "RxSwift", url: "https://github.com/ReactiveX/RxSwift", from: "5.0.0"),
    .package(name: "AppAuth", url: "https://github.com/openid/AppAuth-iOS", from: "1.4.0")
  ],
  targets: [
    .target(
      name: "RxFireAuth",
      dependencies: [
        .product(name: "FirebaseAuth", package: "Firebase"),
        .product(name: "JWTDecode", package: "JWTDecode"),
        .product(name: "RxSwift", package: "RxSwift"),
        .product(name: "RxCocoa", package: "RxSwift"),
        .product(name: "AppAuth", package: "AppAuth")
      ],
      path: "RxFireAuth",
      sources: [
        ".",
        "Classes",
        "iOS",
        "macOS"
      ]
    )
  ]
)
