//
//  UserManagerType.swift
//  Redirekt
//
//  Created by Alessio Moiso on 13/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import RxSwift

/// This protocol defines the public APIs of the main
/// wrapper around the Firebase Authentication SDK.
///
/// When using the library in your code always make sure to
/// reference this protocol instead of the default implementation `UserManager`,
/// as this protocol will always conform to Semantic Versioning.
///
/// All reactive methods of this protocol are wrapped inside a Rx object that
/// will not execute any code until somebody subscribes to it.
public protocol UserManagerType {
  /// Get the current login handler.
  ///
  /// This property holds a reference to the handler that is being used
  /// during a login operation with multiple steps (such as Sign in with Apple).
  var loginHandler: LoginHandlerType? { get }
  
  /// Get if there is a currently logged-in user.
  ///
  /// This property will be `false` even if there is a currently logged-in user,
  /// but it is anonymous.
  var isLoggedIn: Bool { get }
  
  /// Get if there is an anonymous user logged-in.
  var isAnonymous: Bool { get }
  
  /// Get the currently logged-in user or `nil` if no user is logged-in.
	///
	/// - note: Use ``autoupdatingUser`` if you need to observe changes
	/// to the logged-in user.
  var user: UserData? { get }
  
  /// Get an Observable that emits a new item every time the logged-in user changes
	/// or is updated.
  var autoupdatingUser: Observable<UserData?> { get }
  
  /// Get the current access token for the logged-in user.
  ///
  /// You can use values from this Observable to authenticate with your backend.
  /// This function will cause a refresh of the access token if the stored one is expired.
  ///
  /// - warning: The access token should be treated as sensitive information.
  /// - since: version 2.0.0
  var accessToken: Single<String?> { get }
	
	// MARK: - Login
  
  /// Login with an anonymous user.
  ///
  /// - note: You can use this method to create an anonymous user on the server.
  ///
  /// - note: The resulting Completable will emit `UserError.alreadyLoggedIn` if there
  ///         is already a non-anonymous user logged-in. It will also emit `UserError.alreadyAnonymous`
  ///         if there is already an anonymous user logged-in.
  ///
  /// - returns: A Completable action to observe.
  func loginAnonymously() -> Completable
  
  /// Login the user with the specified email address using the specified password.
  ///
  /// - note: This function will return `UserError.alreadyLoggedIn` if there is already
  ///         a non-anonymous user logged-in.
	///
	/// - note: 	This function is a shorthand for
	///        	calling ``login(with:updateUserDisplayName:allowMigration:resetToAnonymousOnFailure:)`` passing
	/// 				``Credentials.password``.
	///
	/// - seealso: ``login(with:updateUserDisplayName:allowMigration:resetToAnonymousOnFailure:)``.
  ///
  /// - parameters:
  ///     - email: The user email address.
  ///     - password: The user password.
  ///     - allowMigration: An optional boolean that defines the behavior in case there is an anonymous user logged-in 
	///     							and the user is trying to login into an existing account. This option will be passed back to the caller
  ///     							in the resulting `LoginDescriptor.performMigration`;
	///     							if set to `nil`, the operation will not proceed and a `UserError.migrationRequired` error will be emitted by the Single.
	///     - resetToAnonymousOnFailure: 	If `true`, this function will call `loginAnonymously()` if the login operation fails.
	///     													This only applies to password-based authentication when linking an existing account
	///     													to an anonymous one. It will be invoked when the provided credentials are invalid.
	///     													A migration will always be required in this case, because the previous anonymous account will be lost.
  /// - returns: A Single that emits errors or a `LoginDescriptor` instance.
	@available(*, deprecated, renamed: "login(with:updateUserDisplayName:allowMigration:resetToAnonymousOnFailure:)", message: "Invoke the generic login function passing `Credentials.password`.")
	func login(
		email: String,
		password: String,
		allowMigration: Bool?,
		resetToAnonymousOnFailure: Bool
	) -> Single<LoginDescriptor>
	
