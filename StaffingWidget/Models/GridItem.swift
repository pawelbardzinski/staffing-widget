//
//  GridItem.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-14.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Runes
import Argo

struct GridItem: Equatable
{
    var objectId: String?
    
    var staffTypeName:String
    var index: Int
    var staffGrid:[Int]
    var required:Bool
    var visible:Bool

    var availableStaff: Double
    var requestedStaff: Double

    var changes: [StaffChange]

    // MARK: - Read-only properties
    
    var actualStaff: Double {
        return availableStaff + Double(changes.reduce(0, combine: { return $0 + $1.count }))
    }
    
    var resourceVariance: Double {
        return actualStaff - requestedStaff
    }
    
    var maxCensus: Int {
        return staffGrid.count == 0 ? 0 : staffGrid.count - 1
    }
    
    func recommendedStaffForCensus(census: Int) -> Int? {
        if census < 0 || census >= staffGrid.count {
            return nil
        } else {
            return staffGrid[census]
        }
    }
    
    func staffVarianceForCensus(census: Int) -> Double? {
        let recommendedStaff = recommendedStaffForCensus(census)
        
        if recommendedStaff != nil {
            return actualStaff - Double(recommendedStaff!)
        } else {
            return nil
        }
    }

    var changeDescriptions: [String] {
        return changes.map({ $0.count > 0 ? $0.description : $0.reversedChange!.description })
    }

    /**
     * Add the change or combine it with existing changes so the list of changes is as simple as
     * possible.
     *
     * This is done by combining it with a change in the same direction, so for example, dragging
     * a Nurse from A to B and then dragging another Nurse from A to B will result in a single
     * change with a count of 2.
     *
     * Similarily, calling in an extra SEC to A and then flexing off a SEC from A will cancel out
     * the original change.
     */
    mutating func addChange(change: StaffChange) {
        var matchIndex = find(changes, change)
        var reverseMatchIndex = change.reversedChange != nil ? find(changes, change.reversedChange!) : nil

        if matchIndex != nil {
            changes[matchIndex!].count += change.count

            if changes[matchIndex!].count == 0 {
                changes.removeAtIndex(matchIndex!)
            }
        } else if reverseMatchIndex != nil {
            changes[reverseMatchIndex!].count -= change.count

            if changes[reverseMatchIndex!].count == 0 {
                changes.removeAtIndex(reverseMatchIndex!)
            }
        } else {
            changes.append(change)
        }
    }
    
    func jsonForCensus(census: Int) -> [String: AnyObject] {
        return [
            "staffTypeName": staffTypeName,
            "index": index,
            "grid": staffGrid,
            "required": required,
            "visible": visible,
            "availableStaff": availableStaff,
            "actualStaff": actualStaff,
            "requestedStaff": requestedStaff,
            "recommendedStaff": recommendedStaffForCensus(census) ?? 0,
            "staffVariance": staffVarianceForCensus(census) ?? 0,
            "resourceVariance": resourceVariance
        ]
    }
    
    func jsonChangesForCensus(census: Int) -> [String: AnyObject] {
        return [
            "visible": visible,
            "availableStaff": availableStaff,
            "actualStaff": actualStaff,
            "requestedStaff": requestedStaff,
            "recommendedStaff": recommendedStaffForCensus(census) ?? 0,
            "staffVariance": staffVarianceForCensus(census) ?? 0
        ]
    }
}

func ==(lhs: GridItem, rhs: GridItem) -> Bool {
    return (lhs.staffTypeName == rhs.staffTypeName) && (lhs.objectId == rhs.objectId)
}


extension GridItem: Decodable {
    static func create(objectId: String?)(staffTypeName: String)(index: Int)(staffGrid: [Int])(required: Bool)(visible: Bool)(availableStaff: Double)(requestedStaff: Double)(changes: [StaffChange]?) -> GridItem {
        return GridItem(objectId: objectId, staffTypeName: staffTypeName, index: index, staffGrid: staffGrid, required: required,
            visible: visible, availableStaff: availableStaff, requestedStaff: requestedStaff, changes: changes ?? [])
    }
    
    static func decode(j: JSON) -> Decoded<GridItem> {
        return GridItem.create
            <^> j <|? "objectId"
            <*> j <| "staffTypeName"
            <*> j <| "index"
            <*> j <|| "grid"
            <*> j <| "required"
            <*> j <| "visible"
            <*> j <| "availableStaff"
            <*> j <| "requestedStaff"
            <*> j <||? "changes"
    }
}
