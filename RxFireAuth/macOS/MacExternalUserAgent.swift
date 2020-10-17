//
//  MacExternalUserAgent.swift
//  RxFireAuth-macOS
//
//  Created by Alessio Moiso on 11.10.20.
//

import AppAuth
#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

class ExternalUserAgent: NSObject, OIDExternalUserAgent {
  
  private var inProgress: Bool = false
  private var session: OIDExternalUserAgentSession?
  
  func present(_ request: OIDExternalUserAgentRequest, session: OIDExternalUserAgentSession) -> Bool {
    guard !self.inProgress else { return false }
    
    self.inProgress = true
    self.session = session
    
    var openedBrowser = false
    #if os(macOS)
    openedBrowser = NSWorkspace.shared.open(request.externalUserAgentRequestURL())
    #elseif os(iOS)
    openedBrowser = UIApplication.shared.openURL(request.externalUserAgentRequestURL())
    #endif
    
    if (!openedBrowser) {
      self.cleanUp()
      session.failExternalUserAgentFlowWithError(
        OIDErrorUtilities.error(with: OIDErrorCode.browserOpenError, underlyingError: nil, description: "Unable to open the browser.")
      )
    }
    
    return openedBrowser
  }
  
  func dismiss(animated: Bool, completion: @escaping () -> Void) {
    guard self.inProgress else {
      completion()
      return
    }
    
    self.cleanUp()
    completion()
  }
  
  private func cleanUp() {
    self.session = nil
    self.inProgress = false
  }
  
}