  /// Login the user with the specified credentials.
	///
  /// - since: version 6.0.0
	///
	/// - note: This function will fail when attempting to login with `Credentials.password` on an account that has no password set.
  ///
  /// - parameters:
  ///     - credentials: Credentials to use to login.
  ///     - updateUserDisplayName: 	If the passed credentials result in a successful login and this is set to `true`,
	///     												this function will attempt to update the user display name
	///     												by reading it from the resulting `LoginDescriptor`.
  ///     - allowMigration: 	An optional boolean that defines the behavior in case
	///     								there is an anonymous user logged-in and the user
	///     								is trying to login into an existing account.
	///     								This option will be passed back to the caller in the
	///     								resulting `LoginDescriptor.performMigration`;
	///     								if set to `nil`, the operation will not proceed and a `UserError.migrationRequired`
	///     								error will be emitted instead.
	///     - resetToAnonymousOnFailure: 	If `true`, this function will call `loginAnonymously()`
	///     													if the login operation fails. This only applies to password-based
	///     													authentication when linking an existing
	///     													account to an anonymous one. It will be invoked
	///     													when the provided credentials are invalid.
	///     													A migration will always be required in this case,
	///     													because the previous anonymous account will be lost.
  /// - returns: A Single to observe for results.
	func login(
		with credentials: Credentials,
		updateUserDisplayName: Bool,
		allowMigration: Bool?,
		resetToAnonymousOnFailure: Bool
	) -> Single<LoginDescriptor>
  
  /// Sign out the currently logged-in user.
  ///
  /// Using the `resetToAnonymous` parameter, you can make sure
  /// that there is always a user signed in: if the parameter is set to `true`, this
  /// function will call ``loginAnonymously()`` immediately after the logout operation has completed.
  ///
  /// - parameters:
  ///     - resetToAnonymous: If `true`, after having logged-out successfully, this function will immediately sign in a new anonymous user.
  /// - returns: A Completable action to observe.
  func logout(resetToAnonymous: Bool) -> Completable
	
	// MARK: - Manual Registration
	
	/// Register a new account on the server with the passed email and password.
	///
	/// - note: The resulting Completable will emit `UserError.alreadyLoggedIn` if there is already
	///         a non-anonymous user logged-in. If the logged-in user is anonymous, this function
	///         will call `self.linkAnonymousAccount` and return that value.
	///
	/// - note: After registering, the new user will become the currently logged-in user
	///         automatically.
	///
	/// - parameters:
	///     - email: The user email address.
	///     - password: The user password.
	/// - returns: A Completable action to observe.
	func register(email: String, password: String) -> Completable
	
	// MARK: - Manual Linking
	
	/// Convert an anonymous user to a user with a email and a password.
	///
	/// - note: This function is a shorthand for calling ``linkAnonymousAccount(to:)`` passing ``Credentials.password``.
	///
	/// - parameters:
	///     - email: The user email address.
	///     - password: The user password.
	/// - returns: A Completable action to observe.
	@available(*, deprecated, renamed: "linkAnonymousAccount(to:)", message: "Invoke the generic link function passing `Credentials.password`.")
	func linkAnonymousAccount(toEmail email: String, password: String) -> Completable
	
	/// Convert an anonymous account to an account that can login with the passed credentials.
	///
	/// - note: This function will fail if the passed credentials are already associated with another account.
	/// 				To support this use case,
	/// 				use ``login(with:updateUserDisplayName:allowMigration:resetToAnonymousOnFailure:)`` instead.
	///
	/// - note: This function will fail with ``UserError.noUser`` if there is no anonymous user logged-in.
	///
	/// - since: version 6.0.0.
	/// - parameters:
	/// 	- credentials: The credentials to link to the anonymous account.
	/// - returns: A Completable action to observe.
	func linkAnonymousAccount(to credentials: Credentials) -> Completable
  
	// MARK: - Update User
	
  /// Update the currently signed in user taking new values from the
  /// passed object.
  ///
  /// You cannot instantiate a `UserData` instance directly. To pass the parameter to this function,
  /// use a value retrieved from `self.user` or `self.autoupdatingUser`. To simplify this even
  /// further, use `self.update(userConfigurationHandler:)`.
  ///
  /// - note: This function will not update the user email address, even if it has changed.
  ///
  /// - seealso: ``update(userConfigurationHandler:)``
  /// - parameters:
  ///     - user: A user to gather new values from.
  /// - returns: A Completable action to observe.
  func update(user: UserData) -> Completable
  
  /// Update the currently signed in user by retrieving its value and passing it
  /// to the `userConfigurationHandler`.
  ///
  /// - note: This function is a shorthand that takes the first value of ``autoupdatingUser``,
  /// 				maps it by calling `userConfigurationHandler` and passes the result to ``update(user:)``.
  ///
  /// - since: version 1.1.0
  ///
  /// - parameters:
  ///     - userConfigurationHandler: A function that takes a `UserData` instance and returns it with the required changes.
  /// - returns: A Completable action to observe.
  func update(userConfigurationHandler: @escaping (UserData) -> UserData) -> Completable
  
	// MARK: - Email Management
	
