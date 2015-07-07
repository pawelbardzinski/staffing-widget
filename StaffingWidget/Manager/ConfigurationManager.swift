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
    
    func getUnitsForFacility(facilityId: String, successHandler: (units: Array<Unit>) -> (), failureHandler: (error: NSError) -> () ) {
        configurationClient.getUnitsJSON(facilityId, successHandler: { (unitsJSON) -> () in

            // take the items into an array down the items into an array
            var unitNames:[String]
            if let unitsJSONArray = unitsJSON["results"] as? Array<NSDictionary>
            {
                let units:Decoded<[Unit]> = decode(unitsJSONArray)
                
                switch units {
                case .Success(let box):
                    successHandler(units: box.value)
                case .TypeMismatch(let error):
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the units configuration!",
                        reason: "Type mismatch: \(error)"))
                case .MissingKey(let key):
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the units configuration!",
                        reason: "Missing key: \(key)"))
                }
            } else {
                successHandler(units: [])
            }
            
        }) { (error) -> () in
            failureHandler(error: error)
        }
    }
    
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
