//
//  UserManager+Apple.swift
//  Redirekt
//
//  Created by Alessio Moiso on 12/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import RxSwift
import FirebaseAuth

extension UserManager: LoginProviderManagerType {
  
  // MARK: - Sign in with Apple
  
  @available(iOS 13.0, macOS 10.15, *)
  private func signInWithAppleHandler(in viewController: ViewController) -> Single<LoginCredentials> {
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
    }.do(onDispose: { [weak self] in
      self?.loginHandler = nil
    })
  }
  
  @available(iOS 13.0, macOS 10.15, *)
  public func signInWithApple(in viewController: ViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor> {
    return self.signInWithAppleHandler(in: viewController)
      .flatMap { [unowned self] credentials in
        self.login(with: credentials, updateUserDisplayName: updateUserDisplayName, allowMigration: allowMigration)
      }
  }
  
  @available(iOS 13.0, macOS 10.15, *)
  public func confirmAuthenticationWithApple(in viewController: ViewController) -> Completable {
    return self.signInWithAppleHandler(in: viewController)
      .flatMapCompletable(self.confirmAuthentication(with:))
  }
  
  // MARK: - Google Sign-in
  
  private func signInWithGoogleHandler(as clientId: String, in viewController: ViewController) -> Single<LoginCredentials> {
    return Single<LoginCredentials>.create { [unowned self] (observer) -> Disposable in
      let disposable = Disposables.create {
        self.loginHandler = nil
      }
      
      let googleSignInHandler = GoogleSignInHandler(clientId: clientId, viewController: viewController)
      self.loginHandler = googleSignInHandler
      
      googleSignInHandler.signIn { (idToken, accessToken, email, fullName, error) in
        guard !disposable.isDisposed else { return }
        
        guard error == nil else {
          observer(.error(error!))
          return
        }
        
        observer(
          .success(
            LoginCredentials(idToken: idToken ?? "", accessToken: accessToken, fullName: fullName, email: email ?? "", password: nil, provider: .google, nonce: "")
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
        self.login(with: credentials, updateUserDisplayName: updateUserDisplayName, allowMigration: allowMigration)
      }
  }
  
  public func confirmAuthenticationWithGoogle(as clientId: String, in viewController: ViewController) -> Completable {
    return self.signInWithGoogleHandler(as: clientId, in: viewController)
      .flatMapCompletable(self.confirmAuthentication(with:))
  }
  
}
