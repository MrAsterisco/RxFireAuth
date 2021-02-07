//
//  GoogleSignInHandler.swift
//  Pods
//
//  Created by Alessio Moiso on 17/05/2020.
//

import AppAuth

public typealias GoogleSignInCompletionHandler = (_ idToken: String?, _ accessToken: String?, _ email: String?, _ fullName: String?, _ error: Error?) -> Void

class GoogleSignInHandler: LoginHandlerType {
  
  private static let serviceURL = URL(string: "https://accounts.google.com/")!
  
  private let clientId: String
  private let reversedClientId: String
  private let viewController: ViewController
  private var completionHandler: GoogleSignInCompletionHandler?
  
  private var session: OIDExternalUserAgentSession?
  
  init(clientId: String, viewController: ViewController) {
    self.clientId = clientId
    self.reversedClientId = Array(clientId.split(separator: ".").reversed()).joined(separator: ".")
    self.viewController = viewController
  }
  
  func handle(url: URL) -> Bool {
    self.session?.resumeExternalUserAgentFlow(with: url) == true
  }
  
  func signIn(completionHandler: @escaping GoogleSignInCompletionHandler) {
    self.completionHandler = completionHandler
    
    OIDAuthorizationService.discoverConfiguration(forIssuer: Self.serviceURL) { [unowned self] (configuration, error) in
      guard let configuration = configuration, error == nil else {
        completionHandler(nil, nil, nil, nil, error)
        return
      }
      
      let request = OIDAuthorizationRequest(configuration: configuration, clientId: self.clientId, clientSecret: "", scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail], redirectURL: self.redirectURL, responseType: OIDResponseTypeCode, additionalParameters: nil)
      
      let callback: (OIDAuthState?, Error?) -> Void = { (authState, error) in
        guard let authState = authState, let lastTokenResponse = authState.lastTokenResponse, error == nil else {
          completionHandler(nil, nil, nil, nil, error)
          return
        }
        
        let idToken = OIDIDToken(idTokenString: lastTokenResponse.idToken ?? "")
        completionHandler(nil, authState.lastTokenResponse?.accessToken, idToken?.claims["email"] as? String, idToken?.claims["name"] as? String, nil)
      }
      
      #if os(macOS)
      self.session = OIDAuthState.authState(byPresenting: request, externalUserAgent: ExternalUserAgent(), callback: callback)
      #elseif os(iOS)
      self.session = OIDAuthState.authState(byPresenting: request, presenting: viewController, callback: callback)
      #endif
    }
  }
  
  private var redirectURL: URL {
    return URL(string: "\(self.reversedClientId):/oauthredirect")!
  }
  
}
