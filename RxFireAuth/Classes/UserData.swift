//
//  User.swift
//  Redirekt
//
//  Created by Alessio Moiso on 12/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import UIKit
import FirebaseAuth

/// A User.
///
/// This class usually inherits data from a Firebase User.
/// You cannot instantiate this class directly. Use `UserManagerType`
/// implementations to get a user.
public struct UserData {
    
    /// Get the ID.
    ///
    /// Corresponds to `uid` on the Firebase User object.
    public let id: String?
    
    /// Get the  email.
    ///
    /// Corresponds to `email` on the Firebase User object.
    public let email: String?
    
    /// Get the user display name.
    ///
    /// Corresponds to `displayName` on the Firebase User object..
    public var displayName: String?
    
    /// Get if this is an anonymous user.
    ///
    /// Corresponds to `isAnonymous` on the Firebase User object.
    public let isAnonymous: Bool
    
    /// Get a list of providers that this user has connected.
    public let authenticationProviders: [LoginCredentials.Provider]
    
    /// Initialize a new instance using data from the passed Firebase User.
    ///
    /// - parameters:
    ///     - user: A Firebase User.
    init(user: User) {
        self.id = user.uid
        self.email = user.email
        self.displayName = user.displayName
        self.isAnonymous = user.isAnonymous
        self.authenticationProviders = user.providerData.compactMap { LoginCredentials.Provider(rawValue: $0.providerID) }
    }
    
}
