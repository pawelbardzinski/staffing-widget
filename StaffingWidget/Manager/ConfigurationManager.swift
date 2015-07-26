//
//  ConfigurationManager.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-12.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit
import Argo

class ConfigurationManager: NSObject {
    
    // MARK: - Properties
    
    var configurationClient:ConfigurationClient!
    
    func getFacilityDefaults(facilityId: String, successHandler: () -> (), failureHandler: (error: NSError) -> () ) {
        configurationClient.getConfigurationJSON(facilityId, successHandler: { (facilityJSON) -> () in
        
            // save facility to NSUserDefaults
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(facilityJSON, forKey: "Facility")
            
            successHandler()
            
        }) { (error) -> () in
            failureHandler(error: error)
        }
    }
    
}
