//
//  String+SecureRandom.swift
//  Redirekt
//
//  Created by Alessio Moiso on 12/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

import UIKit
import CryptoKit
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
    
    @available(iOS 13.0, *)
    var sha256: String {
      let inputData = Data(self.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    var legacySha25: Data {
        let data = Data(self.utf8)
        var buffer = UnsafeMutableRawPointer.allocate(byteCount: Int(CC_SHA256_DIGEST_LENGTH), alignment: 8)
        var buffer2 = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(CC_SHA256_DIGEST_LENGTH))
        defer {
            buffer.deallocate()
            buffer2.deallocate()
        }
        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> () in
            CC_SHA256(ptr.baseAddress!, CC_LONG(data.count), buffer.assumingMemoryBound(to: UInt8.self))
        }
        CC_SHA256(buffer, CC_LONG(CC_SHA256_DIGEST_LENGTH), buffer2)
        return Data(buffer: UnsafeBufferPointer(start: buffer2, count: Int(CC_SHA256_DIGEST_LENGTH)))
    }
    
}
