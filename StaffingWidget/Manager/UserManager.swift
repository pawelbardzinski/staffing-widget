//
//  UserManager.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/20/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Parse
import Argo

class UserManager: NSObject {

    static var userName : String? {
        get {
            // get from nsuserdefaults
            let defaults = NSUserDefaults.standardUserDefaults()
            return defaults.objectForKey("UserName") as? String
        }
        
        set {
            // store in user defaults
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(newValue, forKey: "UserName")
        }
    }
    
    static var userObjectId : String? {
        get {
            // get from nsuserdefaults
            let defaults = NSUserDefaults.standardUserDefaults()
            return defaults.objectForKey("UserObjectId") as? String
        }
        
        set {
            // store in user defaults
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(newValue, forKey: "UserObjectId")
            
            // associate or disassociate the user from the installation
            // used for push notifications
            let installation = PFInstallation.currentInstallation()
            if (newValue != nil)
            {
                var user = PFUser(withoutDataWithObjectId: userObjectId)
                installation.setObject(user, forKey: "user")

            } else {
                installation.removeObjectForKey("user")
            }
            
            // link the installation with the user, for use in push messaging

            installation.save()
        }
    }
    
    static var facilityId : String? {
        get {
            // get from nsuserdefaults
            let defaults = NSUserDefaults.standardUserDefaults()
            return defaults.objectForKey("FacilityId") as? String
        }
        
        set {
            // store in user defaults
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(newValue, forKey: "FacilityId")
        }
    }
    
    static var roleInfo: RoleInfo? {
        get {
            // get from nsuserdefaults
            let defaults = NSUserDefaults.standardUserDefaults()
            let json = defaults.objectForKey("RoleInfo") as? NSDictionary
    
            if json != nil {
                let roleInfo:Decoded<RoleInfo> = decode(json!)
                return roleInfo.value
            } else {
                return nil
            }
        }
        
        set {
            // store in user defaults
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(newValue != nil ? newValue!.json : nil, forKey: "RoleInfo")
        }
    }
    
    static var sessionToken : String? {
        get {
            // get from nsuserdefaults
            let (dictionary, _) = Locksmith.loadDataForUserAccount(self.userName!)
            return dictionary?.valueForKey("sessionToken") as? String
        }
        
        set {
            // store in user defaults
            Locksmith.saveData(["sessionToken": newValue!], forUserAccount: self.userName!)
        }
    }
    
    static var isLoggedIn : Bool {
        get {
            return (self.userName != nil && self.sessionToken != nil)
        }
    }
    
    static func signOut() {
        Locksmith.deleteDataForUserAccount(self.userName!)
        self.userName = nil
        self.userObjectId = nil
        self.roleInfo = nil
    }
}