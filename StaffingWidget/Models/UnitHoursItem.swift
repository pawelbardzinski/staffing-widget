//
//  UnitHoursItem.swift
//  StaffingWidget
//
//  Created by Seth Hein on 7/24/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Runes
import Argo

struct UnitHoursItem
{
    var unitName:String
    var actualPersonHours: Float
    var guidelinePersonHours: Float
}

// MARK: - JSON Decoding

extension UnitHoursItem: Decodable {
    static func create(unitName: String)(actualPersonHours: Float)(guidelinePersonHours: Float) -> UnitHoursItem {
        return UnitHoursItem(unitName: unitName, actualPersonHours: actualPersonHours, guidelinePersonHours: guidelinePersonHours)
    }
    
    static func decode(j: JSON) -> Decoded<UnitHoursItem> {
        return UnitHoursItem.create
            <^> j <| "unitName"
            <*> j <| "actualPersonHours"
            <*> j <| "guidelinePersonHours"
    }
}