	/// Verify if an account exists on the server with the passed email address.
	///
	/// - warning: This query will always return `false` if your project is using Email Enumeration Protection.
	///
	///	- seealso: [Email Enumeration Protection](https://cloud.google.com/identity-platform/docs/admin/email-enumeration-protection)
	/// - parameters:
	///     - email: The account email address.
	/// - returns: A Single that completes with the result of the query on the backend.
	@available(*, deprecated, message: "This function will be removed when it is removed by the Firebase SDK. If your project is using Email Enumeration Protection, this query will always return false.")
	func accountExists(with email: String) -> Single<Bool>
	
  /// Update the email of the currently signed in user.
  ///
  /// All users have an email address associated, even those that have signed in using a login provider (such as Google).
  /// Keep in mind that some login providers may return a relay email which may not be enabled to receive messages.
  ///
	/// - warning: If your project has Email Enumeration Protection enabled, this call will fail.
	/// - seealso: [Email Enumeration Protection](https://cloud.google.com/identity-platform/docs/admin/email-enumeration-protection)
  /// - parameters:
  ///     - newEmail: The new email address.
  /// - returns: A Completable action to observe.
	@available(*, deprecated, renamed: "verifyAndChange(toNewEmail:)", message: "This function will be removed when it is removed by the Firebase SDK. If your project is using Email Enumeration Protection, you should invoke `verifyAndChange(toNewEmail:)` instead.")
  func updateEmail(newEmail: String) -> Completable
	
	/// Send a verification email to the specified email address and, if the verification succeeds,
	/// update the email address.
	///
	/// All users have an email address associated, even those that have signed in using a login provider (such as Google).
	/// Keep in mind that some login providers may return a relay email which may not be enabled to receive messages.
	///
	/// - note: If your project does not have Email Enumeration Protection enabled, you can also invoke ``updateEmail(newEmail:)``
	/// directly, but this will not send a verification email to confirm ownership of the email address.
	///
	/// - parameters:
	/// 	- newEmail: The new email address to be verified.
	/// - returns: A Completable action to observe.
	func verifyAndChange(toNewEmail newEmail: String) -> Completable
  
	// MARK: - Confirm Authentication
	
  /// Confirm the authentication of the passed credentials with the currently signed in user.
  ///
  /// You need to confirm the authentication of a user before performing sensitive operations, such
  /// as deleting the account, associating a new login provider or changing the email or password.
  ///
  /// To confirm the authentication with a login provider (such as Google), use the appropriate method in
  /// the "confirmAuthenticationWith" family, or confirm the authentication by other means and then call
  /// `self.confirmAuthentication(with:)`.
	///
	/// - note: This is a shorthand for ``confirmAuthentication(with:)`` passing ``Credentials.password``.
  ///
  /// - parameters:
  ///     - email: The user email address.
  ///     - password: The user password.
  /// - returns: A Completable action to observe.
	@available(*, deprecated, renamed: "confirmAuthentication(with:)", message: "Invoke the generic confirm function passing `Credentials.password`.")
  func confirmAuthentication(email: String, password: String) -> Completable
  
  /// Confirm the authentication of the passed credentials with the currently signed in user.
  ///
  /// - since: version 1.5.0
  ///
  /// - parameters:
  ///     - loginCredentials: A representation of the credentials used to login.
  /// - returns: A Completable action to observe.
  func confirmAuthentication(with loginCredentials: Credentials) -> Completable
	
	// MARK: - Password Management
	
	/// Update or set the password of the currently signed in user.
	///
	/// If the user does not have `password` among their `authenticationProviders`,
	/// this function will create a new provider using the user email and the specified password.
	/// This will basically link the Email & Password authentication to the user.
	/// If the user already has `password` as an authentication provider, this function will
	/// simply update their password.
	///
	/// - since: version 1.4.0
	///
	/// - parameters:
	///     - newPassword: The new password.
	/// - returns: A Completable action to observe.
	func updatePassword(newPassword: String) -> Completable
  
	// MARK: - Delete User
	
  /// Delete the currently signed in user.
  ///
  /// This is a sensitive action. If the user hasn't signed in recently, you'll need to confirm the authentication
  /// by invoking ``confirmAuthentication(with:)``.
  ///
  /// Using the `resetToAnonymous` parameter, you can make sure
  /// that there is always a user signed in; if the parameter is set to `true`, this
  /// function will call ``loginAnonymously()`` immediately after the logout operation has completed.
  ///
  /// - since: version 1.4.0
  ///
  /// - parameters:
  ///     - resetToAnonymous: If `true`, after having deleted the account successfully, this function will immediately sign in a new anonymous user.
  /// - returns: A Completable action to observe.
  func deleteUser(resetToAnonymous: Bool) -> Completable
  
}
