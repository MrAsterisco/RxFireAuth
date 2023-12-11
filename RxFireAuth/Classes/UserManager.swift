//
//  UserManager.swift
//  Redirekt
//
//  Created by Alessio Moiso on 12/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

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
  public internal(set) var loginHandler: LoginHandlerType?
  
  public var isLoggedIn: Bool {
    return Auth.auth().currentUser != nil && !Auth.auth().currentUser!.isAnonymous
  }
  
  public var isAnonymous: Bool {
    return Auth.auth().currentUser != nil && Auth.auth().currentUser!.isAnonymous
  }
  
  public var user: UserData? {
    guard let user = Auth.auth().currentUser else { return nil }
    return UserData(user: user)
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
  
  private var autoupdatingFirebaseUser: Observable<User?> {
    return Observable.create { [unowned self] (observer) -> Disposable in
      let listener = Auth.auth().addStateDidChangeListener { (auth, user) in
        observer.onNext(user)
      }
      
      let subscription = self.forceRefreshAutoUpdatingUser.subscribe(onNext: { _ in
        observer.onNext(Auth.auth().currentUser)
      })
      
      let disposable = Disposables.create {
        Auth.auth().removeStateDidChangeListener(listener)
        subscription.dispose()
      }
      
      return disposable
    }
  }
  
  public var autoupdatingUser: Observable<UserData?> {
    autoupdatingFirebaseUser
      .map { user in
        guard let user = user else {
          return nil
        }
        return .init(user: user)
      }
  }
  
  public var accessToken: Single<String?> {
    autoupdatingFirebaseUser
      .take(1).asSingle()
      .flatMap { (user: User?) in
        Single<String?>.create { (observer) -> Disposable in
          let disposable = Disposables.create { }
          
          if let user = user {
            user.getIDToken(completion: { (token, error) in
              if let token = token {
                observer(.success(token))
              } else if let error = error {
                observer(.failure(error))
              }
            })
          } else {
            observer(.success(nil))
          }
          
          return disposable
        }
      }
  }
  
  public func accountExists(with email: String) -> Single<Bool> {
    return Single.create { [unowned self] (observer) -> Disposable in
      let disposable = Disposables.create { }
      
      Auth.auth().fetchSignInMethods(forEmail: email) { [unowned self] (methods,
                                                                        error) in
        guard !disposable.isDisposed else { return }
        
        if let error = error {
          observer(.failure(self.map(error: error)))
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
  
  /// Link the passed user to the Email & Password authentication provider.
  ///
  /// - parameters:
  ///     - user: A user.
  ///     - email: The email address.
  ///     - password: A password.
  /// - returns: A Completable action to observe.
  private func link(user: User, toEmail email: String, withPassword password: String) -> Completable {
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
  
  public func linkAnonymousAccount(toEmail email: String, password: String) -> Completable {
    return Completable.deferred { [unowned self] in
      guard let user = Auth.auth().currentUser, user.isAnonymous else { return .error(UserError.noUser) }
      return self.link(user: user, toEmail: email, withPassword: password)
    }
  }
  
  public func login(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor> {
		login(
			with: .password(email: email, password: password),
			updateUserDisplayName: true,
			allowMigration: allowMigration
		)
  }
  
  public func loginWithoutChecking(email: String, password: String, allowMigration: Bool?) -> Single<LoginDescriptor> {
		login(
			email: email,
			password: password,
			allowMigration: allowMigration
		)
  }
  
  public func login(with credentials: Credentials, updateUserDisplayName: Bool, allowMigration: Bool? = nil) -> Single<LoginDescriptor> {
    return Single<LoginDescriptor>.create { [unowned self] observer -> Disposable in
      let disposable = Disposables.create { }
      
      let firebaseCredentials = credentials.asAuthCredentials()
      
      var oldUserId: String?
      let signInCompletionHandler: (Error?) -> Void = { (error) in
        guard !disposable.isDisposed else { return }
        if let error = error {
          observer(.failure(self.map(error: error)))
        } else if let newUser = Auth.auth().currentUser {
					
          observer(
            .success(
              LoginDescriptor(
								fullName: credentials.fullName,
								performMigration: allowMigration ?? false,
								oldUserId: oldUserId,
								newUserId: newUser.uid
							)
            )
          )
        } else {
          observer(.failure(UserError.noUser))
        }
      }
      
			if let currentUser = Auth.auth().currentUser {
				/// There is a logged-in user.
				/// We'll try to link the new authentication method to the existing account.
				currentUser.link(with: firebaseCredentials) { [forceRefreshAutoUpdatingUser] (_, error) in
					let nsError = error as? NSError
					
					if nsError?.code == AuthErrorCode.emailAlreadyInUse.rawValue && currentUser.isAnonymous {
						/// An error occurred while trying to link.
						/// 	When Email Enumeration Protection is enabled, this is the only signal we have
						/// 	to determine that a user with the provided email address already exists.
						/// This user exists.
						/// The currently logged-in user is anonymous, so we can try to migrate.
						if allowMigration == nil {
							/// Fail early because a migration would be required, but the caller is unprepared.
							observer(.failure(UserError.migrationRequired(credentials)))
							return
						}
						
						oldUserId = currentUser.uid
						
						/// The currently logged-in user is anonymous
						/// We'll delete the anonymous account and login with the new account.
						currentUser.delete { (error) in
							guard !disposable.isDisposed else { return }
							if let error = error {
								observer(.failure(self.map(error: error)))
							} else {
								self.signIn(
									with: firebaseCredentials,
									in: disposable,
									completionHandler: signInCompletionHandler
								)
							}
						}
					} else {
						if error == nil {
							forceRefreshAutoUpdatingUser.onNext(())
						}
						
						/// Linking succeeded or failed with a different error, so we return.
						signInCompletionHandler(error)
					}
				}
			} else {
				/// There's nobody logged-in.
				/// We'll go ahead and sign in with the authentication method.
				self.signIn(
					with: firebaseCredentials,
					in: disposable,
					completionHandler: signInCompletionHandler
				)
			}
      
      return disposable
    }
    .flatMap { (loginDescriptor) -> Single<LoginDescriptor> in
      if updateUserDisplayName, let fullName = loginDescriptor.fullName, fullName.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
        return self.update { (userData) -> UserData in
          var newUserData = userData
          newUserData.displayName = fullName
          return newUserData
        }.andThen(Single.just(loginDescriptor))
      }
      return Single.just(loginDescriptor)
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
	
	public func verifyAndChange(toNewEmail newEmail: String) -> Completable {
		return Completable.deferred { [unowned self] in
			guard let user = Auth.auth().currentUser else { return Completable.error(UserError.noUser) }
			
			return Completable.create { (observer) -> Disposable in
				let disposable = Disposables.create { }
				
				user.sendEmailVerification(beforeUpdatingEmail: newEmail) { (error) in
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
		confirmAuthentication(
			with: .password(email: email, password: password)
		)
  }
  
  public func confirmAuthentication(with loginCredentials: Credentials) -> Completable {
    return Completable.create { (observer) -> Disposable in
      let disposable = Disposables.create { }
      
      guard let user = Auth.auth().currentUser else { observer(.error(UserError.noUser)); return disposable }
      
      user.reauthenticate(with: loginCredentials.asAuthCredentials()) { (_, error) in
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
  
  public func deleteUser(resetToAnonymous: Bool) -> Completable {
    return Completable.deferred { [unowned self] in
      guard let user = Auth.auth().currentUser else { return Completable.error(UserError.noUser) }
      
      var deleteAction = Completable.create { (observer) -> Disposable in
        let disposable = Disposables.create { }
        
        user.delete { (error) in
          guard !disposable.isDisposed else { return }
          if let error = error {
            observer(.error(self.map(error: error)))
          } else {
            observer(.completed)
          }
        }
        
        return disposable
      }
      
      if resetToAnonymous {
        deleteAction = deleteAction
          .andThen(self.loginAnonymously())
      }
      
      return deleteAction
    }
  }
  
  public func updatePassword(newPassword: String) -> Completable {
    return Completable.deferred { [unowned self] in
      guard let user = Auth.auth().currentUser else { return Completable.error(UserError.noUser) }
      
      if self.user!.authenticationProviders.contains(.password) {
        return Completable.create { (observer) -> Disposable in
          let disposable = Disposables.create { }
          
          user.updatePassword(to: newPassword) { (error) in
            guard !disposable.isDisposed else { return }
            if let error = error {
              observer(.error(self.map(error: error)))
            } else {
              observer(.completed)
            }
          }
          
          return disposable
        }
      } else {
        guard let email = user.email else { return Completable.error(UserError.invalidEmail) }
        return self.link(user: user, toEmail: email, withPassword: newPassword)
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
