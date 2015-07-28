//
//  RecordTimestamp.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 5/27/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

struct RecordTimestamp {
    var date: NSDate
    var time: NSTimeInterval

    var dateAndTime: NSDate {
        return date.dateByAddingTimeInterval(time)
    }

    static func now() -> RecordTimestamp {
        return RecordTimestamp(date: NSDate(), time: StaffingUtils.currentHour())
    }
}
