//
//  SignInWithAppleError.swift
//  FirebaseAuth
//
//  Created by Alessio Moiso on 18/04/2020.
//

import Foundation

/// Errors thrown by `SignInWithAppleHandler` instances.
enum SignInWithAppleError: Error {
    /// A callback has been invoked without a nonce.
    case invalidCallback
    /// Apple returned an invalid ID token.
    case invalidIdToken
}
