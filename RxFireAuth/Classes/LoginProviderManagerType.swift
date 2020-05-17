//
//  LoginProviderManagerType.swift
//  AddAction
//
//  Created by Alessio Moiso on 13/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import RxSwift

/// This protocol defines the public API of the wrapper
/// around login providers, such as Sign in with Apple.
///
/// When using the library in your code always make sure to
/// reference this protocol instead of the default implementation `UserManager`,
/// as this protocol will always conform to Semantic Versioning.
public protocol LoginProviderManagerType {

    /// Sign in with Apple in the passed view controller.
    ///
    /// - parameters:
    ///     - viewController: The view controller over which the Sign in with Apple UI should be displayed.
    ///     - updateUserDisplayName: If set to `true`, a successful login will also update the user `displayName` field using information from the associated Apple ID.
    ///     - allowMigration: An optional boolean that defines the behavior in case there is an anonymous user logged-in and the user is trying to login in an existing account. This option will be passed back to the caller
    ///     in the resulting `LoginDescriptor.performMigration`; if set to `nil`, the operation will not proceed and a `UserError.migrationRequired` error will be thrown.
    /// - returns: A Single that emits errors or a `LoginDescriptor` instance.
    @available(iOS 13.0, *)
    func signInWithApple(in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
    
    /// Confirm the authentication of the currently logged-in user with Sign in with Apple.
    ///
    /// You can use this function to renew the user authentication in order to perform sensitive actions such as
    /// updating the password or deleting the account. This function will emit an error if the user does not have
    /// Sign in with Apple among their login providers.
    ///
    /// - since: version 1.5.0
    ///
    /// - parameters:
    ///     - viewController: The view controller over which the Sign in with Apple UI should be displayed.
    /// - returns: A Completable action to observe.
    @available(iOS 13.0, *)
    func confirmAuthenticationWithApple(in viewController: UIViewController) -> Completable
    
    /// Sign in with Google in the passed view controller.
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
    func signInWithGoogle(as clientId: String, in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
    
    /// Confirm the authentication of the currently logged-in user with Google Sign-in.
    ///
    /// You can use this function to renew the user authentication in order to perform sensitive actions such as
    /// updating the password or deleting the account. This function will emit an error if the user does not have
    /// Google among their login providers.
    ///
    /// - since: version 1.5.0
    ///
    /// - parameters:
    ///     - clientId: Google client ID, generally obtainable using `FirebaseApp.app()!.options.clientID`.
    ///     - viewController: The view controller over which the Google Sign-in UI should be displayed.
    /// - returns: A Completable action to observe.
    func confirmAuthenticationWithGoogle(as clientId: String, in viewController: UIViewController) -> Completable
    
}
