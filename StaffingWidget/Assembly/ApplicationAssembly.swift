//
//  ApplicationAssembly.swift
//  TalkTime
//
//  Created by Seth Hein on 4/8/15.
//  Copyright (c) 2015 reallyseth.com. All rights reserved.
//


public class ApplicationAssembly: TyphoonAssembly {
    
    // MARK: - Bootstrapping
    
    /*
    * These are modules - assemblies collaborate to provie components to this one.  At runtime you
    * can instantiate Typhoon with any assembly tha satisfies the module interface.
    */

    var coreComponents : CoreComponents!
    
    /*
    * This is the definition for our AppDelegate. Typhoon will inject the specified properties
    * at application startup.
    */
    public dynamic func appDelegate() -> AnyObject {
        return TyphoonDefinition.withClass(AppDelegate.self) {
            (definition) in
            
            definition.injectProperty("assembly", with: self)
            definition.injectProperty("censusViewController", with:self.censusViewController())
        }
    }
    
    public dynamic func censusViewController() -> AnyObject {
        return TyphoonDefinition.withClass(CensusViewController.self) {
            (definition) in
            
            definition.injectProperty("assembly", with: self)
            definition.injectProperty("configurationManager", with: self.coreComponents.configurationManager())
        }
    }
    
    public dynamic func censuslistTVC() -> AnyObject {
        return TyphoonDefinition.withClass(CensusListTVC.self) {
            (definition) in
            definition.injectProperty("configurationManager", with: self.coreComponents.configurationManager())
            definition.injectProperty("assembly", with: self)
        }
    }
    
    public dynamic func reportViewController() -> AnyObject {
        return TyphoonDefinition.withClass(ReportViewController.self) {
            (definition) in
            
            definition.injectProperty("assembly", with: self)
        }
    }
    
    public dynamic func loginViewController() -> AnyObject {
        return TyphoonDefinition.withClass(LoginViewController.self) {
            (definition) in
            
            definition.injectProperty("loginClient", with: self.coreComponents.loginClient())
            definition.injectProperty("configurationManager", with: self.coreComponents.configurationManager())
        }
    }
    
    public dynamic func rootViewController() -> AnyObject {
        return TyphoonDefinition.withClass(RootViewController.self) {
            (definition) in
            
            definition.injectProperty("assembly", with: self)
        }
    }
    
    public dynamic func storyboard() -> AnyObject {
        return TyphoonDefinition.withClass(TyphoonStoryboard.self) {
            (definition) in
            
            definition.useInitializer("storyboardWithName:factory:bundle:", parameters: { (initializer : TyphoonMethod!) -> Void in
                initializer.injectParameterWith("Main")
                initializer.injectParameterWith(self)
                initializer.injectParameterWith(NSBundle.mainBundle())
            })
        }
    }
    
    public dynamic func loginViewControllerFromStoryboard() -> AnyObject {
        return TyphoonDefinition.withFactory(self.storyboard(), selector: "instantiateViewControllerWithIdentifier:", parameters: {
            (factoryMethod) in
            factoryMethod.injectParameterWith("LoginViewController")
        })
    }
    
    public dynamic func reportViewControllerFromStoryboard() -> AnyObject {
        return TyphoonDefinition.withFactory(self.storyboard(), selector: "instantiateViewControllerWithIdentifier:", parameters: {
            (factoryMethod) in
            factoryMethod.injectParameterWith("ReportViewController")
        })
    }
    
    public dynamic func censusNavControllerFromStoryboard() -> AnyObject {
        return TyphoonDefinition.withFactory(self.storyboard(), selector: "instantiateViewControllerWithIdentifier:", parameters: {
            (factoryMethod) in
            factoryMethod.injectParameterWith("CensusNavController")
        })
    }
    
    public dynamic func reportNavControllerFromStoryboard() -> AnyObject {
        return TyphoonDefinition.withFactory(self.storyboard(), selector: "instantiateViewControllerWithIdentifier:", parameters: {
            (factoryMethod) in
            factoryMethod.injectParameterWith("ReportNavController")
        })
    }
    
    public dynamic func dashboardViewControllerFromStoryboard() -> AnyObject {
        return TyphoonDefinition.withFactory(self.storyboard(), selector: "instantiateViewControllerWithIdentifier:", parameters: {
            (factoryMethod) in
            factoryMethod.injectParameterWith("DashboardViewController")
        })
    }
}
