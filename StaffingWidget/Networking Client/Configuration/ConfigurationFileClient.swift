//
//  ConfigurationFileClient.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-13.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

class ConfigurationFileClient:NSObject, ConfigurationClient
{
    
    
    func getConfigurationJSON(facilityId: String, successHandler: (configuration: NSDictionary) -> (), failureHandler: (error: NSError) -> () )
    {
        #if DEBUG
        let resourcePath = "defaults"
        #else
        let resourcePath = "defaults-release"
        #endif
        
        if let path = NSBundle.mainBundle().pathForResource(resourcePath, ofType: "json")
        {
            var loadingError: NSError?
            
            if let jsonData = NSData(contentsOfFile:path, options: .DataReadingMappedIfSafe, error: &loadingError) {
                
                var jsonerror :NSError?
                if let json: NSDictionary = NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers, error: &jsonerror) as? NSDictionary {
                    successHandler(configuration: json)
                } else if (jsonerror != nil) {
                    failureHandler(error: jsonerror!)
                }
            } else if (loadingError != nil) {
                failureHandler(error: loadingError!)
            }
        }
    }
}
