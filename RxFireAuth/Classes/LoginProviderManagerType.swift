//
//  LoginProviderManagerType.swift
//  AddAction
//
//  Created by Alessio Moiso on 13/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import RxSwift

#if os(macOS)
import AppKit
public typealias ViewController = NSViewController
#elseif os(iOS)
import UIKit
public typealias ViewController = UIViewController
#endif

/// This protocol defines the public API of the wrapper
/// around login providers, such as Sign in with Apple.
///
/// When using the library in your code always make sure to
/// reference this protocol instead of the default implementation `UserManager`,
/// as this protocol will always conform to Semantic Versioning.
public protocol LoginProviderManagerType {
  
  /// Sign in with Apple in the passed view controller.
  ///
  /// Before using this function, you must enable Sign in with Apple under the "Signing & Capabilities" tab of
  /// your target. Also, you must turn on Sign in with Apple in your Firebase Console, if you haven't already.
  ///
  /// The Sign in with Apple flow will be different for new users and returning users; as a result, in the latter case, the library
  /// will not be able to retrieve the user's display name, as Apple does not provide this information for returning users.
  /// Keep in mind that the account you are creating using this function will be linked to the user's Apple ID, but that link
  /// will only work in one direction: from Apple to Firebase; if you delete the Firebase account, the user will still find your app
  /// in their Apple ID settings, under "Apps Using Your Apple ID".
  ///
  /// To use Sign in with Apple, your app must comply with specific terms. We strongly suggest you to review them before
  /// starting the implementation: you can find those on the [Apple Developer Portal](https://developer.apple.com/sign-in-with-apple/).
  /// Additionally, if your app also provides the option to sign in/sign up with another provider (such as Google) and you're targeting the public App Store,
  /// [you must also support Sign in with Apple](https://developer.apple.com/app-store/review/guidelines/#sign-in-with-apple).
  ///
  /// - parameters:
  ///     - viewController: The view controller over which the Sign in with Apple UI should be displayed.
  ///     - updateUserDisplayName: If set to `true`, a successful login will also update the user `displayName` field using information from the associated Apple ID.
  ///     - allowMigration: An optional boolean that defines the behavior in case there is an anonymous user logged-in and the user is trying to login in an existing account. This option will be passed back to the caller
  ///     in the resulting `LoginDescriptor.performMigration`; if set to `nil`, the operation will not proceed and a `UserError.migrationRequired` error will be thrown.
  /// - returns: A Single that emits errors or a `LoginDescriptor` instance.
  @available(iOS 13.0, macOS 10.15, *)
  func signInWithApple(in viewController: ViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
  
  /// Confirm the authentication of the currently signed in user with Sign in with Apple.
  ///
  /// You can use this function to renew the user authentication in order to perform sensitive actions such as
  /// updating the password or deleting the account. This function will emit an error if the user does not have
  /// Sign in with Apple among their authentication providers.
  ///
  /// - since: version 1.5.0
  ///
  /// - parameters:
  ///     - viewController: The view controller over which the Sign in with Apple UI should be displayed.
  /// - returns: A Completable action to observe.
  @available(iOS 13.0, macOS 10.15, *)
  func confirmAuthenticationWithApple(in viewController: ViewController) -> Completable
  
  /// Sign in with Google in the passed view controller.
  ///
  /// Google Sign In works by opening a Safari view over the specified view controller. At some point,
  /// a redirect will happen and will be sent to your AppDelegate or SceneDelegate: when it does, you must forward
  /// the URL by calling `loginHandler.handle(url:)` on your `UserManagerType` instance.
  ///
  /// - since: version 1.5.0
  ///
  /// - parameters:
  ///     - clientId: Google client ID, generally obtainable using `FirebaseApp.app()!.options.clientID`.
  ///     - viewController: The view controller over which the Google Sign-in UI should be displayed.
  ///     - updateUserDisplayName: If set to `true`, a successful login will also update the user `displayName` field using information from the associated Google Account.
  ///     - allowMigration: An optional boolean that defines the behavior in case there is an anonymous user logged-in and the user is trying to login in an existing account. This option will be passed back to the caller
  ///     in the resulting `LoginDescriptor.performMigration`; if set to `nil`, the operation will not proceed and a `UserError.migrationRequired` error will be thrown.
  /// - returns: A Single that emits errors or a `LoginDescriptor` instance.
  func signInWithGoogle(as clientId: String, in viewController: ViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
  
  /// Confirm the authentication of the currently logged-in user with Google Sign-in.
  ///
  /// You can use this function to renew the user authentication in order to perform sensitive actions such as
  /// updating the password or deleting the account. This function will emit an error if the user does not have
  /// Google Sign In among their authentication providers.
  ///
  /// - since: version 1.5.0
  ///
  /// - parameters:
  ///     - clientId: Google client ID, generally obtainable using `FirebaseApp.app()!.options.clientID`.
  ///     - viewController: The view controller over which the Google Sign-in UI should be displayed.
  /// - returns: A Completable action to observe.
  func confirmAuthenticationWithGoogle(as clientId: String, in viewController: ViewController) -> Completable
  
}
