//
// Created by Michael Spencer on 7/13/15.
// Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

import Argo
import Runes

struct Worksheet {

    // MARK: - Parse properties
    
    var facilityId: String

    var recordDateString: String
    // record date in yyyy-mm-dd format
    var recordTime: NSTimeInterval
    // record time only

    var records: [CensusRecord]

    var changes: [StaffChange]

    // Dictionary of [staffTypeName: availableStaff]
    var floatPool: [FloatPoolItem]

    init(facilityId: String, recordDateString: String, recordTime: NSTimeInterval, records: [CensusRecord], changes: [StaffChange], floatPool: [FloatPoolItem]) {
        self.facilityId = facilityId
        self.recordDateString = recordDateString
        self.recordTime = recordTime
        self.records = records
        self.changes = changes
        self.floatPool = floatPool

        reset(childrenOnly: true)

        for change in changes {
            addChange(change, addToChanges: false)
        }
    }

    // MARK: - Read-only properties

    var recordTimestamp: RecordTimestamp {
        let date = StaffingUtils.recordDateFormatter().dateFromString(recordDateString)
        return RecordTimestamp(date: date!, time: recordTime)
    }

    // A user can edit the worksheet for up to 30 minutes after the record time
    var canEdit: Bool {
        let lastEditTime = recordTimestamp.dateAndTime.dateByAddingTimeInterval(StaffingUtils.minutes(30))
        let now = NSDate()

        // now < lastEditTime
        return now.compare(lastEditTime) == .OrderedAscending
    }

    var changesDescription: String {
        return " • " + ("\n • ".join(changes.map({ $0.description })))
    }

    // Only unconfirmed records can be reset
    var resettable: Bool {
        return records.filter({ $0.status == RecordStatus.Confirmed }).count == 0
    }

    var staffTypeNames: [String] {
        return records.flatMap({ $0.gridItems.map({ $0.staffTypeName }) }).unique()
    }

    // MARK: - JSON generation

    var json: [String:AnyObject] {
        return [
            "facilityId": facilityId,
            "changes": changes.map { $0.json },
            "floatPool": floatPool.map { $0.json },
            "recordTime": recordTime,
            "recordDateString": recordDateString
        ]
    }

    // MARK: - Methods

    func indexOfUnit(unit: Unit!) -> Int? {
        if unit != nil {
            var matchingRecords = records.filter {
                $0.unit == unit
            }

            if matchingRecords.count == 1 {
                return find(records, matchingRecords[0])
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func indexOfFloatItem(staffTypeName: String!) -> Int? {
        if staffTypeName != nil {
            var matches = floatPool.filter { $0.staffTypeName == staffTypeName }
            
            if matches.count == 1 {
                return find(floatPool, matches[0])
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    mutating func moveStaff(staffTypeName: String, fromUnit: Unit, toUnit: Unit) {
        let change = StaffChange(changeType: .Move, staffTypeName: staffTypeName,
                count: 1, fromUnit: fromUnit, toUnit: toUnit)

        addChange(change)
    }

    mutating func callInExtra(staffTypeName: String, toUnit: Unit) {
        let change = StaffChange(changeType: .CallInExtra, staffTypeName: staffTypeName,
                count: 1, fromUnit: nil, toUnit: toUnit)

        addChange(change)
    }

    mutating func floatIn(staffTypeName: String, toUnit: Unit) {
        let change = StaffChange(changeType: .FloatIn, staffTypeName: staffTypeName,
                count: 1, fromUnit: nil, toUnit: toUnit)

        addChange(change)
    }

    mutating func flexOff(staffTypeName: String, fromUnit: Unit) {
        let change = StaffChange(changeType: .FlexOff, staffTypeName: staffTypeName,
                count: 1, fromUnit: fromUnit, toUnit: nil)

        addChange(change)
    }

    mutating func reset(childrenOnly: Bool = false) {
        if !childrenOnly {
            changes = []
        }

        for i in 0 ..< records.count {
            records[i].resetChanges()
        }

        for i in 0 ..< floatPool.count {
            floatPool[i].changes = []
        }
    }

    func gridItemForChange(change: StaffChange) -> GridItem? {
        if change.toUnit != nil {
            var index = indexOfUnit(change.toUnit)

            if index != nil {
                return records[index!].gridItemForStaffType(change.staffTypeName)
            }
        }

        return nil
    }

    mutating func addChange(change: StaffChange, addToChanges: Bool = true) {
        // Add the change to the worksheet changes array so it gets saved back to Parse
        if addToChanges {
            var matchIndex = find(changes, change)
            var reverseMatchIndex = change.reversedChange != nil ? find(changes, change.reversedChange!) : nil

            if matchIndex != nil {
                changes[matchIndex!].count += change.count

                if changes[matchIndex!].count == 0 {
                    changes.removeAtIndex(matchIndex!)
                } else if changes[matchIndex!].count < 0 {
                    changes[matchIndex!] = changes[matchIndex!].reversedChange!
                }
            } else if reverseMatchIndex != nil {
                changes[reverseMatchIndex!].count -= change.count

                if changes[reverseMatchIndex!].count == 0 {
                    changes.removeAtIndex(reverseMatchIndex!)
                } else if changes[reverseMatchIndex!].count < 0 {
                    changes[reverseMatchIndex!] = changes[reverseMatchIndex!].reversedChange!
                }
            } else {
                changes.append(change)
            }
        }

        // Also add the change and the reverse change to the respective records
        // So they are reflected in actual staffing.

        var fromIndex = indexOfUnit(change.fromUnit)
        var toIndex = indexOfUnit(change.toUnit)
        var floatIndex = change.changeType == .FloatIn ? indexOfFloatItem(change.staffTypeName) : nil

        if fromIndex != nil && change.reversedChange != nil {
            records[fromIndex!].addChange(change.reversedChange!)
        }

        if toIndex != nil {
            records[toIndex!].addChange(change)
        }
        
        if floatIndex != nil {
            floatPool[floatIndex!].addChange(change)
        }
    }
}

extension Worksheet: Decodable {
    static func create(facilityId: String)(records: [CensusRecord])(recordDateString: String)(recordTime: NSTimeInterval)(changes: [StaffChange])(floatPool: [FloatPoolItem]) -> Worksheet {
        return Worksheet(facilityId: facilityId, recordDateString: recordDateString, recordTime: recordTime, records: records, changes: changes, floatPool: floatPool)
    }

    static func decode(j: JSON) -> Decoded<Worksheet> {
        return Worksheet.create
                <^> j <| "facilityId"
                <*> j <|| "records"
                <*> j <| "recordDateString"
                <*> j <| "recordTime"
                <*> j <|| "changes"
                <*> j <|| "floatPool"
    }
}
