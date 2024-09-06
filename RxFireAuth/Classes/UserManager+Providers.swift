//
//  UserManager+Apple.swift
//  Redirekt
//
//  Created by Alessio Moiso on 12/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import RxSwift
import FirebaseAuth
import AppAuth

extension UserManager: LoginProviderManagerType {
  
  // MARK: - Sign in with Apple
  
  @available(iOS 13.0, macOS 10.15, *)
  private func signInWithAppleHandler(in viewController: ViewController) -> Single<Credentials> {
    return Single<Credentials>.create { [unowned self] (observer) -> Disposable in
      let disposable = Disposables.create { [unowned self] in
        self.loginHandler = nil
      }
      
      let appleSignInHandler = SignInWithAppleHandler(viewController: viewController)
      self.loginHandler = appleSignInHandler
      
      appleSignInHandler.signIn { result in
        guard !disposable.isDisposed else { return }
        
				switch result {
				case let .success(data):
					guard let email = data.email else { observer(.failure(UserError.invalidEmail)); return }
					
					observer(
						.success(
							.apple(
								idToken: data.idToken,
								fullName: data.displayName,
								email: email,
								nonce: data.nonce
							)
						)
					)
				case let .failure(error):
					observer(
						.failure(error)
					)
				}
      }
      
      return disposable
    }.do(onDispose: { [weak self] in
      self?.loginHandler = nil
    })
  }
  
  @available(iOS 13.0, macOS 10.15, *)
  public func signInWithApple(in viewController: ViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor> {
    return self.signInWithAppleHandler(in: viewController)
      .flatMap { [unowned self] credentials in
        performLogin(
					with: credentials,
					updateUserDisplayName: updateUserDisplayName, 
					allowMigration: allowMigration,
					externalCredentialsProvider: signInWithAppleHandler(in: viewController),
					resetToAnonymousOnFailure: false
				)
      }
  }
  
  @available(iOS 13.0, macOS 10.15, *)
  public func confirmAuthenticationWithApple(in viewController: ViewController) -> Completable {
    return self.signInWithAppleHandler(in: viewController)
      .flatMapCompletable(self.confirmAuthentication(with:))
  }
  
  // MARK: - Google Sign-in
  
  private func signInWithGoogleHandler(as clientId: String, in viewController: ViewController) -> Single<Credentials> {
    return Single<Credentials>.create { [unowned self] (observer) -> Disposable in
      let disposable = Disposables.create {
        self.loginHandler = nil
      }
      
      let googleSignInHandler = GoogleSignInHandler(clientId: clientId, viewController: viewController)
      self.loginHandler = googleSignInHandler
      
      googleSignInHandler.signIn { (idToken, accessToken, email, fullName, error) in
        guard !disposable.isDisposed else { return }
        
        guard error == nil else {
					observer(.failure(error!))
          return
        }
        
        observer(
          .success(
						.google(
							idToken: idToken ?? "",
							accessToken: accessToken ?? "",
							fullName: fullName,
							email: email ?? ""
						)
          )
        )
      }
      
      return disposable
    }.do(onDispose: { [weak self] in
      self?.loginHandler = nil
    })
  }
  
  public func signInWithGoogle(as clientId: String, in viewController: ViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor> {
    return self.signInWithGoogleHandler(as: clientId, in: viewController)
      .flatMap { [unowned self] credentials in
        performLogin(
					with: credentials,
					updateUserDisplayName: updateUserDisplayName,
					allowMigration: allowMigration,
					externalCredentialsProvider: signInWithGoogleHandler(as: clientId, in: viewController),
					resetToAnonymousOnFailure: false
				)
      }
  }
  
  public func confirmAuthenticationWithGoogle(as clientId: String, in viewController: ViewController) -> Completable {
    return self.signInWithGoogleHandler(as: clientId, in: viewController)
      .flatMapCompletable(self.confirmAuthentication(with:))
  }
  
}
