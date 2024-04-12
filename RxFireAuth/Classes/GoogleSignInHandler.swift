//
//  GoogleSignInHandler.swift
//  Pods
//
//  Created by Alessio Moiso on 17/05/2020.
//

import GoogleSignIn

public typealias GoogleSignInCompletionHandler = (_ idToken: String?, _ accessToken: String?, _ email: String?, _ fullName: String?, _ error: Error?) -> Void

class GoogleSignInHandler: LoginHandlerType {
  private let clientId: String
  private let viewController: ViewController
  private var completionHandler: GoogleSignInCompletionHandler?
  
  init(clientId: String, viewController: ViewController) {
    self.clientId = clientId
    self.viewController = viewController
  }
  
  func handle(url: URL) -> Bool {
		GIDSignIn.sharedInstance.handle(url)
  }
  
  func signIn(completionHandler: @escaping GoogleSignInCompletionHandler) {
    self.completionHandler = completionHandler
		GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
		
		#if os(macOS)
		let presentation = viewController.view.window
		guard let presentation else {
			completionHandler(
				nil,
				nil,
				nil,
				nil,
				ProvidersError.unexpected(GoogleSignInHandlerError.missingPresentation)
			)
			return
		}
		#else
		let presentation = viewController
		#endif
		
		GIDSignIn.sharedInstance.signIn(withPresenting: presentation) { result, error in
			if let error {
				completionHandler(
					nil,
					nil,
					nil,
					nil,
					ProvidersError.fromGoogle(error: error)
				)
			}
			
			completionHandler(
				result?.user.idToken?.tokenString,
				result?.user.accessToken.tokenString,
				result?.user.profile?.email,
				result?.user.profile?.name,
				nil
			)
		}
  }
}

private extension ProvidersError {
	static func fromGoogle(error: Error?) -> Self {
		guard let error else { return .unknown }
		
		if (error as NSError).code == GIDSignInError.canceled.rawValue {
			return .userCancelled
		}
		
		return .unexpected(error)
	}
}
