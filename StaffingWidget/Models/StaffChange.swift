//
// Created by Michael Spencer on 7/12/15.
// Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Runes
import Argo

enum StaffChangeType: String {
    case Move = "move"
    case FlexOff = "flex_off"
    case CallInExtra = "call_extra"
    case FloatIn = "float_pool"
}

extension StaffChangeType: Decodable {
    static func decode(j: JSON) -> Decoded<StaffChangeType> {
        switch j {
        case let .String(s):
            return .fromOptional(StaffChangeType(rawValue: s))
        default:
            return .TypeMismatch("The staff change type needs to be represented as a string instead of \(j)")
        }
    }
}

struct StaffChange: Equatable {

    var changeType: StaffChangeType
    var staffTypeName: String
    var count: Int
    var fromUnit: Unit?
    var toUnit: Unit?

    var json: [String:AnyObject] {
        var json: [String:AnyObject] = [
                "changeType": changeType.rawValue,
                "staffTypeName": staffTypeName,
                "count": count
        ]

        if fromUnit != nil {
            json["fromUnit"] = ParseData.pointer("Unit", objectId: fromUnit!.objectId)
        }

        if toUnit != nil {
            json["toUnit"] = ParseData.pointer("Unit", objectId: toUnit!.objectId)
        }

        return json
    }

    var description: String {
        switch changeType {
        case .Move:
            return "Float \(count) \(staffTypeName) from \(fromUnit!.name) to \(toUnit!.name)"
        case .FlexOff:
            return "Flex off \(count) \(staffTypeName) from \(fromUnit!.name)"
        case .CallInExtra:
            return "Call in \(count) extra \(staffTypeName) to \(toUnit!.name)"
        case .FloatIn:
            return "Float \(count) \(staffTypeName) from the float pool to \(toUnit!.name)"
        }
    }

    var reversedChange: StaffChange? {
        switch changeType {
        case .Move:
            return StaffChange(changeType: .Move, staffTypeName: staffTypeName,
                    count: -1 * count, fromUnit: toUnit, toUnit: fromUnit)
        case .FlexOff:
            return StaffChange(changeType: .CallInExtra, staffTypeName: staffTypeName,
                    count: -1 * count, fromUnit: toUnit, toUnit: fromUnit)
        case .CallInExtra:
            return StaffChange(changeType: .FlexOff, staffTypeName: staffTypeName,
                    count: -1 * count, fromUnit: toUnit, toUnit: fromUnit)
        case .FloatIn:
            return nil
        }

    }

    var minusOne: StaffChange {
        return StaffChange(changeType: changeType, staffTypeName: staffTypeName, count: -1,
                fromUnit: fromUnit, toUnit: toUnit)
    }
}

func ==(lhs: StaffChange, rhs: StaffChange) -> Bool {
    let equal = (lhs.staffTypeName == rhs.staffTypeName) &&
            (lhs.fromUnit == rhs.fromUnit) && (lhs.toUnit == rhs.toUnit)

    if lhs.changeType.rawValue == "float_pool" || rhs.changeType.rawValue == "float_pool" {
        return equal && lhs.changeType.rawValue == rhs.changeType.rawValue
    } else {
        return equal
    }
}

extension StaffChange: Decodable {
    static func create(changeType: StaffChangeType)(staffTypeName: String)(count: Int)(fromUnit: Unit?)(toUnit: Unit?) -> StaffChange {
        return StaffChange(changeType: changeType, staffTypeName: staffTypeName, count: count, fromUnit: fromUnit, toUnit: toUnit)
    }

    static func decode(j: JSON) -> Decoded<StaffChange> {
        return StaffChange.create
                <^> j <| "changeType"
                <*> j <| "staffTypeName"
                <*> j <| "count"
                <*> j <|? "fromUnit"
                <*> j <|? "toUnit"
    }
}
