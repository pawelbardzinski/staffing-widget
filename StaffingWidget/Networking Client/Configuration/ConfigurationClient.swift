//
//  ConfigurationClient.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-13.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

@objc protocol ConfigurationClient
{
    func getConfigurationJSON(facilityId: String, successHandler: (configuration: NSDictionary) -> (), failureHandler: (error: NSError) -> () )
}
