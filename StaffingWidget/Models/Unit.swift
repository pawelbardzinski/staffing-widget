//
//  Unit.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-12.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit
import Argo
import Runes

struct Unit: Equatable {
   
    var objectId = ""
    var name = ""
    var floor : Int?
    var maxCensus = 0
    var shiftTimes = [NSTimeInterval]()
    var varianceReasons = [String]()
    
    
    // MARK: - Methods for testing with fake data
    
    func nextRecordTime() -> NSTimeInterval {
        
        var filteredShifts = shiftTimes.filter { $0 >= StaffingUtils.currentHour() }
        if (filteredShifts.count > 0)
        {
            return filteredShifts[0]
        } else
        {
            return 0
        }
    }
    
    func hasBeenRecorded(recordTime: NSTimeInterval) -> Bool {
        return recordTime < StaffingUtils.currentHour()
    }
    
}

func ==(lhs: Unit, rhs: Unit) -> Bool {
    return lhs.objectId == rhs.objectId
}

// MARK: - JSON Decoding

extension Unit: Decodable {
    static func create(objectId: String)(name: String)(floor: Int?)(maxCensus: Int)(shiftTimes: [NSTimeInterval])(varianceReasons: [String]) -> Unit {
        return Unit(objectId: objectId, name: name, floor: floor, maxCensus: maxCensus, shiftTimes: shiftTimes, varianceReasons: varianceReasons)
    }
    
    static func decode(j: JSON) -> Decoded<Unit> {
        return Unit.create
            <^> j <| "objectId"
            <*> j <| "name"
            <*> j <|? "floor" // Use ? for parsing optional values
            <*> j <| "maxCensus"
            <*> j <|| "shiftTimes" // parse arrays of objects
            <*> j <|| "varianceReasons" // parse arrays of objects
    }
}




