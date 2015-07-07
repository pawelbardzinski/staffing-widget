//
//  RootViewController.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 7/1/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

class RootViewController: UITabBarController {
    
    var assembly: ApplicationAssembly!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Do any additional setup after loading the view.
        var viewControllers = [UIViewController]()
        
        viewControllers.append(assembly.censusNavControllerFromStoryboard() as! UIViewController)
        
        // Only show the worksheet tab if the user has permission to view it
        if UserManager.roleInfo?.viewWorksheet ?? false {
            viewControllers.append(assembly.reportNavControllerFromStoryboard() as! UIViewController)
        }
        
        if UserManager.roleInfo?.viewDashboard ?? false {
            viewControllers.append(assembly.dashboardViewControllerFromStoryboard() as! UIViewController)
        }
        
        self.viewControllers = viewControllers as [AnyObject]
    }

}
