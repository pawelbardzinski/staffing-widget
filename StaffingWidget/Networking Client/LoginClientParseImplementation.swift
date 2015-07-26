//
//  LoginClientParseImplementation.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/20/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Parse
import Argo
import Alamofire

class LoginClientParseImplementation:NSObject, LoginClient {
    
    func login(username: String, password: String, successHandler: () -> (), failureHandler: (error: NSError) -> () ) {
        
        request(ParseRouter.Login(username: username, password: password))
        .validate()
        .responseJSON { (request, response, returnObject, error) in
            
            let json = returnObject as! NSDictionary?
            
            if (error != nil)
            {
                failureHandler(error: ParseData.error(response, error: error!, data: returnObject))
            } else {
                
                if let facilityDict = json?["facility"] as? NSDictionary
                {
                    UserManager.facilityId = facilityDict["objectId"] as? String
                } else {
                    failureHandler(error: ParseData.malformedError(description: "Unable to log in!", reason: "Missing facility information"))
                    return
                }
                
                // save the user id
                if let userObjectId = json?["objectId"] as? String
                {
                    UserManager.userObjectId = userObjectId
                } else {
                    failureHandler(error: ParseData.malformedError(description: "Unable to log in!", reason: "Missing user information"))
                    return
                }
                
                if let sessionToken  = json?["sessionToken"] as? String
                {
                    // store the username in ns user defaults
                    UserManager.userName = username
                    
                    // store the session token
                    UserManager.sessionToken = sessionToken
                    
                    let roleId: String? = (json?["roleInfo"] as? NSDictionary)?["objectId"] as? String
                    
                    if roleId != nil {
                        self.getRoleInfo(roleId!, successHandler: { (roleInfo) -> () in
                            UserManager.roleInfo = roleInfo
                            successHandler()
                            }, failureHandler: failureHandler)
                    } else {
                        failureHandler(error: ParseData.malformedError(description: "Unable to log in!", reason: "Missing user role"))
                    }
                } else {
                    failureHandler(error: ParseData.malformedError())
                }
            }
        }
    }
    
    func getRoleInfo(roleId: String, successHandler: (roleInfo: RoleInfo) -> (), failureHandler: (error: NSError) -> () ) {
        request(ParseRouter.ReadObject(className: "RoleInfo", objectId: roleId))
        .validate()
        .responseJSON { (request, response, returnObject, error) in
            
            if (error != nil) {
                failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                    defaultDescription: "Unable to get user's role!"))
            } else if let json = returnObject as? NSDictionary {
                let roleInfo:Decoded<RoleInfo> = decode(json)
                
                switch roleInfo {
                case .Success(let box):
                    successHandler(roleInfo: box.value)
                case .TypeMismatch(let error):
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get user's role!",
                        reason: "Type mismatch: \(error)"))
                case .MissingKey(let key):
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get user's role!",
                        reason: "Missing key: \(key)"))
                }
            } else {
                failureHandler(error: ParseData.malformedError(
                    description: "Unable to get user's role!",
                    reason: "Malformed JSON response."))
            }
        }
    }
}
