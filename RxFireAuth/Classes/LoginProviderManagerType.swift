//
//  LoginProviderManagerType.swift
//  AddAction
//
//  Created by Alessio Moiso on 13/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import RxSwift

public protocol LoginProviderManagerType {

    /// Sign in with Apple in the passed view controller.
    ///
    /// - parameters:
    ///     - viewController: The view controller over which the Sign in with Apple UI should be displayed.
    ///     - updateUserDisplayName: If set to `true`, a successful login will also update the user `displayName` field using information from the associated Apple ID.
    ///     - allowMigration: An optional boolean that defines the behavior in case there is an anonymous user logged-in and the user is trying to login in an existing account. This option will be passed back to the caller
    ///     in the resulting `LoginDescriptor.performMigration`; if set to `nil`, the operation will not proceed and a `UserError.migrationRequired` error will be thrown.
    /// - returns: A Single that emits errors or a `LoginDescriptor` instance.
    @available(iOS 13.0, *)
    func signInWithApple(in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
    
}
