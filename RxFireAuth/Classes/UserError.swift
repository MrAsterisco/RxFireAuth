//
//  UserError.swift
//  RxFireAuth
//
//  Created by Alessio Moiso on 18/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

/// Errors thrown by  `UserManagerType` implementations.
///
/// Most of these errors are never thrown directly, but are always
/// returned as errors inside an Rx object.
public enum UserError: LocalizedError {
    
    /// There is no user associated to perform the requested action.
    case noUser
    /// The update cannot be performed because of invalid data.
    case invalidUpdate
    /// There is already another user logged-in.
    case alreadyLoggedIn
    /// The provided email is not valid.
    case invalidEmail
    /// The action would require to migrate the current user data to a new account.
    /// Use the passed login credentials to continue signing-in when ready by calling `login(with credentials:updateUserDisplayName:allowMigration:)`
    case migrationRequired(LoginCredentials?)
    /// The requested action cannot be performed because there is already an anonymous user logged-in.
    case alreadyAnonymous
    /// The specified user cannot be found.
    case userNotFound
    /// The specified user is disabled.
    case userDisabled
    /// The user token has expired.
    case expiredToken
    /// The specified password is invalid.
    case wrongPassword
    /// The specified credential is either expired or invalid.
    case invalidCredential
    /// The specified email is already in use in another account.
    case emailAlreadyInUse
    /// The specified password does not satisfy the basic security requirements.
    case weakPassword(String?)
    /// The requested action would target a different user than the one currently signed-in.
    case wrongUser
    /// The requested action requires a recent call to `self.confirmAuthentication(email:password:)`.
    case authenticationConfirmationRequired
    /// The specified provider is already linked with this user.
    case providerAlreadyLinked
    /// An error occurred while reaching Firebase servers.
    case networkError
    /// The requested operation is not enabled in Firebase Console.
    case configurationError
    /// The provided Firebase configuration is invalid.
    case invalidConfiguration
    /// An error occurred while attempting to access the keychain.
    case keychainError(Error?)
    /// An unknown error has occurred.
    case unknown(Error?)
    
    public var errorDescription: String? {
        switch self {
        case .noUser:
            return "This action requires a logged-in user."
        case .invalidUpdate:
            return "This update cannot be performed."
        case .alreadyLoggedIn:
            return "There is already a non-anonymous user logged-in."
        case .invalidEmail:
            return "The provided email address is invalid."
        case .migrationRequired:
            return "Proceeding with this action requires confirmation to migrate data from a user account to another."
        case .alreadyAnonymous:
            return "There is already an anonymous user logged-in."
        case .userNotFound:
            return "The specified user cannot be found."
        case .networkError:
            return "A network error occurred."
        case .unknown(let error):
            return error?.localizedDescription ?? "An unknown error occurred."
        case .userDisabled:
            return "The specified user is disabled."
        case .expiredToken:
            return "The credential stored on this device are no longer valid. Please re-authenticate."
        case .wrongPassword:
            return "The specified password is invalid."
        case .invalidCredential:
            return "The specified credential is invalid."
        case .emailAlreadyInUse:
            return "This email address is already registered with another account."
        case .weakPassword(let reason):
            return "The provided password does not satisfy the security requirements: \(reason ?? "please try again")."
        case .wrongUser:
            return "You are authenticating with a different user."
        case .authenticationConfirmationRequired:
            return "In order to perform this action, you'll have to confirm your credentials by authenticating again."
        case .providerAlreadyLinked:
            return "This login provider is already linked."
        case .configurationError:
            return "There is an error in your Firebase Console configuration."
        case .invalidConfiguration:
            return "There is an error in your app configuration."
        case .keychainError(let error):
            return "An error occurred while comunicating with the keychain: \(error?.localizedDescription ?? "unknown")"
        }
    }
    
}
