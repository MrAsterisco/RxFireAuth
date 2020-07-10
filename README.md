# RxFireAuth

[![Version](https://img.shields.io/cocoapods/v/RxFireAuth.svg?style=flat)](https://cocoapods.org/pods/RxFireAuth)
[![License](https://img.shields.io/cocoapods/l/RxFireAuth.svg?style=flat)](https://cocoapods.org/pods/RxFireAuth)
[![Platform](https://img.shields.io/cocoapods/p/RxFireAuth.svg?style=flat)](https://cocoapods.org/pods/RxFireAuth)

RxFireAuth is a wrapper around the [Firebase Authentication](https://firebase.google.com/docs/auth) SDK that exposes most of the available functions through [RxSwift](https://github.com/ReactiveX/RxSwift) objects. as well as improving the logic around managing and handling accounts throughout the lifecycle of your app.

Firebase Authentication is a great way to support user authentication in your app easily. This library builds on top of that to simplify even further the process with pre-built algorithms that support registering, logging-in, linking accounts with other providers, and more.

Looking for the Android version? You can find it [right here](https://github.com/MrAsterisco/RxFireAuth-Android).

## Installation

RxFireAuth is available through [CocoaPods](https://cocoapods.org). We don't support other package managers at the moment, mainly because the Firebase SDK is available through CocoaPods only.

To install RxFireAuth in your project add:

```ruby
pod 'RxFireAuth'
```

To find out the latest version, look at the Releases tab of this repository.

## Get Started
To get started with RxFireAuth, you can download the example project or dive right into the [documentation](https://mrasterisco.github.io/RxFireAuth/).

## Example Project
This library includes a sample project that shows how to support a user log in, including anonymous accounts.

To see it in action, follow these steps:

- Download this repository.
- Navigate to your [Firebase Console](https://console.firebase.google.com/) and create a new project using `io.mrasterisco.github.RxFireAuth-Example` as bundle identifier *(or change the bundle identifier to match the one of a project you already have)*.
- Download the `GoogleService-Info.plist` and place it in the `Example/RxFireAuth` folder.
- In the Firebase Console, navigate to Authentication and enable the "Email/Password", "Anonymous" and "Apple" sign-in methods.
- Run `pod install` inside the `Example` folder.
- Open the `RxFireAuth.xcworkspace`, select a valid Signing Identity, build and run.

*To test Sign in with Apple, you need a valid signing identity. If you don't have one now, you can turn off Sign in with Apple under the "Signing & Capabilities" tab of the Xcode project.*

## Usage
The whole library is built around the `UserManagerType` protocol. The library provides the default implementation of it through the `UserManager` class, that you can instantiate directly or get through Dependency Injection.

### Configuration
RxFireAuth assumes that you have already gone through the [Get Started](https://firebase.google.com/docs/auth/ios/start) guide on the Firebase Authentication documentation website. This means that:

- You have already [created a new project](https://firebase.google.com/docs/ios/setup#create-firebase-project) in the [Firebase Console](https://console.firebase.google.com/).
- You have [registered your app's bundle identifier](https://firebase.google.com/docs/ios/setup#register-app) and
[added the `GoogleService-Info.plist` file](https://firebase.google.com/docs/ios/setup#add-config-file).
- You have already called `FirebaseApp.configure()` in your `application:didFinishLaunchingWithOptions:` function in the AppDelegate, [as described here](https://firebase.google.com/docs/ios/setup#initialize-firebase).
- You have already turned on and configured the authentication providers that you'd like to use in the Firebase Console.

*In your Podfile, you can omit the `Firebase/Auth` reference as it is already a dependency of this library and will be included automatically.*

To support OAuth providers (such as Google Sign-in), add the following method into your `AppDelegate`:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return self.userManager.loginHandler?.handle(url: url) ?? false
}
```

### Login
One of the things that RxFireAuth aims to simplify is the ability to build a Register/Login screen that works seamlessly for new and returning users, also considering the ability of Firebase to create anonymous accounts.

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
- He goes directly into the Sign-in screen and enters his account credentials: at this point, using the Firebase SDK, you'll try to link the anonymous account that has been created while opening the app to Mike's credential, but you'll get an error saying that those credentials are already in use. **Here's where this library will help you: when logging-in, the `UserManager` class will automatically check if the specified credentials already exist and will use those to login; it'll also delete the anonymous account that is no longer needed.**

##### Code Showcase
Use the following method to login using an email and a password:

```swift
func login(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor>
```

The `allowMigration` parameter is useful in the situation that we've just described: there is an anonymous account that has to be deleted and replaced with an existing account. When set to `nil`, the library will return a `Single` that emits the `UserError.migrationRequired` error to give your app the chance to ask the user what they'd like to do with the data they have in the anonymous account.

![Account Migration Alert](https://i.imgur.com/XRPhSUg.jpg)

When the user has made a choice, pass either `true` or `false` to get the same value circled back to your code after the login procedure has completed successfully.

To support the migration, all login methods return an instance of `LoginDescriptor` which gives you the `allowMigration` parameter that you've passed, the User ID of the anonymous account, and the User ID of the account that is now logged-in. With this information, you can go ahead and migrate the data from the anonymous account to the newly logged-in account.

#### Sign-in with Login Providers
If you are thinking of providing alternatives ways to login into your app, RxFireAuth's got you covered.

When signing in with an external provider, it is always good to just let the user sign-in and then figure out later if this is their first time or not. Additionally, it is common practice to let people connect different providers along with their email and password credentials. *Giving people flexibility is always a good choice.*

Let's use the same short story from before, but Mike is now going to use Sign-in with Apple.

- On the first device, nothing changes: with the standard Firebase SDK, we can link the anonymous account with Mike's Apple ID.
- On the second device, two things will happen: first of all, Apple has a different flow for apps that have already used Sign-in with Apple; and this is not controllable by you, so if the user registers and then deletes their account in your app, they'll still get a different sign-in flow in the case they return to the app and Sign-in with Apple once again (further on this [here](https://forums.developer.apple.com/thread/119826)). Secondly, you'll have to handle various cases.

When using Sign-in with Apple *(or any other provider, such as Google)*, you'll find yourself in one of these cases:

- There is an anonymous user logged-in and the Apple ID is not linked with any existing account: that's fantastic! We'll just link the Apple ID with the anonymous user and we're done.
- There is an anonymous user logged-in, but the Apple ID is already linked with another account: we'll have to go through the migration and then log in to the existing account.
- There is a normal user logged-in and the Apple ID is not already linked with another account: the user is trying to link their Apple ID with an existing account, let's go ahead and do that.
- There is a normal user logged-in, but the Apple ID is already linked with another account: we'll throw an error because the user has to choose what to do.
- There is nobody logged-in and the Apple ID is either already linked or not: we'll sign in into the existing or new account.

##### Code Showcase

**All of these cases** are handled automatically for you by calling:

```swift
func signInWithApple(in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
```
or

```swift
func signInWithGoogle(as clientId: String, in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
```

*These functions are available in implementations of `LoginProviderManagerType`, such as the `UserManager` class that we're already using.*

You can use the `updateUserDisplayName` parameter to automatically set the Firebase User `displayName` property to the full name associated with the provider account. *Keep in mind that some providers, such as Apple, allow the user to change this information while signing-in for the first time.*

This function will behave as the normal login, returning `UserError.migrationRequired`, if an anonymous account is going to be deleted and `allowMigration` is not set. When this happens, you can use the following function to continue signing-in after having asked the user what they would like to do:

```swift
func login(with credentials: LoginCredentials, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
```
The login credentials are embedded in the `migrationRequired` error and, except for particular cases, you shouldn't need to inspect them.

#### Standard Flow
If you don't want to support the anonymous authentication, you can use this library anyway as all of the methods are built to work even when no account is logged-in.

You can make explicit calls to:

```swift
func register(email: String, password: String) -> Completable
```

and to:

```swift
func loginWithoutChecking(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor>
```

and also to:

```swift
func linkAnonymousAccount(toEmail email: String, password: String) -> Completable
```

These methods will bypass the logic around anonymous and existing/non-existing accounts and will let you use the bare Firebase SDK through RxSwift.

## Documentation
**Always refer to the `UserManagerType` and `LoginProviderManagerType` protocols** in your code, because the `UserManager` implementation may introduce breaking changes over time even if the library major version hasn't changed.

These protocols are fully documented, as all of the involved structs and helper classes.

You can find the [autogenerated documentation here](https://mrasterisco.github.io/RxFireAuth/).

## Compatibility
RxFireAuth targets **iOS 9.0 or later** and has the following dependencies:

- `Firebase/Auth` version 6.5.
- `GoogleSignIn` version 5.0.2.
- `JWTDecode` version 2.4.
- `RxCocoa` version 5.

Compatibility with macOS is **planned**. Don't hesitate to open an issue to prioritize it.

## Contributions
All contributions to expand the library are welcome. Fork the repo, make the changes you want, and open a Pull Request.

If you make changes to the codebase, I am not enforcing a coding style, but I may ask you to make changes based on how the rest of the library is made.

## Status
This library is under **active development** and it can be considered stable enough to be used in Production. 

Even if most of the APIs are pretty straightforward, **they may change in the future**; but you don't have to worry about that, because releases will follow [Semanting Versioning 2.0.0](https://semver.org).

## License
RxFireAuth is distributed under the MIT license. [See LICENSE](https://github.com/MrAsterisco/RxFireAuth/blob/master/LICENSE) for details.


