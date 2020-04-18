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
    case migrationRequired
    
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
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .noUser:
            return "There is no user currently logged-in."
        case .invalidUpdate:
            return "The update contains invalid data and cannot be performed."
        case .alreadyLoggedIn:
            return "The requested action can be performed only when there is an anonymous user or nobody logged-in."
        case .invalidEmail:
            return "The provided value is not a valid email address."
        case .migrationRequired:
            return "The requested action will result in deleting the currently logged-in user and replace it with another user account, hence the library is asking for confirmation that the caller will perform (or not) data migration."
        }
    }
    
}
