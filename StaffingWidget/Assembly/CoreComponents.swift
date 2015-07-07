//
//  CoreComponents.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-13.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

public class CoreComponents: TyphoonAssembly {
   
    public dynamic func configurationManager() -> AnyObject {
        
        return TyphoonDefinition.withClass(ConfigurationManager.self) {
            (definition) in
            
            definition.injectProperty("configurationClient", with:self.configurationClient())

        }
    }
    
    public dynamic func loginValidator() -> AnyObject {
        return TyphoonDefinition.withClass(LoginValidator.self)
    }
    
    public dynamic func configurationClient() -> AnyObject {
        return TyphoonDefinition.withClass(ConfigurationParseClient.self)
    }
    
    public dynamic func loginClient() -> AnyObject {
        return TyphoonDefinition.withClass(LoginClientParseImplementation.self)
    }
}
