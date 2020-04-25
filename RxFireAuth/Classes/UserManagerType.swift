//
//  UserManagerType.swift
//  Redirekt
//
//  Created by Alessio Moiso on 13/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import UIKit
import RxSwift

/// This protocol defines the public API of the main
/// wrapper around Firebase Authentication SDK.
///
/// When using the library in your code always make sure to
/// reference this protocol instead of the default implementation `UserManager`,
/// as this protocol will always conform to Semantic Versioning.
///
/// All methods of this protocol are wrapped inside a Rx object that
/// will not execute any code until somebody subscribes to it.
public protocol UserManagerType {
    
    /// Get if there is a currently logged-in user.
    var isLoggedIn: Bool { get }
    
    /// Get if there is an anonymous user logged-in.
    var isAnonymous: Bool { get }
    
    /// Get the currently logged-in user or nil if no user is logged-in.
    var user: UserData? { get }
    
    /// Get an Observable that emits a new item every time the logged-in user is updated.
    var autoupdatingUser: Observable<UserData?> { get }
    
    /// Verify if an account exists on the server with the passed email address.
    ///
    /// - parameters:
    ///     - email: The account email address.
    /// - returns: A Single that completes with the result of the query on the backend.
    func accountExists(with email: String) -> Single<Bool>
    
    /// Register a new account on the server with the passed email and credentials.
    ///
    /// - note: This function will return `UserError.alreadyLoggedIn` if there is already
    ///         a non-anonymous user logged-in. If the logged-in user is anonymous, this function
    ///         will call `self.linkAnonymousAccount` and return that value.
    ///
    /// - parameters:
    ///     - email: The user email address.
    ///     - password: The user password.
    /// - returns: A Completable action to observe.
    func register(email: String, password: String) -> Completable
    
    /// Login an anonymous user on the app.
    ///
    /// - note: You can use this method to create an anonymous user on the server.
    ///
    /// - returns: A Completable action to observe.
    func loginAnonymously() -> Completable
    
    /// Convert an anonymous user to a normal user with an email and a password.
    ///
    /// - note: This function will return `UserError.noUser` if the currently logged-in user does not exists
    ///         or is not anonymous.
    /// - parameters:
    ///     - email: The user email address.
    ///     - password: The user password.
    /// - returns: A Completable action to observe.
    func linkAnonymousAccount(toEmail email: String, password: String) -> Completable
    
    /// Login the specified user on the app.
    ///
    /// - note: This function will return `UserError.alreadyLoggedIn` if there is already
    ///         a non-anonymous user logged-in.
    ///
    /// - parameters:
    ///     - email: The user email address.
    ///     - password: The user password.
    ///     - allowMigration: An optional boolean that defines the behavior in case there is an anonymous user logged-in and the user is trying to login in an existing account. This option will be passed back to the caller
    ///     in the resulting `LoginDescriptor.performMigration`; if set to `nil`, the operation will not proceed and a `UserError.migrationRequired` error will be thrown.
    /// - returns: A Single that emits errors or a `LoginDescriptor` instance.
    func login(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor>
    
    /// Sign in with the passed credentials without first checking if an account
    /// with the specified email address exists on the backend.
    ///
    /// - parameters:
    ///     - email: An email address.
    ///     - password: A password.
    /// - returns: A Single to observe for result.
    func loginWithoutChecking(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor>
    
    /// Sign in with the passed credentials on a provider.
    ///
    /// Use this function to sign in with a provider credentials. In a normal flow,
    /// you'll use this function with credentials obtained by one of the `signInWith…` methods
    /// provided by implementations of `LoginProviderManagerType`.
    func login(with credentials: LoginCredentials, allowMigration: Bool?) -> Single<LoginDescriptor>
    
    /// Logout the currently logged-in user.
    ///
    /// Using the `resetToAnonymous` parameter, you can make sure
    /// that there is always a user signed in.
    ///
    /// - parameters:
    ///     - resetToAnonymous: If `true`, after having logged-out successfully, this function will immediately sign in a new anonymous user.
    /// - throws:
    /// - returns: A Completable action to observe.
    func logout(resetToAnonymous: Bool) -> Completable
    
    /// Update the currently logged-in user taking new values from the
    /// passed object.
    ///
    /// You cannot instantiate a `UserData` instance directly. To pass the parameter to this function,
    /// use a value retrieved from `self.user` or `self.autoupdatingUser`. To simplify this even
    /// further, use `self.update(userConfigurationHandler:)`.
    ///
    /// - note: This function will not update the user email address, even if it has changed.
    ///
    /// - seealso: self.update(userConfigurationHandler:)
    /// - parameters:
    ///     - user: A user to gather new values from.
    /// - returns: A Completable action to observe.
    func update(user: UserData) -> Completable
    
    /// Retrieve the currently logged-in user and use the specified
    /// configuration handler to update its properties.
    ///
    /// - note: This function is only a wrapper that takes the first value of `self.autoupdatingUser`,
    ///   maps it by calling the `userConfigurationHandler` and passes it to `self.update(user:)`.
    ///
    /// - since: version 1.1.0
    ///
    /// - parameters:
    ///     - userConfigurationHandler: A function that takes a `UserData` instance and returns it with the required changes.
    /// - returns: A Completable action to observe.
    func update(userConfigurationHandler: @escaping (UserData) -> UserData) -> Completable
    
    /// Update the email of the currently logged-in user.
    ///
    /// - parameters:
    ///     - newEmail: The new email address.
    /// - returns: A Completable action to observe.
    func updateEmail(newEmail: String) -> Completable
    
    /// Confirm the authentication of the passed credentials with the currently logged-in user.
    ///
    /// - parameters:
    ///     - email: The user email address.
    ///     - password: The user password.
    /// - returns: A Completable action to observe.
    func confirmAuthentication(email: String, password: String) -> Completable
    
}
