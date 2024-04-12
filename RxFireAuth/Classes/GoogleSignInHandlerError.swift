//
//  GoogleSignInHandlerError.swift
//
//
//  Created by Alessio Moiso on 12/04/24.
//

import Foundation

/// Errors thrown by `GoogleSignInHandler` instances.
public enum GoogleSignInHandlerError: Error {
	/// A window cannot be retrievied from the passed view controller.
	///
	/// Ensure that the view controller is visible **before** invoking the `signInWithGoogle` method.
	@available(macOS 10.13, *)
	case missingPresentation
}
