//
//  LoginCredentials.swift
//  Pods
//
//  Created by Alessio Moiso on 25/04/2020.
//

import Foundation
import FirebaseAuth

/// An authentication provider.
///
/// - since: version 4.0.0
public enum AuthenticationProvider: String {
	/// Email & Password
	case password = "password"
	/// Sign in with Apple.
	case apple = "apple.com"
	/// Google Sign In
	case google = "google.com"
	
	/// Get the Firebase Auth Provider ID for this authentication provider.
	var asAuthProviderID: AuthProviderID {
		switch self {
		case .apple:
			return .apple
		case .google:
			return .google
		case .password:
			return .email
		}
	}
}

/// Credentials used to perform a sign in
/// with an authentication provider.
///
/// Cases of this enums are returned when a recoverable
/// error, such as `UserError.migrationRequired`, occurs during a sign in.
///
/// - since: version 4.0.0
public enum Credentials {
	case password(email: String, password: String)
	case apple(idToken: String, fullName: String?, email: String, nonce: String)
	case google(idToken: String, accessToken: String, fullName: String?, email: String)
  
	var fullName: String? {
		switch self {
		case let .apple(_, fullName, _, _), let .google(_, _, fullName, _):
			return fullName
		case .password:
			return nil
		}
	}
	
  /// Get the Firebase representation of the credentials.
  ///
  /// - returns: A Firebase Auth Credentials.
  func asAuthCredentials() -> AuthCredential {
    switch self {
    case let .password(email, password):
      return EmailAuthProvider.credential(
				withEmail: email,
				password: password
			)
    case let .apple(idToken, _, _, nonce):
			return OAuthProvider.credential(
				providerID: AuthenticationProvider.apple.asAuthProviderID,
				idToken: idToken,
				rawNonce: nonce
			)
    case let .google(idToken, accessToken, _, _):
      return GoogleAuthProvider.credential(
				withIDToken: idToken,
				accessToken: accessToken
			)
    }
  }
	
	/// Get whether this credential is reusable after it has been sent to the server
	///
	/// Sign in with Apple credentials are not reusable. If you need to authenticate the user twice,
	/// you will have to present the SIWA screen twice.
	var isReusable: Bool {
		return switch self {
		case .password, .google:
			true
		default:
			false
		}
	}
  
}
