//
//  CensusClient.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 5/21/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

protocol CensusClient {
    
    func saveRecord(record: CensusRecord, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> () )
    func getRecord(unitId: String, timestamp: RecordTimestamp, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> () )
    func getRecord(recordId: String, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> () )
    func getLastDayRecords(facilityId: String, successHandler: (records: [CensusRecord]) -> (), failureHandler: (error: NSError) -> ())

    func getCurrentWorksheet(facilityId: String, successHandler: (worksheet: Worksheet) -> (), failureHandler: (error: NSError) -> ())
    func getWorksheet(facilityId: String, timestamp: RecordTimestamp, successHandler: (worksheet: Worksheet) -> (), failureHandler: (error: NSError) -> ())
    func saveWorksheet(worksheet: Worksheet, successHandler: (worksheet: Worksheet) -> (), failureHandler: (error: NSError) -> ())
    
    func getInstanceTargetByStaffTypeReport(month: String?, successHandler: (instanceTargetItems: [InstanceTargetItem]) -> (), failureHandler: (error: NSError) -> ())
    func getPersonHoursReport(month: String?, successHandler: (unitHoursItems: [UnitHoursItem]) -> (), failureHandler: (error: NSError) -> ())
}
