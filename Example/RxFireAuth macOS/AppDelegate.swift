//
//  AppDelegate.swift
//  RxFireAuth-Example-macOS
//
//  Created by Alessio Moiso on 10.10.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Cocoa
import Firebase

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    FirebaseApp.configure()
  }
  
}

