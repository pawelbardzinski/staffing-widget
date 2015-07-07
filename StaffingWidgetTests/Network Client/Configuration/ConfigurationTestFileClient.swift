//
//  ConfigurationTestFileClient.swift
//  StaffingWidget
//
//  Created by David Oliver on 6/24/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

class ConfigurationTestFileClient:NSObject, ConfigurationClient
{
    
    let resourcePath = "testdefaults"
    
    func getConfigurationJSON(facilityId: String, successHandler: (configuration: NSDictionary) -> (), failureHandler: (error: NSError) -> () )
    {
        var loadingError: NSError?
        
        if let path = NSBundle(forClass: ConfigurationTestFileClient.self).pathForResource(resourcePath, ofType: "json")
        {
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
        } else {
            loadingError = NSError(domain: "local", code: -1, userInfo: nil)
            failureHandler(error: loadingError!)
        }
    }
    
    func getUnitsJSON(facilityId: String, successHandler: (configuration: NSDictionary) -> (), failureHandler: (error: NSError) -> () )
    {
        getConfigurationJSON(facilityId, successHandler: successHandler, failureHandler: failureHandler)
    }
}