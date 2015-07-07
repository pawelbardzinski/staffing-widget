//
//  AppDelegate.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-12.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit
import HockeySDK
import Parse

let log = XCGLogger.defaultInstance()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var assembly : ApplicationAssembly!
    
    var window: UIWindow?
    var censusViewController: CensusViewController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Hockey
        BITHockeyManager.sharedHockeyManager().configureWithIdentifier("b6e0f4be6adfdbd785b43bbf32755daf")
        BITHockeyManager.sharedHockeyManager().startManager()
        BITHockeyManager.sharedHockeyManager().authenticator.authenticateInstallation()
        
        
        
        #if DEBUG
            BITHockeyManager.sharedHockeyManager().disableUpdateManager = true
        #endif
        
        log.setup(logLevel: .Debug, showLogLevel: true, showFileNames: true, showLineNumbers: true)
        
        // if we want file logging :
        // log.setup(logLevel: .Debug, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "path/to/file", fileLogLevel: .Debug)


        // Push Notifications
        #if DEBUG
        Parse.setApplicationId("jjQlIo5A3HWAMRMCkH8SnOfimVfCi6QlOV9ZNO2T", clientKey: "BPL9s6qTnzAsikqKZm6eMJaN6eTfRPU20UDFUtyQ")
        #else
        Parse.setApplicationId("5pYOx25qvyg4IVXyu128IuRlbnJtwLgwCTsHXCpO", clientKey: "qjz2kDzJOTZaucLMakiV0a7uUfmGRf20vRLuSNsS")
        #endif

        // Register for Push Notitications
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.respondsToSelector("backgroundRefreshStatus")
            let oldPushHandlerOnly = !self.respondsToSelector("application:didReceiveRemoteNotification:fetchCompletionHandler:")
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
        if application.respondsToSelector("registerUserNotificationSettings:") {
            let userNotificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            let types = UIRemoteNotificationType.Badge | UIRemoteNotificationType.Alert | UIRemoteNotificationType.Sound
            application.registerForRemoteNotificationTypes(types)
        }
        
        // For now, we're not showing the census view on the iPhone, so set the report navigation controller
        // as the root view controller
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.window!.rootViewController! = assembly.storyboard().instantiateViewControllerWithIdentifier("ReportNavController") as! UIViewController
        }
        
        // Push the login view controller if necessary
        if !UserManager.isLoggedIn {
            // The window must be visible before presenting the login view controller
            self.window?.makeKeyAndVisible()
            
            let loginVC : UIViewController! = assembly.loginViewControllerFromStoryboard() as! UIViewController
            self.window!.rootViewController!.presentViewController(loginVC, animated: false, completion: nil)
        }
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            println("Push notifications are not supported in the iOS Simulator.")
        } else {
            println("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if application.applicationState == UIApplicationState.Inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        }
        
        if let reportId = userInfo["reportId"] as? String {
            if application.applicationState == UIApplicationState.Inactive {
                displayReport(reportId)
            } else {
                let alertController = UIAlertController(title: nil,
                        message: ((userInfo["aps"] as! NSDictionary)["alert"]) as? String, preferredStyle: .Alert)
            
                let cancelAction = UIAlertAction(title: "Ignore", style: .Cancel) { (action) in
                    // Ignore...
                }
                alertController.addAction(cancelAction)
                let viewAction = UIAlertAction(title: "View", style: .Default) { (action) in
                    self.displayReport(reportId)
                }
                alertController.addAction(viewAction)
                
                self.reportNavController().presentViewController(alertController, animated: true) {
                    // Ignore completion...
                }
            }
        } else {
            log.warning("Push notification is missing report ID!")
        }
    }
    
    func displayReport(reportId: String) {
        let navController = reportNavController()
        let reportController = assembly.reportViewControllerFromStoryboard() as! ReportViewController
        reportController.reportId = reportId
        reportController.navigationItem.rightBarButtonItem = nil // Don't show the sign out button for a pushed VC
        
        navController.pushViewController(reportController, animated: false)
    }
    
    func reportNavController() -> UINavigationController {

        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return self.window!.rootViewController as! UINavigationController
        } else {
            let tabBarController = self.window?.rootViewController as! UITabBarController
            
            return (tabBarController.viewControllers!)[1] as! UINavigationController
        }
    }
}

