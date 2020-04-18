# RxFireAuth

[![CI Status](https://img.shields.io/travis/mrasterisco/RxFireAuth.svg?style=flat)](https://travis-ci.org/mrasterisco/RxFireAuth)
[![Version](https://img.shields.io/cocoapods/v/RxFireAuth.svg?style=flat)](https://cocoapods.org/pods/RxFireAuth)
[![License](https://img.shields.io/cocoapods/l/RxFireAuth.svg?style=flat)](https://cocoapods.org/pods/RxFireAuth)
[![Platform](https://img.shields.io/cocoapods/p/RxFireAuth.svg?style=flat)](https://cocoapods.org/pods/RxFireAuth)

RxFireAuth is a wrapper around the [Firebase Authentication](https://firebase.google.com/docs/auth) SDK that exposes the most common use cases through [RxSwift](https://github.com/ReactiveX/RxSwift) objects.

Firebase Authentication is a great way to support user authentication in your app easily. This library builds on top of that to simplify even further the process with pre-built algorithms that support registering, logging-in, linking accounts with other providers and more.

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

### Login
One of the things that RxFireAuth aims to simplify is the ability to build a Register/Login screen that works seamlessly for new and returning users, also considering the ability of Firebase to create anonymous accounts.

#### Anonymous Accounts Flow
Modern applications should always try to delay sign-in as long as possible. From Apple Human Interface Guidelines:

> Delay sign-in as long as possible. People often abandon apps when they're forced to sign in before doing anything useful. Give them a chance to familiarize themselves with your app before making a commitment. For example, a live-streaming app could let people explore available content before signing in to stream something.

Anonymous Accounts are Firebase's way to support this situation: when you first launch the app, you create an anonymous account that can then be converted to a new account when the user is ready to actually sign-in. This works flawlessly for new accounts, but has a few catches when dealing with returning users.

Consider the following situation:

- Mike is a new user of your app. Since you've strictly followed Apple's guidelines, when Mike opens your app, he's taken directly to the main screen.
- All the data that Mike builds in your app is linked to an anonymous account that you have created automatically while starting the app for the first time.
- At some point, Mike decides to sign-in in order to sync his data with another device. He registers a new account with his email and a password.
- Everything's looking good until now with the normal Firebase SDK, **unless you're super into RxSwift and you want all the Firebase methods to be wrapped into Rx components; if that's the case, skip the next points and go directly to "Code Showcase" paragraph.**
- Now, Mike wants to use his shiny new account to sign-in into another device. He downloads the app once again and he finds himself on the Home screen. 
- He goes directly into the Sign-in screen and enters his account credentials: at this point, using the Firebase SDK, you'll try to link the anonymous account that has been created while opening the app to Mike's credential, but you'll get an error saying that those credentials are already in use. **Here's where this library will help you: when logging-in, the `UserManager` class will automatically check if the specified credentials already exist and will use those to login; it'll also delete the anonymous account that is no longer needed.**

##### Code Showcase
Assuming that you have an instance of the `UserManager` class, use the following method to login using an email and a password:

```swift
func login(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor>
```

The `allowMigration` parameter is useful in the situation that we've just described: there is an anonymous account that has to be deleted and replaced with an existing account. When set to `nil`, the library will return a `Single` that emits the `UserError.migrationRequired` error to give your app the chance to ask the user what they'd like to do with the data they have in the anonymous account.

![Account Migration Alert](https://i.imgur.com/XRPhSUg.jpg)

When the user has made a choice, pass either `true` or `false` to get the same value circled back to your code after the login procedure has completed successfully.

To support the migration, all login methods return an instance of `LoginDescriptor` which gives you the `allowMigration` parameter that you've passed, the User ID of the anonymous account and the User ID of the account that is now logged-in. With this information, you can go ahead and migrate the data from the anonymous account to the newly logged-in account.

#### Sign-in with Apple
If you are thinking of providing alternatives ways to login into your app, you have to consider Sign-in with Apple as an option, *[mainly because you have to](https://developer.apple.com/app-store/review/guidelines/#4.8), but also because it provides a great experience for people using your app in the Apple ecosystem*.

When signing in with an external provider, it is always good to just let the user sign-in and then figure out later if this is their first time or not. Additionally, it is common practice to let people connect different providers along with their email and password credentials. Giving people flexibility is always a good choice.

Let's use the same short story from before, but Mike is now going to use Sign-in with Apple.

- On the first device, nothing changes: with the standard Firebase SDK, we can link the anonymous account with Mike's Apple ID.
- On the second device, a lot of different things will happen: first of all, Apple has a different flow for apps that have already used Sign-in with Apple; this means that if the user registers and then deletes their account in your app, they'll still get a different sign-in flow in the case they return to the app and Sign-in with Apple once again (further on this [here](https://forums.developer.apple.com/thread/119826)). Secondly, you'll have to handle a lot of different cases.

When using Sign-in with Apple *(or any other provider, such as Google or Facebook)*, the following situations may apply:

- There is an anonymous user logged-in and the Apple ID is not linked with any existing account: that's fantastic! We'll just link the Apple ID with the anonymous user and we're done.
- There is an anonymous user logged-in, but the Apple ID is already linked with another account: we'll have to go through the migration and then login into the existing account.
- There is a normal user logged-in and the Apple ID is not already linked with another account: the user is trying to link their Apple ID with an existing account, let's go ahead and do that.
- There is a normal user logged-in, but the Apple ID is already linked with another account: we'll throw an error, because the user has to choose what to do.
- There is nobody logged-in and the Apple ID is either already linked or not: we'll sign in into the existing or new account.

##### Code Showcase

**All of these cases** are handled automatically for you by calling:

```swift
func signInWithApple(in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
```

*This function is available in implementations of `LoginProviderManagerType`, such as the `UserManager` class that we're already using.*

You can use the `updateUserDisplayName` parameter to automatically set the Firebase User `displayName` property to the full name associated to the Apple ID. *Keep in mind that the user can change this information while signing-in with Apple for the first time.*

This function will behave as the normal login, returning `UserError.migrationRequired`, if an anonymous account is going to be deleted and `allowMigration` is not set.

#### Standard Flow
If you don't want to support the anonymous authentication, you can use this library anyway as all of the methods are built to work even when no account is logged-in.

### Other Functions
The library wraps most of the Firebase Authentication SDK methods. If you can't find the method you need, feel free to open an issue or build a PR yourself.

**TODO**

## Contributions
All contributions to expand the library are welcome. Fork the repo, make the changes you want and open a Pull Request.

## Status
This library is under **active development**. Even if most of the APIs are pretty straightforward, **they may change in the future**; releases will follow [Semanting Versioning 2.0.0](https://semver.org).

## License
RxFireAuth is distributed under the MIT license. [See LICENSE](https://github.com/MrAsterisco/RxFireAuth/blob/master/LICENSE) for details.


