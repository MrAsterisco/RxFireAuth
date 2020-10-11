//
//  ViewController.swift
//  RxFireAuth-Example-macOS
//
//  Created by Alessio Moiso on 10.10.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Cocoa
import RxFireAuth
import RxSwift
import RxCocoa

class ViewController: NSViewController {
  
  @IBOutlet weak var welcomeLabel: NSTextField!
  @IBOutlet weak var subtitleLabel: NSTextField!
  
  @IBOutlet weak var loginField: NSTextField!
  @IBOutlet weak var passwordField: NSTextField!
  
  @IBOutlet weak var signInButton: NSButton!
  @IBOutlet weak var signOutButton: NSButton!
  
  @IBOutlet weak var dataMigrationControl: NSSegmentedControl!
  
  @IBOutlet weak var nameField: NSTextField!
  @IBOutlet weak var updateProfileButton: NSButton!
  
  @IBOutlet weak var resetAnonymousCheckbox: NSButton!
  
  @IBOutlet weak var providersField: NSTextField!
  @IBOutlet weak var confirmAuthButton: NSButton!
  
  @IBOutlet weak var progressIndicator: NSProgressIndicator!
  @IBOutlet weak var progressLabel: NSTextField!
  
  private var userManager: UserManagerType {
    return (NSApp.delegate as! AppDelegate).userManager
  }
  
  private let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.toggleProgress(false)
    
