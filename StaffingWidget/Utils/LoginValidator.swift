//
//  LoginValidator.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/13/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

class LoginValidator:NSObject {

    static func isValidEmailAddress(email: NSString!) -> Bool {
        let emailRegEx : NSString = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        
        let isValid :Bool = emailTest.evaluateWithObject(email)
        
        return isValid;
    }
    
    static func isValidPassword(password: NSString!) -> Bool {
        if password == nil || password.length==0{
            return false
        }
        let whitespaceSet = NSCharacterSet.whitespaceCharacterSet()
        let range = password.rangeOfCharacterFromSet(whitespaceSet)
        if range.length > 0 {
            return false
        }
        return true
    }
}