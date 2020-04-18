//
//  UserManager.swift
//  Redirekt
//
//  Created by Alessio Moiso on 12/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import UIKit
import FirebaseAuth
import RxSwift

public class UserManager: UserManagerType {
    
    /// Instanties a new user manager.
    ///
    /// Pass `clearingKeychain = true` to clear credentials
    /// that are stored in the iCloud Keychain. This is particularly useful
    /// if you don't want to login users automatically when they install your
    /// app on multiple devices with iCloud Keychain turned on.
    /// You should pass `true` only once, otherwise the user will be
    /// logged-out every time you instantiate a user manager.
    ///
    /// - parameters:
    ///     - clearingKeychain: If set to `true`, this instance will attempt a logout (ignoring errors) while initializing.
    public init(clearingKeychain: Bool = false) {
        guard clearingKeychain else { return }
        do {
            try Auth.auth().signOut()
        } catch { }
    }
    
    /// Get or set a reference to a custom-provider login handler.
    var loginHandler: Any?
    
    public var isLoggedIn: Bool {
        return Auth.auth().currentUser != nil && !Auth.auth().currentUser!.isAnonymous
    }
    
    public var user: UserData? {
        if let user = Auth.auth().currentUser {
            return UserData(id: user.uid, email: user.email, displayName: user.displayName, isAnonymous: user.isAnonymous)
        }
        return nil
    }
    
    /// Get a Behavior Subject that emits a new value every time the value of
    /// `autoupdatingUser` must be refreshed.
    ///
    /// This is required to work around the fact that the Firebase SDK does not emit a
    /// state change when an anonymous account is linked successfully to another account,
    /// resulting in observers being fed old data.
    ///
    /// For example, if I am currently logged-in with an anonymous account and I proceed to link it
    /// to my email address "example@example.com", observers will not receive the updated email address.
    private var forceRefreshAutoUpdatingUser = BehaviorSubject<Void>(value: ())
    
    public var autoupdatingUser: Observable<UserData?> {
        return Observable.create { (observer) -> Disposable in
            let listener = Auth.auth().addStateDidChangeListener { (auth, user) in
                if let user = user {
                    observer.onNext(UserData(id: user.uid, email: user.email, displayName: user.displayName, isAnonymous: user.isAnonymous))
                } else {
                    observer.onNext(nil)
                }
            }
            
            let subscription = self.forceRefreshAutoUpdatingUser.subscribe(onNext: { _ in
                if let currentUser = Auth.auth().currentUser {
                    observer.onNext(UserData(id: currentUser.uid, email: currentUser.email, displayName: currentUser.displayName, isAnonymous: currentUser.isAnonymous))
                } else {
                    observer.onNext(nil)
                }
            })
            
            let disposable = Disposables.create {
                Auth.auth().removeStateDidChangeListener(listener)
                subscription.dispose()
            }
            
            return disposable
        }
    }
    
    public func accountExists(with email: String) -> Single<Bool> {
        return Single.create { (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            Auth.auth().fetchSignInMethods(forEmail: email) { (methods,
                error) in
                guard !disposable.isDisposed else { return }
                
                if let error = error {
                    observer(.error(error))
                } else if let methods = methods, methods.count > 0 {
                    observer(.success(true))
                } else {
                    observer(.success(false))
                }
            }
            
            return disposable
        }
    }
    
    public func register(email: String, password: String) -> Completable {
        guard !self.isLoggedIn else { return .error(UserError.alreadyLoggedIn) }
        
        if Auth.auth().currentUser?.isAnonymous == true {
            return self.linkAnonymousAccount(toEmail: email, password: password)
        }
        
        return Completable.create { (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            Auth.auth().createUser(withEmail: email, password: password) { (_, error) in
                guard !disposable.isDisposed else { return }
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.completed)
                }
            }
            
            return disposable
        }
    }
    
