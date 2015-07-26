//
// Created by Michael Spencer on 5/12/15.
// Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

class StaffingUtils {

    static func hour(hour: UInt) -> NSTimeInterval {
        return NSTimeInterval(hour * 60 * 60)
    }

    static func minutes(minutes: Int) -> NSTimeInterval {
        return NSTimeInterval(minutes * 60)
    }

    static func formattedRecordTime(recordTime: NSTimeInterval) -> String {
        let hours = Int(recordTime/3600)

        let postfix = hours >= 12 ? "PM" : "AM"

        if hours == 0 {
            return "12 \(postfix)"
        } else if hours > 12 {
            return "\(hours - 12) \(postfix)"
        } else {
            return "\(hours) \(postfix)"
        }
    }
    
    static func currentHour() -> NSTimeInterval {
        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitHour | .CalendarUnitMinute, fromDate:  NSDate())
        let currentHour = components.hour
        let currentMinute = components.minute
        
        return self.hour(UInt(currentHour)) + self.minutes(currentMinute)
    }
    
    static func recordDateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }
    
    static func formatStaffing(staffing: Double, includePlusSymbol: Bool = false) -> String {
        let hasFraction = floor(staffing) != staffing
        let prefix = includePlusSymbol && staffing > 0 ? "+" : ""
        
        if hasFraction {
            return String(format: "\(prefix)%.1f", staffing)
        } else {
            return String(format: "\(prefix)%.0f", staffing)
        }
    }
}

extension NSDate {
    static func tomorrow() -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: 1, toDate: NSDate(), options: NSCalendarOptions(rawValue: 0))!
    }
}
