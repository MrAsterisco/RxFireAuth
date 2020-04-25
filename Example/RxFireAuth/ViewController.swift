//
//  ViewController.swift
//  RxFireAuth
//
//  Created by Alessio Moiso on 04/18/2020.
//  Copyright (c) 2020 Alessio Moiso. All rights reserved.
//

import UIKit
import RxFireAuth
import RxSwift
import RxCocoa

class ViewController: UITableViewController {

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var loginField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    
    @IBOutlet weak var dataMigrationControl: UISegmentedControl!
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var updateProfileButton: UIButton!
    
    @IBOutlet weak var resetAnononymousSwitch: UISwitch!
    
    private var userManager: UserManagerType & LoginProviderManagerType = UserManager()
    private var disposeBag = DisposeBag()
    
    private var progressDialog: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userManager.autoupdatingUser
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (user) in
                if let user = user {
                    if user.isAnonymous {
                        self.welcomeLabel.text = "Welcome, Anonymous!"
                        self.subtitleLabel.text = "You are logged-in with an anonymous account."
                    } else {
                        if let displayName = user.displayName, displayName.count > 0 {
                            self.welcomeLabel.text = "Welcome, \(displayName)!"
                        } else {
                            self.welcomeLabel.text = "Welcome!"
                        }
                        self.subtitleLabel.text = "You are logged-in with \(user.email ?? "unknown")."
                    }
                    self.nameField.text = user.displayName
                } else {
                    self.welcomeLabel.text = "Welcome!"
                    self.subtitleLabel.text = "You are not logged-in."
                }
            }).disposed(by: self.disposeBag)
        
        self.loginField.rx.text
            .map { ($0 ?? "").count > 0 }
            .withLatestFrom(self.userManager.autoupdatingUser.map({ $0 != nil })) { hasEmail, isLoggedIn -> String in
                if !hasEmail && !isLoggedIn {
                    return "Sign in anonymously"
                } else if isLoggedIn && hasEmail {
                    return "Link"
                } else if isLoggedIn && !hasEmail {
                    return "Insert an email address to link it!"
                }
                return "Sign in"
            }
            .bind(to: self.signInButton.rx.title())
            .disposed(by: self.disposeBag)
    }
    
    private var migrationAllowance: Bool? {
        let allowMigration: Bool?
        switch self.dataMigrationControl.selectedSegmentIndex {
        case 1:
            allowMigration = true
        case 2:
            allowMigration = false
        default:
            allowMigration = nil
        }
        
        return allowMigration
    }
    
    @IBAction func signIn(sender: AnyObject) {
        self.toggleProgress(true)
        if self.loginField.text?.count == 0 {
            self.userManager.loginAnonymously()
                .subscribe(onCompleted: {
                    self.toggleProgress(false)
                }, onError: self.show(error:))
                .disposed(by: self.disposeBag)
        } else {
            self.userManager.login(email: self.loginField.text!, password: self.passwordField.text!, allowMigration: self.migrationAllowance)
                .subscribe(onSuccess: self.handleLoggedIn(_:), onError: self.show(error:))
                .disposed(by: self.disposeBag)
        }
    }
    
    @IBAction func signInWithApple(sender: AnyObject) {
        if #available(iOS 13.0, *) {
            self.userManager.signInWithApple(in: self, updateUserDisplayName: true, allowMigration: self.migrationAllowance)
                .subscribe(onSuccess: self.handleLoggedIn(_:), onError: self.show(error:))
                .disposed(by: self.disposeBag)
        } else {
            self.show(title: "Sign in with Apple is not available on iOS 12 or earlier.", message: "Use a device running iOS 13 or later to test this feature.")
        }
    }
    
    @IBAction func signOut(sender: AnyObject) {
        self.toggleProgress(true)
        self.userManager.logout(resetToAnonymous: self.resetAnononymousSwitch.isOn)
            .subscribe(onCompleted: {
                self.toggleProgress(false)
            }, onError: self.show(error:))
            .disposed(by: self.disposeBag)
    }
    
    @IBAction func updateProfile(sender: AnyObject) {
        self.toggleProgress(true)
        self.userManager.update { (userData) -> UserData in
                var user = userData
                user.displayName = self.nameField.text
                return user
            }.subscribe(onCompleted: {
                self.toggleProgress(false)
            }, onError: self.show(error:))
            .disposed(by: self.disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.loginField.becomeFirstResponder()
    }
    
    private func toggleProgress(_ show: Bool, completionHandler: (() -> Void)? = nil) {
        if show {
            self.progressDialog = UIAlertController(title: "Working…", message: nil, preferredStyle: .alert)
            self.present(self.progressDialog!, animated: true, completion: completionHandler)
        } else {
            self.progressDialog?.dismiss(animated: true, completion: completionHandler)
        }
    }
    
    private func handleLoggedIn(_ descriptor: LoginDescriptor) {
        self.loginField.text = nil
        self.passwordField.text = nil
        self.toggleProgress(false) { [unowned self] in
            let alertController = UIAlertController(title: "You are now logged in!", message: nil, preferredStyle: .alert)
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
            alertController.message = messages.joined(separator: " ")
            alertController.addAction(UIAlertAction(title: "Cool!", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func show(error: Error) {
        self.show(title: "An error occurred!", message: error.localizedDescription)
    }
    
    private func show(title: String, message: String) {
        self.toggleProgress(false) { [unowned self] in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }

}

