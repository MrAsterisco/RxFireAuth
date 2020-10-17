//
//  LoginCredentials.swift
//  Pods
//
//  Created by Alessio Moiso on 25/04/2020.
//

import Foundation
import FirebaseAuth

/// This class represents a set of credentials used
/// to perform a sign in with a specific authentication provider.
///
/// Instances of this class are returned when a recoverable
/// error, such as `UserError.migrationRequired`, occurs during a sign in.
///
/// You shouldn't need to inspect the content of this struct.
/// Its main purpose is to temporary store credentials in order
/// to continue the login action when your client has handled the error.
public struct LoginCredentials {
  
  /// A provider represents a supported authentication provider.
  public enum Provider: String {
    /// Email & Password
    case password = "password"
    /// Sign in with Apple.
    case apple = "apple.com"
    /// Google Sign In
    case google = "google.com"
  }
  
  /// Get or set the ID token.
  var idToken: String
  
  /// Get or set the access token.
  var accessToken: String?
  
  /// Get or set the user full name.
  var fullName: String?
  
  /// Get or set the user email.
  var email: String
  
  /// Get or set the user password.
  var password: String?
  
  /// Get or set the authentication provider.
  var provider: Provider
  
  /// Get or set the nonce.
  var nonce: String
  
  /// Get the Firebase representation of these credentials.
  ///
  /// - returns: A Firebase Auth Credentials.
  func asAuthCredentials() -> AuthCredential {
    switch self.provider {
    case .password:
      return EmailAuthProvider.credential(withEmail: self.email, password: self.password ?? "")
    case .apple:
      return OAuthProvider.credential(withProviderID: self.provider.rawValue, idToken: self.idToken, rawNonce: self.nonce)
    case .google:
      return GoogleAuthProvider.credential(withIDToken: self.idToken, accessToken: self.accessToken ?? "")
    }
  }
  
}
