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
    public func signInWithApple(in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor> {
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
        .flatMap { [unowned self] credentials in
            self.login(with: credentials, allowMigration: allowMigration)
        }
        .flatMap { (loginDescriptor) -> Single<LoginDescriptor> in
            if updateUserDisplayName, let fullName = loginDescriptor.fullName, fullName.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                return self.update(user: UserData(id: nil, email: nil, displayName: fullName, isAnonymous: false))
                    .andThen(Single.just(loginDescriptor))
            }
            return Single.just(loginDescriptor)
        }
    }
    
}
