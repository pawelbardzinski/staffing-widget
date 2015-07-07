//
//  LoginClient.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/20/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

@objc protocol LoginClient {
    
    func login(username: String, password: String, successHandler: () -> (), failureHandler: (error: NSError) -> () )
}