//
//  ErrorHandling.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 5/26/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

extension UIViewController {
    func displayError(error: NSError, tryAgainCallback: (() -> ())? = nil) {
        log.error("Error: \(error.localizedDescription)")
        
        if let reason = error.localizedFailureReason {
            log.error("Reason: \(reason)")
        }
        
        let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .Alert)
        
        if tryAgainCallback != nil {
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                // Ignore...
            }
            alertController.addAction(cancelAction)
            let tryAgainAction = UIAlertAction(title: "Try again", style: .Default) { (action) in
                tryAgainCallback!()
            }
            alertController.addAction(tryAgainAction)
        } else {
            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                // Ignore...
            }
            alertController.addAction(OKAction)
        }
        
        
        self.presentViewController(alertController, animated: true) {
            // Ignore completion...
        }
    }
}