    self.userManager.autoupdatingUser
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] (user) in
        if let user = user {
          if user.isAnonymous {
            self.welcomeLabel.stringValue = "Welcome, Anonymous!"
            self.subtitleLabel.stringValue = "You are now logged-in with an anonymous account."
          } else {
            if let displayName = user.displayName, displayName.count > 0 {
              self.welcomeLabel.stringValue = "Welcome, \(displayName)!"
            } else {
              self.welcomeLabel.stringValue = "Welcome!"
            }
            self.subtitleLabel.stringValue = "You are logged-in with \(user.email ?? "Unknown")."
          }
          self.nameField.stringValue = user.displayName ?? ""
          
          self.providersField.stringValue = user.authenticationProviders.map { $0.rawValue }.joined(separator: ", ")
        } else {
          self.welcomeLabel.stringValue = "Welcome!"
          self.subtitleLabel.stringValue = "You are not logged-in."
          self.providersField.stringValue = "Not logged-in."
        }
      })
      .disposed(by: disposeBag)
    
    self.loginField.rx.text
      .map { ($0 ?? "").count > 0 }
      .withLatestFrom(self.userManager.autoupdatingUser.map({ $0 != nil })) { hasEmail, isLoggedIn -> String in
        if !hasEmail && !isLoggedIn {
          return "Sign in anonymously"
        } else if isLoggedIn && hasEmail {
          return "Link"
        } else if isLoggedIn && !hasEmail {
          return "Insert Email..."
        }
        return "Sign in"
      }
      .subscribe(onNext: { [unowned self] in
        self.signInButton.title = $0
      })
      .disposed(by: self.disposeBag)
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    self.loginField.becomeFirstResponder()
  }
  
  // MARK - Actions
  
  @IBAction func signIn(sender: AnyObject) {
    self.toggleProgress(true)
    if self.loginField.stringValue.isEmpty {
      self.userManager.loginAnonymously()
        .subscribe(onCompleted: { [unowned self] in
          self.toggleProgress(false)
        }, onError: { [unowned self] in
          self.show(error: $0)
        })
        .disposed(by: self.disposeBag)
    } else {
      self.userManager.login(email: self.loginField.stringValue, password: self.passwordField.stringValue, allowMigration: self.migrationAllowance)
        .subscribe(onSuccess: { [unowned self] in
          self.handleLoggedIn($0)
        }, onError: { [unowned self] in
          self.handleSignInError(error: $0)
        })
        .disposed(by: self.disposeBag)
    }
  }
  
  @IBAction func signOut(sender: AnyObject) {
    self.toggleProgress(true)
    self.userManager.logout(resetToAnonymous: self.resetAnonymousCheckbox.state == .on)
      .subscribe(onCompleted: { [unowned self] in
        self.toggleProgress(false)
      }, onError: { [unowned self] in
        self.show(error: $0)
      })
      .disposed(by: self.disposeBag)
  }
  
  @IBAction func updateProfile(sender: AnyObject) {
    self.toggleProgress(true)
    self.userManager.update { [unowned self] (userData) -> UserData in
      var user = userData
      user.displayName = self.nameField.stringValue
      return user
    }.subscribe(onCompleted: { [unowned self] in
      self.toggleProgress(false)
    }, onError: { [unowned self] in
      self.show(error: $0)
    })
    .disposed(by: self.disposeBag)
  }
  
  @IBAction func changePassword(sender: AnyObject) {
    self.toggleProgress(true)
    self.userManager.autoupdatingUser
      .filter { $0 != nil }.map { $0! }
      .take(1)
      .map { $0.authenticationProviders }
      .subscribe(onNext: { [unowned self] (authenticationProviders) in
        self.toggleProgress(false) {
          if authenticationProviders.contains(.password) {
            self.changeExistingPassword()
          } else {
            self.setNewPassword()
          }
        }
      })
      .disposed(by: self.disposeBag)
  }
  
  @IBAction func deleteAccount(sender: AnyObject) {
    self.toggleProgress(true)
    self.userManager.deleteUser(resetToAnonymous: self.resetAnonymousCheckbox.state == .on)
      .subscribe(onCompleted: { [unowned self] in
        self.toggleProgress(false)
      }, onError: { [unowned self] in
        self.show(error: $0)
      })
      .disposed(by: self.disposeBag)
  }
  
  @IBAction func confirmAuthentication(sender: AnyObject) {
    let providers = self.userManager.user?.authenticationProviders
      .map { provider in
        return NSMenuItem(title: provider.rawValue, action: #selector(confirmAuthentication(of:)), keyEquivalent: "")
      }
    
    let menu = NSMenu(title: "")
    providers?.forEach(menu.addItem(_:))
    NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: self.confirmAuthButton)
  }
  
  @objc func confirmAuthentication(of sender: NSMenuItem) {
    guard let provider = LoginCredentials.Provider(rawValue: sender.title) else {
      return
    }
    
    self.confirmAuthentication(for: provider)
  }
  
  // MARK: - Logic
  
  private func handleSignInError(error: Error) {
    if case UserError.migrationRequired(let credentials) = error {
      self.handleMigration(credentials: credentials)
    } else {
      self.show(error: error)
    }
  }
  
  private func confirmAuthentication(for provider: LoginCredentials.Provider) {
    switch provider {
    case .password:
      let email = self.loginField.stringValue
      let password = self.passwordField.stringValue
      
      guard email.count > 0 && password.count > 0 else {
        self.show(title: "Insert your email and password!", message: "Use the field at the top of the screen to insert your email and password.")
        return
      }
      
      self.toggleProgress(true)
      self.userManager.confirmAuthentication(email: email, password: password)
        .observeOn(MainScheduler.instance)
        .subscribe(onCompleted: { [unowned self] in
          self.toggleProgress(false)
          self.show(title: "Authentication Confirmed!", message: "You can now perform sensitive operations.")
        }, onError: { [unowned self] in
          self.show(error: $0)
        })
        .disposed(by: disposeBag)
    default:
      break
    }
  }
  
  private func changeExistingPassword() {
    let alert = NSAlert()
    alert.messageText = "Confirm Credentials"
    alert.informativeText = "Insert your current password below:"
    
    let textField = NSSecureTextField(frame: .init(x: 0, y: 0, width: 350, height: 24))
    textField.placeholderString = "Current Password"
    alert.accessoryView = textField
    
    alert.addButton(withTitle: "Confirm")
    alert.addButton(withTitle: "Cancel")
    
    alert.beginSheetModal(for: view.window!) { [unowned self] (response) in
      if response == .alertFirstButtonReturn {
        self.userManager.confirmAuthentication(email: self.userManager.user!.email!, password: textField.stringValue)
          .observeOn(MainScheduler.instance)
          .subscribe(onCompleted: { [unowned self] in
            self.setNewPassword()
          }, onError: { [unowned self] in
            self.show(error: $0)
          })
          .disposed(by: disposeBag)
      }
    }
  }
  
  private func setNewPassword() {
    let alert = NSAlert()
    alert.messageText = "New Password"
    alert.informativeText = "Insert your new password below:"
    
    let textField = NSSecureTextField(frame: .init(x: 0, y: 0, width: 350, height: 24))
    textField.placeholderString = "New Password"
    alert.accessoryView = textField
    
    alert.addButton(withTitle: "Set")
    alert.addButton(withTitle: "Cancel")
    
    alert.beginSheetModal(for: view.window!) { [unowned self] (response) in
      self.userManager.updatePassword(newPassword: textField.stringValue)
        .observeOn(MainScheduler.instance)
        .subscribe(onCompleted: { [unowned self] in
          self.show(title: "Password set!", message: "Your new password has been set.")
        }, onError: { [unowned self] in
          self.show(error: $0)
        })
        .disposed(by: self.disposeBag)
    }
  }
  
  private func handleMigration(credentials: LoginCredentials?) {
    let alert = NSAlert()
    alert.messageText = "Migration Required"
    alert.informativeText = "You are trying to login into an existing account while being logged-in with an anonymous account. When doing this in a real app, you should check if the user has data in the anonymous account and, if so, offer the option to merge the anonymous account with the one that the user is trying to sign into."
    alert.addButton(withTitle: "Migrate")
    alert.addButton(withTitle: "Cancel")
    alert.beginSheetModal(for: view.window!) { [unowned self] (response) in
      switch response {
      case .alertFirstButtonReturn:
        if let credentials = credentials {
          self.userManager.login(with: credentials, updateUserDisplayName: true, allowMigration: true)
            .subscribe(onSuccess: self.handleLoggedIn(_:), onError: self.show(error:))
            .disposed(by: self.disposeBag)
        } else {
          self.userManager.login(email: self.loginField.stringValue, password: self.passwordField.stringValue, allowMigration: true)
            .subscribe(onSuccess: self.handleLoggedIn(_:), onError: self.show(error:))
            .disposed(by: self.disposeBag)
        }
      default:
        break
      }
    }
  }
  
  // MARK: - Utilities
  
  private func toggleProgress(_ show: Bool, completionHandler: (() -> Void)? = nil) {
    if show {
      self.progressIndicator.startAnimation(nil)
      self.progressIndicator.isHidden = false
      self.progressLabel.stringValue = "Working..."
    } else {
      self.progressIndicator.stopAnimation(nil)
      self.progressIndicator.isHidden = true
      self.progressLabel.stringValue = "Ready"
    }
    completionHandler?()
  }
  
  private func handleLoggedIn(_ descriptor: LoginDescriptor) {
    self.loginField.stringValue = ""
    self.passwordField.stringValue = ""
    self.toggleProgress(false) {
      let alert = NSAlert()
      alert.messageText = "You are now logged in!"
      var messages = [String]()
      if descriptor.performMigration {
        messages += ["Migration is required!"]
      } else {
        messages += ["Migration is not required."]
      }
      if let oldUserId = descriptor.oldUserId {
        messages += ["Your old User ID is: \(oldUserId)."]
      }
      if let newUserId = descriptor.newUserId {
        messages += ["Your new User ID is: \(newUserId)."]
      }
      alert.informativeText = messages.joined(separator: " ")
      alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
  }
  
  private func show(error: Error) {
    self.show(title: "An error occurred!", message: error.localizedDescription)
  }
  
  private func show(title: String, message: String) {
    self.toggleProgress(false) {
      let alert = NSAlert()
      alert.messageText = title
      alert.informativeText = message
      alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
  }
  
  private var migrationAllowance: Bool? {
    let allowMigration: Bool?
    switch self.dataMigrationControl.selectedSegment {
    case 1:
      allowMigration = true
    case 2:
      allowMigration = false
    default:
      allowMigration = nil
    }
    
    return allowMigration
  }
  
}

