//
//  Report.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-14.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Argo
import Runes

struct Report {
    
    var objectId: String?
    
    var gridItems: [GridItem]
    
    var unit: Unit!
    
    var reportingDateString:String  // report date in yyyy-mm-dd format
    var reportingTime:NSTimeInterval // report time only
    
    var census:Int
    var previousCensus:Int
    
    var confirmed:Bool
    
    // TODO: Jim to refactor as an enum?
    var reason:String
    var comments:String!
    
    // MARK: - Read-only properties
    
    var nextReportingTime: NSTimeInterval {
        let index = find(unit.shiftTimes, reportingTime)
        
        if index != nil && index! < unit.shiftTimes.count - 1 {
            return unit.shiftTimes[index! + 1]
        } else {
            return unit.shiftTimes[0]
        }
    }
    
    var visibleGridItems: [GridItem] {
        return gridItems.filter { $0.visible || $0.required }
    }
    
    var maxCensus: Int {
        return gridItems.reduce(Int.max, combine: { min($0, $1.maxCensus) })
    }
    
    var gridWHPPD: Double {
        let totalGridStaff = visibleGridItems.reduce(0, combine: { $0 + $1.gridStaffForCensus(census)! })
        
        return census == 0 ? 0 : Double(totalGridStaff * 24) / Double(census)
    }
    
    var actualWHPPD: Double {
        let totalActualStaff = visibleGridItems.reduce(0, combine: { $0 + $1.actualStaff })
        
        return census == 0 ? 0 : Double(totalActualStaff * 24) / Double(census)
    }
    
    // MARK: - JSON generation
    
    var json: [String: AnyObject] {
        return [
            "unit": ParseData.pointer("Unit", objectId: unit.objectId),
            "reportingDateString": reportingDateString,
            "reportingTime": reportingTime,
            "census": census,
            "reason": reason,
            "comments": comments,
            "confirmed": confirmed,
            "gridItems": ParseData.relation("GridItem")
        ]
    }
    
    var jsonChanges: [String: AnyObject] {
        return [
            "census": census,
            "reason": reason,
            "comments": comments,
            "confirmed": confirmed
        ]
    }
}

extension Report: Decodable {
    static func create(objectId: String?)(gridItems: [GridItem]?)(unit: Unit)(reportingDateString: String)(reportingTime: NSTimeInterval)(census: Int)(previousCensus: Int?)(confirmed: Bool)(reason: String)(comments: String?) -> Report {
        return Report(objectId: objectId, gridItems: gridItems ?? [], unit: unit, reportingDateString: reportingDateString,
            reportingTime: reportingTime, census: census, previousCensus: previousCensus ?? 0, confirmed: confirmed, reason: reason, comments: comments)
    }
    
    static func decode(j: JSON) -> Decoded<Report> {
        return Report.create
            <^> j <|? "objectId"
            <*> j <||? "gridItems"
            <*> j <| "unit"
            <*> j <| "reportingDateString"
            <*> j <| "reportingTime"
            <*> j <| "census"
            <*> j <|? "previousCensus"
            <*> j <| "confirmed"
            <*> j <| "reason"
            <*> j <|? "comments"
    }
}