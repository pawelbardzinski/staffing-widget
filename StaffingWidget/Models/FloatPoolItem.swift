//
// Created by Michael Spencer on 7/27/15.
// Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Argo
import Runes

struct FloatPoolItem: Equatable
{
    var staffTypeName:String
    var index: Int

    var availableStaff: Double

    var changes: [StaffChange]

    // MARK: - Read-only properties

    var actualStaff: Double {
        return availableStaff - Double(changes.reduce(0, combine: { return $0 + $1.count }))
    }

    /**
     * Add the change or combine it with existing changes so the list of changes is as simple as
     * possible.
     *
     * This is done by combining it with a change in the same direction, so for example, floating
     * a Nurse to A and then floating another Nurse to A will result in a single change with a
     * count of 2.
     *
     * While it isn't possible to drag to a float pool item, reversed changes are still possible,
     * which can be created by tapping the minus button on a staff change.
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

    var json: [String: AnyObject] {
        return [
                "staffTypeName": staffTypeName,
                "index": index,
                "availableStaff": availableStaff,
                "actualStaff": actualStaff
        ]
    }
}

func ==(lhs: FloatPoolItem, rhs: FloatPoolItem) -> Bool {
    return (lhs.staffTypeName == rhs.staffTypeName)
}


extension FloatPoolItem: Decodable {
    static func create(staffTypeName: String)(index: Int)(availableStaff: Double) -> FloatPoolItem {
        return FloatPoolItem(staffTypeName: staffTypeName, index: index,
            availableStaff: availableStaff, changes: [])
    }

    static func decode(j: JSON) -> Decoded<FloatPoolItem> {
        return FloatPoolItem.create
                <^> j <| "staffTypeName"
                <*> j <| "index"
                <*> j <| "availableStaff"
    }
}
