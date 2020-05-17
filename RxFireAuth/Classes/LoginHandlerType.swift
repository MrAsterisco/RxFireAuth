//
//  LoginHandlerType.swift
//  AppAuth
//
//  Created by Alessio Moiso on 17/05/2020.
//

import Foundation

public protocol LoginHandlerType {
    
    func handle(url: URL) -> Bool
    
}
