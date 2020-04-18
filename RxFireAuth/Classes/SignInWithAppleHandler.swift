//
//  UserManager+Apple.swift
//  Redirekt
//
//  Created by Alessio Moiso on 12/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import UIKit
import AuthenticationServices
import JWTDecode

/// Instances of `SignInWithAppleHandler` need
/// functions of this type as completion handlers when signing in.
///
/// - parameters:
///     - idToken: The ID token returned by Apple.
///     - nonce: A random secure string to identify the authentication session.
///     - displayName: The user full name.
///     - email: The email associated to the Apple ID or a private email address.
///     - error: An error, if something went wrong.
public typealias SignInWithAppleCompletionHandler = (_ idToken: String?, _ nonce: String?, _ displayName: String?, _ email: String?, _ error: Error?) -> Void

/// A helper class that handles the flow of
/// Sign in with Apple.
///
/// An instance of this class is automatically created and invoked
/// by `UserManager` when you ask it to `signInWithApple(in:updateUserDisplayName:allowMigration:)`.
/// You can use it also without a user manager associated.
///
/// Sign in with Apple is only available on iOS 13 or later.
@available(iOS 13.0, *)
public class SignInWithAppleHandler: NSObject {
    
    private var nonce: String?
    
    private var viewController: UIViewController
    private var completionHandler: SignInWithAppleCompletionHandler?
    
    /// Create a new instance using the passed view controller.
    ///
    /// - parameters:
    ///     - viewController: A view controller over which the Sign in with Apple flow must be presented.
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    /// Start the Sign in with Apple flow.
    ///
    /// - parameters:
    ///     - completionHandler: A function to be performed when the flow is ended, either successfully or with an error.
    public func signIn(completionHandler: SignInWithAppleCompletionHandler?) {
        self.completionHandler = completionHandler
        self.nonce = String.secureRandomString()
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        request.nonce = self.nonce!.sha256
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
}

@available(iOS 13.0, *)
extension SignInWithAppleHandler: ASAuthorizationControllerDelegate {
    
    private func extractName(from components: PersonNameComponents?) -> String? {
        guard let components = components else { return nil }
        
        return ((components.givenName ?? "") + " " + (components.familyName ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        guard let nonce = self.nonce else {
            self.completionHandler?(nil, nil, nil, nil, SignInWithAppleError.invalidCallback)
            return
        }
        guard let idTokenData = credential.identityToken, let idToken = String(data: idTokenData, encoding: .utf8) else {
            self.completionHandler?(nil, nil, nil, nil, SignInWithAppleError.invalidIdToken)
            return
        }
        
        var email = credential.email
        if email == nil {
            do {
                let jwt = try decode(jwt: idToken)
                email = jwt.claim(name: "email").string
            } catch { }
        }
        
        self.completionHandler?(idToken, nonce, self.extractName(from: credential.fullName), email, nil)
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.completionHandler?(nil, nil, nil, nil, error)
    }
    
}

@available(iOS 13.0, *)
extension SignInWithAppleHandler: ASAuthorizationControllerPresentationContextProviding {
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return viewController.view.window!
    }
    
}
