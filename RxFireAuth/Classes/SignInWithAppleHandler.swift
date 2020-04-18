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

typealias SignInWithAppleCompletionHandler = (String?, String?, String?, String?, Error?) -> Void

@available(iOS 13.0, *)
public class SignInWithAppleHandler: NSObject {
    
    enum SignInError: Error {
        case invalidCallback, invalidIdToken
    }
    
    var randomSecureString: String?
    
    private var viewController: UIViewController
    private var completionHandler: SignInWithAppleCompletionHandler?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func startSignInWithApple(completionHandler: SignInWithAppleCompletionHandler?) {
        self.completionHandler = completionHandler
        self.randomSecureString = String.secureRandomString()
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = self.randomSecureString!.sha256
        
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
        guard let nonce = self.randomSecureString else {
            self.completionHandler?(nil, nil, nil, nil, SignInError.invalidCallback)
            return
        }
        guard let idTokenData = credential.identityToken, let idToken = String(data: idTokenData, encoding: .utf8) else {
            self.completionHandler?(nil, nil, nil, nil, SignInError.invalidIdToken)
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
