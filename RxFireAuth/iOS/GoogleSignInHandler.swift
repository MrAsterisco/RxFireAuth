//
//  GoogleSignInHandler.swift
//  Pods
//
//  Created by Alessio Moiso on 17/05/2020.
//

import Foundation
import GoogleSignIn

public typealias GoogleSignInCompletionHandler = (_ idToken: String?, _ accessToken: String?, _ email: String?, _ fullName: String?, _ error: Error?) -> Void

class GoogleSignInHandler: NSObject, GIDSignInDelegate, LoginHandlerType {
    
    private var viewController: UIViewController
    private var completionHandler: GoogleSignInCompletionHandler?
    
    init(clientId: String, viewController: UIViewController) {
        self.viewController = viewController
        super.init()
        GIDSignIn.sharedInstance()?.clientID = clientId
        GIDSignIn.sharedInstance()?.delegate = self
    }
    
    func handle(url: URL) -> Bool {
        return GIDSignIn.sharedInstance()?.handle(url) ?? false
    }
    
    func signIn(completionHandler: @escaping GoogleSignInCompletionHandler) {
        self.completionHandler = completionHandler
        GIDSignIn.sharedInstance()?.presentingViewController = self.viewController
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            self.completionHandler?(nil, nil, nil, nil, error)
        } else if let authentication = user.authentication {
            self.completionHandler?(authentication.idToken, authentication.accessToken, user.profile?.email ?? nil, user.profile?.name ?? nil, nil)
        } else {
            self.completionHandler?(nil, nil, nil, nil, nil)
        }
    }
    
}
