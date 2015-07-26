//
//  Hospital.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/20/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

import Argo
import Runes

struct Facility {

    var name: String
    var shiftTimes: [NSTimeInterval]

    var nextRecordTime: RecordTimestamp {
        let now = StaffingUtils.currentHour()
        let upcomingTimes = shiftTimes.filter { $0 >= now }

        if upcomingTimes.count > 0 {
            return RecordTimestamp(date: NSDate(), time: upcomingTimes[0])
        } else {
            return RecordTimestamp(date: NSDate.tomorrow(), time: shiftTimes[0])
        }
    }
}

extension Facility: Decodable {
    static func create(name: String)(shiftTimes: [NSTimeInterval]) -> Facility {
        return Facility(name: name, shiftTimes: shiftTimes)
    }

    static func decode(j: JSON) -> Decoded<Facility> {
        return Facility.create
                <^> j <| "name"
                <*> j <|| "shiftTimes"
    }
}
