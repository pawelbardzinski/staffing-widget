//
//  RoleInfo.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 7/1/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Argo
import Runes

struct RoleInfo {
    var name: String
    
    var editFacility: Bool
    var editStaffingGrid: Bool
    var inputActualCensus: Bool
    var inputActualStaff: Bool
    var inputAvailableStaff: Bool
    var viewWorksheet: Bool
    var viewAllUnits: Bool
    var viewDashboard: Bool
    var runReports: Bool
    
    var json: [String: AnyObject] {
        return [
            "name": name,
            "editFacility": editFacility,
            "editStaffingGrid": editStaffingGrid,
            "inputActualCensus": inputActualCensus,
            "inputActualStaff": inputActualStaff,
            "inputAvailableStaff": inputAvailableStaff,
            "viewWorksheet": viewWorksheet,
            "viewAllUnits": viewAllUnits,
            "viewDashboard": viewDashboard,
            "runReports": runReports
        ]
    }
}

extension RoleInfo: Decodable {
    static func create(name: String)(editFacility: Bool)(editStaffingGrid: Bool)(inputActualCensus: Bool)(inputActualStaff: Bool)(inputAvailableStaff: Bool)(viewWorksheet: Bool)(viewAllUnits: Bool)(viewDashboard: Bool)(runReports: Bool) -> RoleInfo {
        return RoleInfo(name: name, editFacility: editFacility, editStaffingGrid: editStaffingGrid, inputActualCensus: inputActualCensus, inputActualStaff: inputActualStaff, inputAvailableStaff: inputAvailableStaff, viewWorksheet: viewWorksheet, viewAllUnits: viewAllUnits, viewDashboard: viewDashboard, runReports: runReports)
    }
    
    static func decode(j: JSON) -> Decoded<RoleInfo> {
        return RoleInfo.create
            <^> j <| "name"
            <*> j <| "editFacility"
            <*> j <| "editStaffingGrid"
            <*> j <| "inputActualCensus"
            <*> j <| "inputActualStaff"
            <*> j <| "inputAvailableStaff"
            <*> j <| "viewWorksheet"
            <*> j <| "viewAllUnits"
            <*> j <| "viewDashboard"
            <*> j <| "runReports"
    }
}
