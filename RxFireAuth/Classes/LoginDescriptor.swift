//
//  LoginDescriptor.swift
//  RxFireAuth
//
//  Created by Alessio Moiso on 18/04/2020.
//  Copyright © 2020 Alessio Moiso. All rights reserved.
//

/// A login descriptor represents
/// the result of a login action.
///
/// Instances of this class are returned from all the functions
/// that perform a sign in.
public struct LoginDescriptor {
  
  /// Get the full user name.
  ///
  /// This field inherits its value from the sign in method.
  /// Some sign in methods don't return this information.
  public let fullName: String?
  
  /// Get if this sign in operation requires a data migration.
  ///
  /// This property holds the same value that you have passed
  /// to the `allowMigration` parameter of all the functions
  /// that perform a sign in.
  ///
  /// You can use this value to know if your code actually has to perform
  /// data migration. If `true`, you should detach all
  /// data from `oldUserId` and attach it to `newUserId`.
  public let performMigration: Bool
  
  /// Get the old user ID.
  ///
  /// This property has a value only when a data migration is required.
  /// This is the Firebase `uid` of the anonymous user that has just been deleted and
  /// replaced with an existing account.
  public let oldUserId: String?
  
  /// Get the new user ID.
  ///
  /// This property holds the Firebase `uid` of the user that is currently logged-in
  /// as a result of a sign in action.
  public let newUserId: String?
  
}
