//
//  ReportClient.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 5/21/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

protocol ReportClient {
    
    func saveReport(report: Report, successHandler: (report: Report) -> (), failureHandler: (error: NSError) -> () )
    func getReport(unitId: String, timestamp: ReportTimestamp, successHandler: (report: Report) -> (), failureHandler: (error: NSError) -> () )
    func getReport(reportId: String, successHandler: (report: Report) -> (), failureHandler: (error: NSError) -> () )
    func getCurrentReports(facilityId: String, successHandler: (reports: [Report]) -> (), failureHandler: (error: NSError) -> ())
    func getLastDayReports(facilityId: String, successHandler: (reports: [Report]) -> (), failureHandler: (error: NSError) -> ())
}