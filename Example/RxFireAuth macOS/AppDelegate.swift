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
  private(set) var userManager: UserManagerType & LoginProviderManagerType = UserManager()
  
  override func awakeFromNib() {
    FirebaseApp.configure()
  }
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(AppDelegate.handleGetURLEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
  }
  
  @objc func handleGetURLEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
    let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue!
    let url = URL(string: urlString!)!
    _ = userManager.loginHandler?.handle(url: url)
  }
  
}

