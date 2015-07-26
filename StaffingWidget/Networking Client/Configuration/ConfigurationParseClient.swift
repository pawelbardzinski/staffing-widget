//
//  ConfigurationParseClient.swift
//  StaffingWidget
//
//  Created by Seth Hein on 6/8/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Alamofire

class ConfigurationParseClient:NSObject, ConfigurationClient
{
    func getConfigurationJSON(facilityId: String, successHandler: (configuration: NSDictionary) -> (), failureHandler: (error: NSError) -> () )
    {
        request(ParseRouter.GetFacility(facilityId: facilityId))
        .validate()
        .responseJSON { (request, response, returnObject, error) in
                
            if (error != nil) {
                failureHandler(error: ParseData.error(response, error: error!, data: returnObject))
            } else if let json = (returnObject as? NSDictionary)?["result"] as? NSDictionary {
                 successHandler(configuration: json)
            } else {
                failureHandler(error: ParseData.malformedError())
            }
        }
    }

}
