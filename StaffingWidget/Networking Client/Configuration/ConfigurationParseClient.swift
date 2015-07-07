//
//  ConfigurationParseClient.swift
//  StaffingWidget
//
//  Created by Seth Hein on 6/8/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

class ConfigurationParseClient:NSObject, ConfigurationClient
{
    func getConfigurationJSON(facilityId: String, successHandler: (configuration: NSDictionary) -> (), failureHandler: (error: NSError) -> () )
    {
        request(ParseRouter.ReadObject(className: "Facility", objectId: facilityId))
        .validate()
        .responseJSON { (request, response, returnObject, error) in
                
            let json = returnObject as! NSDictionary?
            
            if (error != nil)
            {
                failureHandler(error: ParseData.error(response, error: error!, data: returnObject))
            } else {
                
                 successHandler(configuration: json!)
            }
        }
    }
    
    func getUnitsJSON(facilityId: String, successHandler: (configuration: NSDictionary) -> (), failureHandler: (error: NSError) -> () )
    {
        request(ParseRouter.GetUnitsForFacility(facilityId: facilityId))
        .validate()
        .responseJSON { (request, response, returnObject, error) in
            
            let json = returnObject as! NSDictionary?
            
            if (error != nil)
            {
                failureHandler(error: ParseData.error(response, error: error!, data: returnObject))
            } else {
                successHandler(configuration: json!)
            }
        }
    }
}