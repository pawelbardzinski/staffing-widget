//
//  StaffingDesign.swift
//  StaffingWidget
//
//  Created by Seth Hein on 6/25/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

enum StaffingColors : Int {
    case LateUnfilledReport, LateUnconfirmedReport, CompleteReport, UpcomingReport;
    
    func color() -> UIColor {
        switch (self) {
        case .CompleteReport:
            return UIColor(red: 80.0/255.0, green: 227.0/255.0, blue: 194.0/255.0, alpha: 1.0)
        case .LateUnfilledReport:
            return UIColor(red: 215.0/255.0, green: 83.0/255.0, blue: 83.0/255.0, alpha: 1.0)
        case .LateUnconfirmedReport:
            return UIColor(red: 245.0/255.0, green: 166.0/255.0, blue: 35.0/255.0, alpha: 1.0)
        case .UpcomingReport:
            return UIColor(red: 217.0/255.0, green: 217.0/255.0, blue: 217.0/255.0, alpha: 1.0)
        default:
            return UIColor.blackColor()
        }
    }
}