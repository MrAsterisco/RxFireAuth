//
//  User.swift
//  Redirekt
//
//  Created by Alessio Moiso on 12/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import UIKit

/// A User.
///
/// This class usually inherits data from a Firebase User.
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
    public let displayName: String?
    
    /// Get if this is an anonymous user.
    ///
    /// Corresponds to `isAnonymous` on the Firebase User object.
    public let isAnonymous: Bool
    
}
