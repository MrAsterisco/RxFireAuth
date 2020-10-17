//
//  String+SecureRandom.swift
//  Redirekt
//
//  Created by Alessio Moiso on 12/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif
import CommonCrypto

extension String {
  
  static func secureRandomString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
      Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
      let randoms: [UInt8] = (0 ..< 16).map { _ in
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if errorCode != errSecSuccess {
          return 0
        }
        return random
      }
      
      randoms.forEach { random in
        if remainingLength == 0 {
          return
        }
        
        if random < charset.count {
          result.append(charset[Int(random)])
          remainingLength -= 1
        }
      }
    }
    
    return result
  }
  
  var sha256: String {
    #if canImport(CryptoKit)
    if #available(iOS 13, macOS 10.15, *) {
      return self.cryptoSha256
    }
    #endif
    return self.legacySha256
  }
  
  #if canImport(CryptoKit)
  @available(iOS 13.0, macOS 10.15, *)
  var cryptoSha256: String {
    let inputData = Data(self.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
      return String(format: "%02x", $0)
    }.joined()
    
    return hashString
  }
  #endif
  
  var legacySha256: String {
    let data = Data(self.utf8)
    let buffer = UnsafeMutableRawPointer.allocate(byteCount: Int(CC_SHA256_DIGEST_LENGTH), alignment: 8)
    let buffer2 = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(CC_SHA256_DIGEST_LENGTH))
    defer {
      buffer.deallocate()
      buffer2.deallocate()
    }
    data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> () in
      CC_SHA256(ptr.baseAddress!, CC_LONG(data.count), buffer.assumingMemoryBound(to: UInt8.self))
    }
    CC_SHA256(buffer, CC_LONG(CC_SHA256_DIGEST_LENGTH), buffer2)
    let hashedData = Data(buffer: UnsafeBufferPointer(start: buffer2, count: Int(CC_SHA256_DIGEST_LENGTH)))
    
    let hashString = hashedData.compactMap {
      return String(format: "%02x", $0)
    }.joined()
    
    return hashString
  }
  
}
