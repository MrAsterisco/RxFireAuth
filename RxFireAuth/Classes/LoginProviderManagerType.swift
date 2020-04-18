//
//  LoginProviderManagerType.swift
//  AddAction
//
//  Created by Alessio Moiso on 13/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import RxSwift

public protocol LoginProviderManagerType {

    @available(iOS 13.0, *)
    func signInWithApple(in viewController: UIViewController, updateUserDisplayName: Bool, allowMigration: Bool?) -> Single<LoginDescriptor>
    
}
