//
//  UserManagerType.swift
//  Redirekt
//
//  Created by Alessio Moiso on 13/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import UIKit
import RxSwift

public protocol UserManagerType {
    
    /// Get if there is a currently logged-in user.
    var isLoggedIn: Bool { get }
    
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
    
    /// Logout the currently logged-in user.
    ///
    /// - parameters:
    ///     - resetToAnonymous: If true, after having logged-out successfully, this function will immediately sign in a new anonymous user.
    /// - returns: A Completable action to observe.
    func logout(resetToAnonymous: Bool) -> Completable
    
    /// Update the currently logged-in user taking new values from the
    /// passed object.
    ///
    /// - note: This function will not update the user email address, even if it has changed.
    ///
    /// - parameters:
    ///     - user: A user to gather new values from.
    /// - returns: A Completable action to observe.
    func update(user: UserData) -> Completable
    
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
