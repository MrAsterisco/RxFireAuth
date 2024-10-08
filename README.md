# RxFireAuth

<a href="https://swift.org/package-manager">
  <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
</a>

RxFireAuth is a wrapper around the [Firebase Authentication](https://firebase.google.com/docs/auth) SDK that exposes most of the available functions through [RxSwift](https://github.com/ReactiveX/RxSwift) objects. as well as improving the logic around managing and handling accounts throughout the lifecycle of your app.

Firebase Authentication is a great way to support user authentication in your app easily. This library builds on top of that to simplify even further the process with pre-built algorithms that support registering, logging-in, linking accounts with other providers, and more.

## Installation

RxFireAuth is available via [Swift Package Manager](https://swift.org/package-manager). Versions older than 4.0.0 were also available on CocoaPods.

### Swift Package Manager

To install RxFireAuth in your project, add this repository as dependency using Xcode or add the following in your `Package.swift` file:

```swift
.package(url: "https://github.com/MrAsterisco/RxFireAuth", from: "<see GitHub releases>")
```

### CocoaPods

As of version 4.0.0, CocoaPods is no longer supported. No new updates will be released on CocoaPods.

### Latest Release

To find out the latest version, look at the Releases tab of this repository.

### Mac Catalyst Compatibility with Xcode 15.4

If you are targeting Mac Catalyst in an app that depends on Firebase (or depends on this library, which in turn depends on Firebase), you will encounter an issue that prevents building. The issue is described [here](https://github.com/firebase/firebase-ios-sdk/issues/12967) and there is no fix provided by either Firebase or Apple, at the moment.

At the time of writing, building on Xcode 15.3 or the latest beta of Xcode 16 solves the problem.

## Get Started

To get started with RxFireAuth, you can download the example project or dive right into the [documentation](https://mrasterisco.github.io/RxFireAuth/documentation/rxfireauth).

### Example Project

This library includes a sample project that shows how to implement all the functions of the library on both iOS and macOS.

To see it in action, follow these steps:

- Download this repository.
- Navigate to your [Firebase Console](https://console.firebase.google.com/) and create a new project (it's free!).
- Add two iOS apps with the following bundle identifiers: `io.mrasterisco.github.RxFireAuth-Example` and `io.mrasterisco.github.RxFireAuth-Example-macOS`. If you are not interested in both platforms, you can also add just one of the two.
- Download the `GoogleService-Info.plist` per each platform and place the first one _(iOS)_ under `Example/RxFireAuth` and the second one _(macOS)_ under `Example\RxFireAuth macOS`.
- In the Firebase Console, navigate to the Authentication tab and enable "Email/Password", "Anonymous", "Apple" and "Google".
- Open `RxFireAuth.xcodeproj` under the `Example-SwiftPM` folder.

**\*Note**: the Firebase Console does not support macOS apps, so you'll have to add the macOS version as an iOS app. Please also note that the Firebase SDK for macOS is not officially part of the Firebase product, but it is community supported. You can find further info [here](https://github.com/firebase/firebase-ios-sdk/blob/master/README.md).\*

**\*Note 2**: to test Sign in with Apple, you need a valid signing identity. If you don't have one now, you can turn off Sign in with Apple under the "Signing & Capabilities" tab of the Xcode project.\*

### References

The whole library is built around the `UserManagerType` protocol. The library provides the default implementation of it through the `UserManager` class, that you can instantiate directly or get through Dependency Injection.

### Configuration

RxFireAuth assumes that you have already gone through the [Get Started](https://firebase.google.com/docs/auth/ios/start) guide on the Firebase Authentication documentation website. This means that:

- You have already [created a new project](https://firebase.google.com/docs/ios/setup#create-firebase-project) in the [Firebase Console](https://console.firebase.google.com/).
- You have [registered your app's bundle identifier](https://firebase.google.com/docs/ios/setup#register-app) and
  [added the `GoogleService-Info.plist` file](https://firebase.google.com/docs/ios/setup#add-config-file).
- You have already configured the Firebase SDK at the app startup:
  -- iOS: you have already called `FirebaseApp.configure()` in your `application:didFinishLaunchingWithOptions:` function in the AppDelegate, [as described here](https://firebase.google.com/docs/ios/setup#initialize-firebase).
  -- macOS: you have already called `FirebaseApp.configure()` in your `awakeFromNib` function in the AppDelegate.
- You have already turned on and configured the authentication providers that you'd like to use in the Firebase Console.

_In your Podfile, you can omit the `Firebase/Auth` reference as it is already a dependency of this library and will be included automatically._

#### OAuth Providers

To support OAuth providers such as Google SignIn, you also have to add the following to your `AppDelegate`:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
  return self.userManager.loginHandler?.handle(url: url) ?? false
}
```

Or, if you're using the library on macOS, add the following to your `AppDelegate`:

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
  NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(AppDelegate.handleGetURLEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
}

@objc func handleGetURLEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
  let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue!
  let url = URL(string: urlString!)!
  _ = userManager.loginHandler?.handle(url: url)
}
```

You also have to register the redirect URL for your app in the `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>{{FIREBASE_REVERSED_CLIENT_ID}}</string>
    </array>
  </dict>
</array>
```

You can find your `FIREBASE_REVERSED_CLIENT_ID` in the `GoogleService-Info.plist` file.

## Features

RxFireAuth offers several ways to interact with Firebase Authentication in a simple and reactive way.

## Login

One of the things that RxFireAuth aims to simplify is the ability to build a Register/Login screen that works seamlessly for new and returning users, also considering the ability of Firebase to create [anonymous accounts](https://firebase.google.com/docs/auth/ios/anonymous-auth).

#### Anonymous Accounts Flow

Modern applications should always try to delay sign-in as long as possible. From Apple Human Interface Guidelines:

> Delay sign-in as long as possible. People often abandon apps when they're forced to sign in before doing anything useful. Give them a chance to familiarize themselves with your app before committing. For example, a live-streaming app could let people explore available content before signing in to stream something.

Anonymous Accounts are Firebase's way to support this situation: when you first launch the app, you create an anonymous account that can then be converted to a new account when the user is ready to sign-in. This works flawlessly for new accounts but has a few catches when dealing with returning users.

Consider the following situation:

- Mike is a new user of your app. Since you've strictly followed Apple's guidelines when Mike opens your app, he's taken directly to the main screen.
- All the data that Mike builds in your app is linked to an anonymous account that you have created automatically while starting the app for the first time.
- At some point, Mike decides to sign-in to sync his data with another device. He registers a new account with his email and a password.
- Everything's looking good until now with the normal Firebase SDK, **unless you're super into RxSwift and you want all the Firebase methods to be wrapped into Rx components; if that's the case, skip the next points and go directly to "Code Showcase" paragraph.**
- Now, Mike wants to use his shiny new account to sign-in into another device. He downloads the app once again and he finds himself on the Home screen.
- He goes directly into the Sign-in screen and enters his account credentials: at this point, using the Firebase SDK, you'll try to link the anonymous account that has been created while opening the app to Mike's credential, but you'll get an error saying that those credentials are already in use. **Here's where this library will help you: when logging-in, the `UserManager` class will automatically check if the specified credentials already exist and will use those to login; it'll also delete the anonymous account that is no longer needed and report everything back to you.**

##### Code Showcase

Use the following method to login using some credentials (for example `.password(email, password)`:

```swift
func login(
		with credentials: Credentials,
		updateUserDisplayName: Bool,
		allowMigration: Bool?,
		resetToAnonymousOnFailure: Bool
) -> Single<LoginDescriptor>
```

The `allowMigration` parameter is useful in the situation that we've just described: there is an anonymous account that has to be deleted and replaced with an existing account. When set to `nil`, the library will return a `Single` that emits the `UserError.migrationRequired` error to give your app the chance to ask the user what they'd like to do with the data they have in the anonymous account.

![Account Migration Alert](https://i.imgur.com/XRPhSUg.jpg)

When the user has made a choice, pass either `true` or `false` to get the same value circled back to your code after the sign in procedure completed successfully.

To support the migration, all sign in methods return an instance of `LoginDescriptor` which gives you the `allowMigration` parameter that you've passed, the User ID of the anonymous account, and the User ID of the account that is now logged-in. With this information, you can go ahead and migrate the data from the anonymous account to the newly logged-in account.

#### Sign-in with Authentication Providers

If you are thinking of providing alternative ways to login into your app, RxFireAuth's got you covered.

When signing in with an external provider, it is always good to just let the user sign in and then figure out later if this is their first time or not. Additionally, it is common practice to let people connect different providers along with their email and password credentials. _Giving people flexibility is always a good choice._

Let's use the same short story from before, but Mike is now going to use Sign in with Apple.

- On the first device, nothing changes: with the standard Firebase SDK, we can link the anonymous account with Mike's Apple ID.
- On the second device, two things will happen: first of all, Apple has a different flow for apps that have already used Sign-in with Apple; and this is not controllable by you, so if the user registers and then deletes their account in your app, they'll still get a different sign-in flow in the case they return to the app and Sign-in with Apple once again (further on this [here](https://forums.developer.apple.com/thread/119826)). Secondly, you'll have to handle various situations.

When using Sign-in with Apple _(or any other provider, including Google and email & password)_, you'll find yourself in one of these cases:

1. There is an anonymous user logged-in and the Apple ID is not linked with any existing account: that's fantastic! We'll just link the Apple ID with the anonymous user and we're done.
1. There is an anonymous user logged-in, but the Apple ID is already linked with another account: we'll have to go through the migration and then sign in to the existing account.
1. There is a normal user logged-in and the Apple ID is not linked with any other account: the user is trying to link their Apple ID with an existing account, let's go ahead and do that.
1. There is a normal user logged-in, but the Apple ID is already linked with another account: we'll throw an error because the user must choose what to do.
1. There is nobody logged-in and the Apple ID is either already linked or not: we'll sign into the existing or new account.

With RxFireAuth's `login` method, all of these cases are handled _automagically_ for you.

##### Code Showcase

**All of the possible cases** are handled automatically for you by calling:

```swift
func signInWithApple(in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
```

or

```swift
func signInWithGoogle(as clientId: String, in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
```

_These functions are available in implementations of `LoginProviderManagerType`, such as the `UserManager` class that we're already using._

You can use the `updateUserDisplayName` parameter to automatically set the Firebase User `displayName` property to the full name associated with the provider account. _Keep in mind that some providers, such as Apple, allow the user to change this information while signing in for the first time and may return it for new users only that have never signed into your app before._

> As of version 5.0.0, RxFireAuth uses [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) to support signing in with Google on all platforms. On iOS and Mac Catalyst, you can take advantage of the `GIDSignInButton` class in your UI by manually adding the dependency to your target.

This function will behave as the normal sign in, returning `UserError.migrationRequired`, if an anonymous account will have to be deleted and `allowMigration` is not set. When this happens, you can use the following function to continue signing in after having asked the user what they'd like to do:

```swift
func login(with credentials: Credentials, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
```

The login credentials are embedded in the `migrationRequired` error and, except for particular cases, you shouldn't need to inspect them.

## User Data

You can get the profile of the currently logged-in user by calling:

```swift
userManager.user
```

or by subscribing to:

```swift
userManager.autoupdatingUser
```

_This Observable will emit new values every time something on the user profile has changed._

Once signed in, you can inspect the authentication providers of the user by cycling through the `authenticationProviders` array of the `UserData` instance. For a list of the supported providers, see the `Provider` enum, in `LoginCredentials`.

## Authentication Confirmation

When performing sensitive actions, such as changing the user password, linking new authentication providers or deleting the user account, Firebase will require you to get a new refresh token by forcing the user to login again. RxFireAuth offers convenient methods to confirm the authentication using one the supported providers.

You can confirm the authentication using any credentials (eg. `.password(email, password)`) by invoking:

```swift
func confirmAuthentication(with loginCredentials: Credentials) -> Completable
```

Sign in with Apple:

```swift
func confirmAuthenticationWithApple(in viewController: UIViewController) -> Completable
```

or Google Sign In:

```swift
func confirmAuthenticationWithGoogle(as clientId: String, in viewController: UIViewController) -> Completable
```

## Password Reset

With version 6.2.0, RxFireAuth introduces a new method to reset the user password. You can call:

```swift
func resetPassword(for email: String) -> Completable
```

This method will send an email to the user with a link to reset their password. You can customize the email content, sender, and more in the Firebase Console.

## Documentation

**Always refer to the `UserManagerType` and `LoginProviderManagerType` protocols** in your code, because the `UserManager` implementation may introduce breaking changes over time even if the library major version hasn't changed.

These protocols are fully documented, as all of the involved structs and helper classes.

You can find the [autogenerated documentation here](https://mrasterisco.github.io/RxFireAuth/).

## Compatibility

RxFireAuth is compatible with **iOS** (including when targeting **Mac Catalyst**) and **macOS**.

RxFireAuth requires **iOS 13.0 or later** and **macOS 11 or later** and has the following shared dependencies:

- `Firebase/Auth` version 11.
- `JWTDecode` version 3.
- `RxSwift` version 6.
- `GoogleSignIn` version 7.

## Contributions

All contributions to expand the library are welcome. Fork the repo, make the changes you want, and open a Pull Request.

If you make changes to the codebase, I am not enforcing a coding style, but I may ask you to make changes based on how the rest of the library is made.

## Status

This library is under **active development**. It is used across multiple apps in Production.

Even if most of the APIs are pretty straightforward, **they may change in the future**; but you don't have to worry about that, because releases will follow [Semanting Versioning 2.0.0](https://semver.org).

## License

RxFireAuth is distributed under the MIT license. [See LICENSE](https://github.com/MrAsterisco/RxFireAuth/blob/master/LICENSE) for details.
