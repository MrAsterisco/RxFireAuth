//
//  LoginCredentials.swift
//  Pods
//
//  Created by Alessio Moiso on 25/04/2020.
//

import Foundation

public struct LoginCredentials {
    
    public enum Provider: String {
        case apple = "apple.com"
    }
    
    var idToken: String
    
    var fullName: String?
    
    var email: String
    
    var provider: Provider
    
    var nonce: String
    
}
