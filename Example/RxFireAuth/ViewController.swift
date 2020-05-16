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

/// This class shows you an example of almost all the features that
/// RxFireAuth supports.
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
    
    @IBOutlet weak var providersField: UILabel!
    
    private var userManager: UserManagerType & LoginProviderManagerType = UserManager()
    private var disposeBag = DisposeBag()
    
    private var progressDialog: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Registering to `autoupdatingUser` gives us
        /// an observable that emits a new value every time something
        /// on the user changes.
        ///
        /// You should use this to bind your UI to make sure that
        /// everything is always updated.
        self.userManager.autoupdatingUser
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (user) in
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
                    
                    self.providersField.text = user.authenticationProviders.map { $0.rawValue }.joined(separator: ", ")
                } else {
                    self.welcomeLabel.text = "Welcome!"
                    self.subtitleLabel.text = "You are not logged-in."
                    self.providersField.text = "Not logged-in."
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
    
    override func viewDidAppear(_ animated: Bool) {
        self.loginField.becomeFirstResponder()
    }
    
    /// Login with email and password or anonymously based
    /// on if there is something written in the email field.
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
                .subscribe(onSuccess: self.handleLoggedIn(_:), onError: { [unowned self] error in
                    if case UserError.migrationRequired(let credentials) = error {
                        self.handleMigration(credentials: credentials)
                    } else {
                        self.show(error: error)
                    }
                })
                .disposed(by: self.disposeBag)
        }
    }
    
    /// Start the Sign in with Apple flow.
    @IBAction func signInWithApple(sender: AnyObject) {
        if #available(iOS 13.0, *) {
            self.userManager.signInWithApple(in: self, updateUserDisplayName: true, allowMigration: self.migrationAllowance)
                .subscribe(onSuccess: self.handleLoggedIn(_:), onError: { [unowned self] error in
                    if case UserError.migrationRequired(let credentials) = error {
                        self.handleMigration(credentials: credentials)
                    } else {
                        self.show(error: error)
                    }
                })
                .disposed(by: self.disposeBag)
        } else {
            self.show(title: "Sign in with Apple is not available on iOS 12 or earlier.", message: "Use a device running iOS 13 or later to test this feature.")
        }
    }
    
    /// Sign out.
    @IBAction func signOut(sender: AnyObject) {
        self.toggleProgress(true)
        self.userManager.logout(resetToAnonymous: self.resetAnononymousSwitch.isOn)
            .subscribe(onCompleted: { [unowned self] in
                self.toggleProgress(false)
            }, onError: self.show(error:))
            .disposed(by: self.disposeBag)
    }
    
    /// Update the user display name using the
    /// value of the name field.
    @IBAction func updateProfile(sender: AnyObject) {
        self.toggleProgress(true)
        self.userManager.update { [unowned self] (userData) -> UserData in
                var user = userData
                user.displayName = self.nameField.text
                return user
            }.subscribe(onCompleted: { [unowned self] in
                self.toggleProgress(false)
            }, onError: self.show(error:))
            .disposed(by: self.disposeBag)
    }
    
    /// Set or update the user password.
    ///
    /// This function verifies if the user already has a password set or not.
    /// You can skip this check and call the library directly, but you keep in mind
    /// that if a user already has a password set they must reauthenticate to change it.
    @IBAction func changePassword(sender: AnyObject) {
        self.toggleProgress(true)
        self.userManager.autoupdatingUser
            .take(1)
            .filter { $0 != nil }.map { $0! }
            .map { $0.authenticationProviders }
            .subscribe(onNext: { [unowned self] (authenticationProviders) in
                self.toggleProgress(false) { [unowned self] in
                    if authenticationProviders.contains(.password) {
                        self.changeExistingPassword()
                    } else {
                        self.setNewPassword()
                    }
                }
            }).disposed(by: self.disposeBag)
    }
    
    /// Delete the currently logged-in account.
    @IBAction func deleteAccount(sender: AnyObject) {
        self.toggleProgress(true)
        self.userManager.deleteUser(resetToAnonymous: self.resetAnononymousSwitch.isOn)
            .subscribe(onCompleted: { [unowned self] in
                self.toggleProgress(false)
            }, onError: self.show(error:))
            .disposed(by: self.disposeBag)
    }
    
    /// Confirm credentials and then ask for a new password.
    private func changeExistingPassword() {
        let alertController = UIAlertController(title: "Confirm Credentials", message: "Insert your current password below:", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Current Password"
            if #available(iOS 11, *) {
                textField.textContentType = .password
            }
            textField.isSecureTextEntry = true
        }
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [unowned self] _ in
            alertController.dismiss(animated: true)
            
            self.userManager.confirmAuthentication(email: self.userManager.user!.email!, password: alertController.textFields!.first!.text!)
                .observeOn(MainScheduler.instance)
                .subscribe(onCompleted: self.setNewPassword, onError: self.show(error:))
                .disposed(by: self.disposeBag)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// Immediately ask for a new password.
    private func setNewPassword() {
        let alertController = UIAlertController(title: "New Password", message: "Insert your new password below:", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "New Password"
            if #available(iOS 11, *) {
                textField.textContentType = .password
            }
            textField.isSecureTextEntry = true
        }
        alertController.addAction(UIAlertAction(title: "Set", style: .default, handler: { [unowned self] _ in
            alertController.dismiss(animated: true)
            
            self.userManager.updatePassword(newPassword: alertController.textFields!.first!.text!)
                .observeOn(MainScheduler.instance)
                .subscribe(onCompleted: { [unowned self] in
                    self.show(title: "Password set!", message: "Your new password has been set.")
                }, onError: self.show(error:))
                .disposed(by: self.disposeBag)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// This function is called when a login operation has failed because of a `UserError.migrationRequired` error.
    ///
    /// After having asked to the user what they would like to do with their existing data, you can continue the flow
    /// using `login(with credentials:updateUserDisplayName:allowMigration:)`. No credentials are
    /// passed when the `UserError.migrationRequired` error is thrown during a sign in with email and password, because
    /// a new login attempt can be made seamlessly without asking anything to the user.
    private func handleMigration(credentials: LoginCredentials?) {
        let migrationAlert = UIAlertController(title: "Migration Required", message: "You are trying to login into an existing account while being logged-in with an anonymous account. When doing this in a real app, you should check if the user has data in the anonymous account and, if so, offer the option to merge the anonymous account with the one that the user is trying to sign into.", preferredStyle: .actionSheet)
        migrationAlert.addAction(UIAlertAction(title: "Migrate", style: .destructive, handler: { [unowned self] _ in
            if let credentials = credentials {
                self.userManager.login(with: credentials, updateUserDisplayName: true, allowMigration: true)
                    .subscribe(onSuccess: self.handleLoggedIn(_:), onError: self.show(error:))
                    .disposed(by: self.disposeBag)
            } else {
                self.userManager.login(email: self.loginField.text!, password: self.passwordField.text!, allowMigration: true)
                    .subscribe(onSuccess: self.handleLoggedIn(_:), onError: self.show(error:))
                    .disposed(by: self.disposeBag)
            }
        }))
        migrationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(migrationAlert, animated: true, completion: nil)
    }
    
    // MARK: - Utilities
    
    private func toggleProgress(_ show: Bool, completionHandler: (() -> Void)? = nil) {
        if show {
            self.progressDialog = UIAlertController(title: "Working…", message: nil, preferredStyle: .alert)
            self.present(self.progressDialog!, animated: true, completion: completionHandler)
        } else {
            if let progressDialog = self.progressDialog {
                progressDialog.dismiss(animated: true, completion: completionHandler)
            } else {
                completionHandler?()
            }
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

}