    public func loginAnonymously() -> Completable {
        guard !isLoggedIn else { return Completable.error(UserError.alreadyLoggedIn) }
        
        return Completable.create { (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            Auth.auth().signInAnonymously { (_, error) in
                guard !disposable.isDisposed else { return }
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.completed)
                }
            }
            
            return disposable
        }
    }
    
    public func linkAnonymousAccount(toEmail email: String, password: String) -> Completable {
        guard let user = Auth.auth().currentUser, user.isAnonymous else { return Completable.error(UserError.noUser) }
        
        return Completable.create { (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.link(with: credential) { (_, error) in
                guard !disposable.isDisposed else { return }
                if let error = error {
                    observer(.error(error))
                } else {
                    self.forceRefreshAutoUpdatingUser.onNext(())
                    observer(.completed)
                }
            }
            
            return disposable
        }
    }
    
    public func login(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor> {
        guard !self.isLoggedIn else { return .error(UserError.alreadyLoggedIn) }
        
        return self.accountExists(with: email)
            .flatMap { (accountExists) -> Single<LoginDescriptor> in
                if accountExists {
                    return self.loginWithoutChecking(email: email, password: password, allowMigration: allowMigration)
                } else {
                    return self.register(email: email, password: password)
                        .andThen(
                            Single.just(
                                LoginDescriptor(fullName: nil, performMigration: false, oldUserId: nil, newUserId: self.user?.id)
                            )
                        )
                }
            }
    }
    
    /// Sign in with the passed credentials without first checking if an account
    /// with the specified email address exists on the backend.
    ///
    /// - parameters:
    ///     - email: An email address.
    ///     - password: A password.
    /// - returns: A Single to observe for result.
    func loginWithoutChecking(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor> {
        return Single.create { (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            var oldUserId: String?
            
            let signInCompletionHandler: (Error?) -> Void = { (error) in
                if let error = error {
                    observer(.error(error))
                } else if let newUser = Auth.auth().currentUser {
                    observer(.success(
                            LoginDescriptor(
                                fullName: nil,
                                performMigration: allowMigration ?? false,
                                oldUserId: oldUserId,
                                newUserId: newUser.uid
                            )
                        )
                    )
                } else {
                    observer(.error(UserError.noUser))
                }
            }
            
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                if allowMigration == nil {
                    observer(.error(UserError.migrationRequired))
                    return disposable
                }
                
                oldUserId = currentUser.uid
                
                currentUser.delete { (error) in
                    if let error = error {
                        observer(.error(error))
                    } else {
                        self.signIn(with: EmailAuthProvider.credential(withEmail: email, password: password), in: disposable, completionHandler: signInCompletionHandler)
                    }
                }
            } else {
                self.signIn(with: EmailAuthProvider.credential(withEmail: email, password: password), in: disposable, completionHandler: signInCompletionHandler)
            }
            
            return disposable
        }
    }
    
    /// Sign in with the passed credentials in the specified disposable
    /// and calls the completion handler when done.
    ///
    /// - parameters:
    ///     - credentials: The credential to use to sign in.
    ///     - disposable: A disposable that controls the life of this operation.
    ///     - completionHandler: A completion handler to call when done.
    func signIn(with credentials: AuthCredential, in disposable: Cancelable, completionHandler: @escaping (Error?) -> Void) {
        Auth.auth().signIn(with: credentials) { (_, error) in
            guard !disposable.isDisposed else { return }
            
            if let error = error {
                completionHandler(error)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    public func logout(resetToAnonymous: Bool = false) -> Completable {
        var logoutAction = Completable.create { (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            do {
                try Auth.auth().signOut()
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            
            return disposable
        }
        
        if (resetToAnonymous) {
            logoutAction = logoutAction
                .andThen(self.loginAnonymously())
        }
        
        return logoutAction
    }
    
    public func update(user: UserData) -> Completable {
        guard let currentUser = Auth.auth().currentUser else { return Completable.error(UserError.noUser) }
        
        return Completable.create { (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            let changeRequest = currentUser.createProfileChangeRequest()
            changeRequest.displayName = user.displayName
            
            changeRequest.commitChanges { (error) in
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.completed)
                }
            }
            
            return disposable
        }
    }
    
    public func updateEmail(newEmail: String) -> Completable {
        guard let user = Auth.auth().currentUser else { return Completable.error(UserError.noUser) }
        
        return Completable.create { (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            user.updateEmail(to: newEmail) { (error) in
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.completed)
                }
            }
            
            return disposable
        }
    }
    
    public func confirmAuthentication(email: String, password: String) -> Completable {
        guard let user = Auth.auth().currentUser else { return Completable.error(UserError.noUser) }
        
        return Completable.create { (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            user.reauthenticate(with: EmailAuthProvider.credential(withEmail: email, password: password)) { (result, error) in
                guard !disposable.isDisposed else { return }
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.completed)
                }
            }
            
            return disposable
        }
    }
    
}
