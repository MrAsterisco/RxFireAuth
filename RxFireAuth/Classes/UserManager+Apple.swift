//
//  UserManager+Apple.swift
//  Redirekt
//
//  Created by Alessio Moiso on 12/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseAuth

extension UserManager: LoginProviderManagerType {
    
    @available(iOS 13.0, *)
    private func signInWithAppleHandler(in viewController: UIViewController) -> Single<LoginCredentials> {
        return Single<LoginCredentials>.create { [unowned self] (observer) -> Disposable in
            let disposable = Disposables.create { [unowned self] in
                self.loginHandler = nil
            }
            
            let appleSignInHandler = SignInWithAppleHandler(viewController: viewController)
            self.loginHandler = appleSignInHandler
            
            appleSignInHandler.signIn { (idToken, nonce, fullName, email, error) in
                guard !disposable.isDisposed else { return }
                
                guard error == nil else {
                    observer(.error(error!))
                    return
                }
                
                guard let email = email else { observer(.error(UserError.invalidEmail)); return }
                
                observer(
                    .success(
                        LoginCredentials(idToken: idToken ?? "", fullName: fullName, email: email, provider: .apple, nonce: nonce ?? "")
                    )
                )
            }
            
            return disposable
        }
    }
    
    @available(iOS 13.0, *)
    public func signInWithApple(in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor> {
        return self.signInWithAppleHandler(in: viewController)
            .flatMap { [unowned self] credentials in
                self.login(with: credentials, updateUserDisplayName: updateUserDisplayName, allowMigration: allowMigration)
            }
    }
    
    @available(iOS 13.0, *)
    public func confirmAuthenticationWithApple(in viewController: UIViewController) -> Completable {
        return self.signInWithAppleHandler(in: viewController)
            .flatMapCompletable { [unowned self] credentials -> Completable in
                return self.confirmAuthentication(with: credentials)
            }
    }
    
}
