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
        return Single<LoginDescriptor>.create { [unowned self] (observer) -> Disposable in
            let disposable = Disposables.create { [unowned self] in
                self.loginHandler = nil
            }
            
            let appleSignInHandler = SignInWithAppleHandler(viewController: viewController)
            self.loginHandler = appleSignInHandler
            
            appleSignInHandler.startSignInWithApple { (idToken, nonce, fullName, email, error) in
                guard !disposable.isDisposed else { return }
                
                if let error = error {
                    observer(.error(error))
                    return
                }
                
                guard let email = email else { observer(.error(UserError.invalidEmail)); return }
                
                let credentials = OAuthProvider.credential(withProviderID: "apple.com", idToken: idToken!, rawNonce: nonce)
                
                var oldUserId: String?
                let signInCompletionHandler: (Error?) -> Void = { (error) in
                    guard !disposable.isDisposed else { return }
                    if let error = error {
                        observer(.error(error))
                    } else if let newUser = Auth.auth().currentUser {
                        observer(
                            .success(
                                LoginDescriptor(fullName: fullName, performMigration: allowMigration!, oldUserId: oldUserId, newUserId: newUser.uid)
                            )
                        )
                    } else {
                        observer(.error(UserError.noUser))
                    }
                }
                
                /// Get if this user already exists
                Auth.auth().fetchSignInMethods(forEmail: email) { (methods, error) in
                    guard !disposable.isDisposed else { return }
                    guard error == nil else { observer(.error(error!)); return }
                    
                    if let methods = methods, methods.count > 0, let currentUser = Auth.auth().currentUser {
                        /// This user exists.
                        /// There is a currently logged-in user.
                        if currentUser.isAnonymous {
                            if allowMigration == nil {
                                observer(.error(UserError.migrationRequired))
                                return
                            }
                            
                            oldUserId = currentUser.uid
                            
                            /// The currently logged-in user is anonymous
                            /// We'll delete the anonymous account and login with the new account.
                            currentUser.delete { (error) in
                                guard !disposable.isDisposed else { return }
                                if let error = error {
                                    observer(.error(error))
                                } else {
                                    self.signIn(with: credentials, in: disposable, completionHandler: signInCompletionHandler)
                                }
                            }
                        } else {
                            /// The logged-in user is not anonymous.
                            /// We'll try to link this authentication method to the existing account.
                            currentUser.link(with: credentials) { (_, error) in
                                signInCompletionHandler(error)
                            }
                        }
                    } else if let currentUser = Auth.auth().currentUser {
                        /// This user does not exist.
                        /// There is a logged-in user.
                        /// We'll try to link the new authentication method to the existing account.
                        currentUser.link(with: credentials) { (_, error) in
                            signInCompletionHandler(error)
                        }
                    } else {
                        /// This user does not exist.
                        /// There's nobody logged-in.
                        /// We'll go ahead and sign in with the authentication method.
                        self.signIn(with: credentials, in: disposable, completionHandler: signInCompletionHandler)
                    }
                }
            }
            
            return disposable
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
