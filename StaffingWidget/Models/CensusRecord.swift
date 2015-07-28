//
//  Record.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-14.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Argo
import Runes

enum RecordStatus: String {
    case Unknown = ""
    case New = "new"
    case Saved = "saved"
    case Adjusted = "adjusted"
    case Confirmed = "confirmed"
}

extension RecordStatus: Decodable {
    static func decode(j: JSON) -> Decoded<RecordStatus> {
        switch j {
        case let .String(s):
            return .fromOptional(RecordStatus(rawValue: s))
        default:
            return .TypeMismatch("The record status needs to be represented as a string instead of \(j)")
        }
    }
}

struct CensusRecord: Equatable {
    
    var objectId: String?
    var status: RecordStatus
    
    var gridItems: [GridItem]
    
    var unit: Unit!
    
    var recordDateString:String  // record date in yyyy-mm-dd format
    var recordTime:NSTimeInterval // record time only
    
    var census:Int
    var previousCensus:Int
    
    // TODO: Jim to refactor as an enum?
    var reason:String
    var comments:String!
    
    // MARK: - Read-only properties

    var recordTimestamp: RecordTimestamp {
        let date = StaffingUtils.recordDateFormatter().dateFromString(recordDateString)
        return RecordTimestamp(date: date!, time: recordTime)
    }
    
    var nextRecordTime: NSTimeInterval {
        let index = find(unit.shiftTimes, recordTime)
        
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
        let totalGridStaff = visibleGridItems.reduce(0, combine: { $0 + $1.recommendedStaffForCensus(census)! })
        
        return census == 0 ? 0 : Double(totalGridStaff * 24) / Double(census)
    }
    
    var availableWHPPD: Double {
        let totalAvailableStaff = visibleGridItems.reduce(0, combine: { $0 + $1.availableStaff })
        
        return census == 0 ? 0 : Double(totalAvailableStaff * 24) / Double(census)
    }

    var isLocked: Bool {
        return status == .Confirmed || !canEdit
    }

    // A user can edit a record for up to 30 minutes after the record time
    var canEdit: Bool {
        let lastEditTime = recordTimestamp.dateAndTime.dateByAddingTimeInterval(StaffingUtils.minutes(30))
        let now = NSDate()

        // now < lastEditTime
        return now.compare(lastEditTime) == .OrderedAscending
    }

    var changeDescriptions: [String] {
        return gridItems.flatMap({ $0.changeDescriptions })
    }

    func gridItemForStaffType(staffTypeName: String) -> GridItem? {
        let matchingGridItems = gridItems.filter { $0.staffTypeName == staffTypeName }

        if matchingGridItems.count == 1 {
            return matchingGridItems[0]
        } else {
            return nil
        }
    }

    mutating func addChange(change: StaffChange) {
        let gridItem = gridItemForStaffType(change.staffTypeName)

        if gridItem != nil {
            let index = find(gridItems, gridItem!)

            gridItems[index!].addChange(change)
        } else {
            log.error("Staff type for change not found!")
        }
    }

    mutating func resetChanges() {
        for i in 0..<gridItems.count {
            gridItems[i].changes = []
        }
    }
    
    // MARK: - JSON generation
    
    var json: [String: AnyObject] {
        return [
            "unit": ParseData.pointer("Unit", objectId: unit.objectId),
            "recordDateString": recordDateString,
            "recordTime": recordTime,
            "census": census,
            "status": status.rawValue,
            "reason": reason,
            "comments": comments,
            "gridItems": ParseData.relation("GridItem")
        ]
    }
    
    var jsonChanges: [String: AnyObject] {
        return [
            "census": census,
            "reason": reason,
            "status": status.rawValue,
            "comments": comments
        ]
    }
}

func ==(lhs: CensusRecord, rhs: CensusRecord) -> Bool {
    return (lhs.objectId == rhs.objectId) && (lhs.unit == rhs.unit)
}

extension CensusRecord: Decodable {
    static func create(objectId: String?)(status: RecordStatus)(gridItems: [GridItem]?)(unit: Unit)(recordDateString: String)(recordTime: NSTimeInterval)(census: Int)(previousCensus: Int?)(reason: String)(comments: String?) -> CensusRecord {
        return CensusRecord(objectId: objectId, status: status, gridItems: gridItems ?? [], unit: unit, recordDateString: recordDateString,
            recordTime: recordTime, census: census, previousCensus: previousCensus ?? 0, reason: reason, comments: comments)
    }
    
    static func decode(j: JSON) -> Decoded<CensusRecord> {
        return CensusRecord.create
            <^> j <|? "objectId"
            <*> j <| "status"            
            <*> j <||? "gridItems"
            <*> j <| "unit"
            <*> j <| "recordDateString"
            <*> j <| "recordTime"
            <*> j <| "census"
            <*> j <|? "previousCensus"
            <*> j <| "reason"
            <*> j <|? "comments"
    }
}
