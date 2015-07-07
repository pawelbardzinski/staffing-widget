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
    var actualStaff: Double
    
    var maxCensus: Int {
        
        return staffGrid.count == 0 ? 0 : staffGrid.count - 1
    }
    
    func gridStaffForCensus(census: Int) -> Int? {
        if census < 0 || census >= staffGrid.count {
            return nil
        } else {
            return staffGrid[census]
        }
    }
    
    func staffVarianceForCensus(census: Int) -> Double? {
        let gridStaff = gridStaffForCensus(census)
        
        if gridStaff != nil {
            return actualStaff - Double(gridStaff!)
        } else {
            return nil
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
            "gridStaff": gridStaffForCensus(census) ?? 0,
            "staffVariance": staffVarianceForCensus(census) ?? 0
        ]
    }
    
    func jsonChangesForCensus(census: Int) -> [String: AnyObject] {
        return [
            "visible": visible,
            "availableStaff": availableStaff,
            "actualStaff": actualStaff,
            "gridStaff": gridStaffForCensus(census) ?? 0,
            "staffVariance": staffVarianceForCensus(census) ?? 0
        ]
    }
}

func ==(lhs: GridItem, rhs: GridItem) -> Bool {
    return (lhs.staffTypeName == rhs.staffTypeName) && (lhs.objectId == rhs.objectId)
}


extension GridItem: Decodable {
    static func create(objectId: String?)(staffTypeName: String)(index: Int)(staffGrid: [Int])(required: Bool)(visible: Bool)(availableStaff: Double)(actualStaff: Double) -> GridItem {
        return GridItem(objectId: objectId, staffTypeName: staffTypeName, index: index, staffGrid: staffGrid, required: required,
            visible: visible, availableStaff: availableStaff, actualStaff: actualStaff)
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
            <*> j <| "actualStaff"
    }
}