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

/// The default implementation of `UserManagerType`.
///
/// As a general rule, you should never use this class directly, as it may change
/// at any point even without a new major version.
/// Documentation for all methods inherited from its protocol are in the protocol itself.
/// The methods that are documented here are just those that are not inherited from the protocol.
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
    
    public var isAnonymous: Bool {
        return Auth.auth().currentUser != nil && Auth.auth().currentUser!.isAnonymous
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
        return Single.create { [unowned self] (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            Auth.auth().fetchSignInMethods(forEmail: email) { [unowned self] (methods,
                error) in
                guard !disposable.isDisposed else { return }
                
                if let error = error {
                    observer(.error(self.map(error: error)))
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
        return Completable.deferred { [unowned self] in
            guard !self.isLoggedIn else { return .error(UserError.alreadyLoggedIn) }
            
            if Auth.auth().currentUser?.isAnonymous == true {
                return self.linkAnonymousAccount(toEmail: email, password: password)
            }
            
            return Completable.create { (observer) -> Disposable in
                let disposable = Disposables.create { }
                
                Auth.auth().createUser(withEmail: email, password: password) { (_, error) in
                    guard !disposable.isDisposed else { return }
                    if let error = error {
                        observer(.error(self.map(error: error)))
                    } else {
                        observer(.completed)
                    }
                }
                
                return disposable
            }
        }
    }
    
    public func loginAnonymously() -> Completable {
        return Completable.deferred { [unowned self] in
            guard !self.isLoggedIn else { return .error(UserError.alreadyLoggedIn) }
            guard !self.isAnonymous else { return .error(UserError.alreadyAnonymous) }
            
            return Completable.create { [unowned self] (observer) -> Disposable in
                let disposable = Disposables.create { }
                
                Auth.auth().signInAnonymously { [unowned self] (_, error) in
                    guard !disposable.isDisposed else { return }
                    if let error = error {
                        observer(.error(self.map(error: error)))
                    } else {
                        observer(.completed)
                    }
                }
                
                return disposable
            }
        }
    }
    
    public func linkAnonymousAccount(toEmail email: String, password: String) -> Completable {
        return Completable.deferred {
            guard let user = Auth.auth().currentUser, user.isAnonymous else { return .error(UserError.noUser) }
            
            return Completable.create { [unowned self] (observer) -> Disposable in
                let disposable = Disposables.create { }
                
                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                user.link(with: credential) { (_, error) in
                    guard !disposable.isDisposed else { return }
                    if let error = error {
                        observer(.error(self.map(error: error)))
                    } else {
                        self.forceRefreshAutoUpdatingUser.onNext(())
                        observer(.completed)
                    }
                }
                
                return disposable
            }
        }
    }
    
    public func login(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor> {
        return Single.deferred { [unowned self] in
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
    }
    
    public func loginWithoutChecking(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor> {
        return Single.create { [unowned self] (observer) -> Disposable in
            let disposable = Disposables.create { }
            
            var oldUserId: String?
            
            let signInCompletionHandler: (Error?) -> Void = { [unowned self] (error) in
                if let error = error {
                    observer(.error(self.map(error: error)))
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
                
                currentUser.delete { [unowned self] (error) in
                    if let error = error {
                        observer(.error(self.map(error: error)))
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
    /// To use this function directly, you should wrap it inside an `Observable.create`
    /// function call. This function will check automatically if the passed disposable has already been
    /// disposed when coming back from `Auth`'s `signIn(with:)` function.
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
        return Completable.deferred { [unowned self] in
            if resetToAnonymous && self.isAnonymous { return .error(UserError.alreadyAnonymous) }
            
            var logoutAction = Completable.create { (observer) -> Disposable in
                let disposable = Disposables.create { }
                
                do {
                    try Auth.auth().signOut()
                    observer(.completed)
                } catch {
                    observer(.error(self.map(error: error)))
                }
                
                return disposable
            }
            
            if (resetToAnonymous) {
                logoutAction = logoutAction
                    .andThen(self.loginAnonymously())
            }
            
            return logoutAction
        }
    }
    
    public func update(user: UserData) -> Completable {
        return Completable.deferred { [unowned self] in
            guard let currentUser = Auth.auth().currentUser else { return Completable.error(UserError.noUser) }
            
            return Completable.create { [unowned self] (observer) -> Disposable in
                let disposable = Disposables.create { }
                
                let changeRequest = currentUser.createProfileChangeRequest()
                changeRequest.displayName = user.displayName
                
                changeRequest.commitChanges { (error) in
                    if let error = error {
                        observer(.error(self.map(error: error)))
                    } else {
                        self.forceRefreshAutoUpdatingUser.onNext(())
                        observer(.completed)
                    }
                }
                
                return disposable
            }
        }
    }
    
    public func update(userConfigurationHandler: @escaping (UserData) -> UserData) -> Completable {
        return Completable.deferred { [unowned self] in
            guard Auth.auth().currentUser != nil else { return Completable.error(UserError.noUser) }
            
            return self.autoupdatingUser
                .take(1)
                .filter { $0 != nil }.map { $0! }
                .map(userConfigurationHandler)
                .flatMap { [unowned self] in self.update(user: $0) }
                .asCompletable()
        }
    }
    
    public func updateEmail(newEmail: String) -> Completable {
        return Completable.deferred { [unowned self] in
            guard let user = Auth.auth().currentUser else { return Completable.error(UserError.noUser) }
            
            return Completable.create { (observer) -> Disposable in
                let disposable = Disposables.create { }
                
                user.updateEmail(to: newEmail) { (error) in
                    if let error = error {
                        observer(.error(self.map(error: error)))
                    } else {
                        observer(.completed)
                    }
                }
                
                return disposable
            }
        }
    }
    
    public func confirmAuthentication(email: String, password: String) -> Completable {
        return Completable.deferred { [unowned self] in
            guard let user = Auth.auth().currentUser else { return Completable.error(UserError.noUser) }
            
            return Completable.create { (observer) -> Disposable in
                let disposable = Disposables.create { }
                
                user.reauthenticate(with: EmailAuthProvider.credential(withEmail: email, password: password)) { [unowned self] (result, error) in
                    guard !disposable.isDisposed else { return }
                    if let error = error {
                        observer(.error(self.map(error: error)))
                    } else {
                        observer(.completed)
                    }
                }
                
                return disposable
            }
        }
    }
    
    /// Map a generic error to a `UserError`.
    ///
    /// For more info on all the Firebase errors,
    /// refer to the [Firebase Documentation](https://firebase.google.com/docs/auth/ios/errors)
    ///
    /// - parameters:
    ///     - error: A error.
    /// - returns: A `UserError` wrapping the error.
    func map(error: Error) -> UserError {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.networkError.rawValue:
            return .networkError
        case AuthErrorCode.userNotFound.rawValue:
            return .userNotFound
        case AuthErrorCode.userTokenExpired.rawValue:
            return .expiredToken
        case AuthErrorCode.invalidEmail.rawValue:
            return .invalidEmail
        case AuthErrorCode.userDisabled.rawValue:
            return .userDisabled
        case AuthErrorCode.wrongPassword.rawValue:
            return .wrongPassword
        case AuthErrorCode.invalidCredential.rawValue:
            return .invalidCredential
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .emailAlreadyInUse
        case AuthErrorCode.operationNotAllowed.rawValue:
            return .configurationError
        case AuthErrorCode.invalidAPIKey.rawValue, AuthErrorCode.appNotAuthorized.rawValue, AuthErrorCode.appNotVerified.rawValue:
            return .invalidConfiguration
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword(nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String)
        case AuthErrorCode.keychainError.rawValue:
            return .keychainError(error)
        case AuthErrorCode.userMismatch.rawValue:
            return .wrongUser
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return .authenticationConfirmationRequired
        case AuthErrorCode.providerAlreadyLinked.rawValue:
            return .providerAlreadyLinked
        default:
            return .unknown(error)
        }
    }
    
}
