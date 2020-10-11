//
//  LoginHandlerType.swift
//  AppAuth
//
//  Created by Alessio Moiso on 17/05/2020.
//

import Foundation

/// This protocol identifies a login handler object
/// that is used by the library to authenticate with a 3rd-party provider,
/// such as Apple or Google.
///
/// You will get an instance of this protocol when reading the value of `loginHandler`
/// in implementations of `IUserManager`- You can use it to redirect incoming calls
/// from the system browser, for example, when authenticating with a OAuth provider that
/// redirects directly to your app (such as Google Sign In).
public protocol LoginHandlerType {
  
  /// Handle the specified URL.
  ///
  /// - parameters:
  ///     - url: A URL.
  /// - returns: `true` if the URL was handled, `false` if it should be handled by someone else.
  func handle(url: URL) -> Bool
  
}
