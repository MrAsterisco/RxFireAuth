//
//  AppDelegate.swift
//  RxFireAuth-Example-macOS
//
//  Created by Alessio Moiso on 10.10.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Cocoa
import Firebase
import RxFireAuth

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  /// Get the user manager.
  private(set) var userManager: UserManagerType = UserManager()
  
  override func awakeFromNib() {
    FirebaseApp.configure()
  }
  
}

