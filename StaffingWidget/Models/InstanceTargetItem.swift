//
//  InstanceTargetItem.swift
//  StaffingWidget
//
//  Created by Seth Hein on 7/17/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Runes
import Argo

struct InstanceTargetItem
{
    var staffTypeName:String
    var above: Float
    var at: Float
    var below: Float
}

// MARK: - JSON Decoding

extension InstanceTargetItem: Decodable {
    static func create(staffTypeName: String)(above: Float)(at: Float)(below: Float) -> InstanceTargetItem {
        return InstanceTargetItem(staffTypeName: staffTypeName, above: above, at: at, below: below)
    }
    
    static func decode(j: JSON) -> Decoded<InstanceTargetItem> {
        return InstanceTargetItem.create
            <^> j <| "staffTypeName"
            <*> j <| "above"
            <*> j <| "at"
            <*> j <| "below"
    }
}
