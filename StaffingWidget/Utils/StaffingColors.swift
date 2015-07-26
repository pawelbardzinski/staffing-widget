//
//  StaffingDesign.swift
//  StaffingWidget
//
//  Created by Seth Hein on 6/25/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

enum StaffingColors {
    case LateUnfilledRecord, LateUnconfirmedRecord, CompleteRecord, UpcomingRecord
    case FlexOff(highlighted: Bool)
    case CallInExtra(highlighted: Bool)
    
    func color() -> UIColor {
        switch (self) {
        case .CompleteRecord:
            return UIColor(red: 80.0/255.0, green: 227.0/255.0, blue: 194.0/255.0, alpha: 1.0)
        case .LateUnfilledRecord:
            return UIColor(red: 215.0/255.0, green: 83.0/255.0, blue: 83.0/255.0, alpha: 1.0)
        case .LateUnconfirmedRecord:
            return UIColor(red: 245.0/255.0, green: 166.0/255.0, blue: 35.0/255.0, alpha: 1.0)
        case .UpcomingRecord:
            return UIColor(red: 217.0/255.0, green: 217.0/255.0, blue: 217.0/255.0, alpha: 1.0)
        case .FlexOff(let highlighted):
            return UIColor(red:0.96, green:0.26, blue:0.21, alpha: highlighted ? 0.2 : 0.1)
        case .CallInExtra(let highlighted):
            return UIColor(red:0.3, green:0.69, blue:0.31, alpha: highlighted ? 0.2 : 0.1)
        default:
            return UIColor.blackColor()
        }
    }
}
