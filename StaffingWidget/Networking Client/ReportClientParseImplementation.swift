//
//  ReportClientParseImplementation.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 5/21/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Argo

class ReportClientParseImplementation:NSObject, ReportClient {
    
    func saveReport(report: Report, successHandler: (report: Report) -> (), failureHandler: (error: NSError) -> ()) {
    
        if report.objectId != nil {
            saveExistingReport(report, successHandler: successHandler, failureHandler: failureHandler)
        } else {
            saveNewReport(report, successHandler: successHandler, failureHandler: failureHandler)
        }
    }
    
    func saveExistingReport(report: Report, successHandler: (report: Report) -> (), failureHandler: (error: NSError) -> ()) {
        var operations: [ParseRouter] = []
        
        operations.append(ParseRouter.UpdateObject(className: "Report", objectId: report.objectId!,
            jsonChanges: report.jsonChanges))
        
        for gridItem in report.gridItems {
            operations.append(ParseRouter.UpdateObject(className: "GridItem", objectId: gridItem.objectId!,
                jsonChanges: gridItem.jsonChangesForCensus(report.census)))
        }
        
        request(ParseRouter.BatchOperation(operations: operations))
            .validate()
            .responseJSON { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to save the report!"))
                } else {
                    successHandler(report: report)
                }
        }
    }
    
        
    func saveNewReport(report: Report, successHandler: (report: Report) -> (), failureHandler: (error: NSError) -> ()) {
        var operations: [ParseRouter] = []
        
        operations.append(ParseRouter.CreateObject(className: "Report", json: report.json))
        
        for gridItem in report.gridItems {
            operations.append(ParseRouter.CreateObject(className: "GridItem", json: gridItem.jsonForCensus(report.census)))
        }
        
        request(ParseRouter.BatchOperation(operations: operations))
            .validate()
            .responseJSON { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to save the report!"))
                } else {
                    let json = returnObject as! [[String: AnyObject]]?
                    
                    let reportId: String = ((json!)[0]["success"] as! [String: String])["objectId"]!
                    
                    let gridItemIds: [String] = Array<String>((json!)[1..<json!.count].map {
                        response in (response["success"] as! [String: String])["objectId"]!
                        })
                    
                    self.addGridItemsToReport(reportId, gridItemIds: gridItemIds, successHandler: {
                        var updatedReport = report
                        updatedReport.objectId = reportId
                        for index in 0..<updatedReport.gridItems.count {
                            updatedReport.gridItems[index].objectId = gridItemIds[index]
                        }
                        successHandler(report: updatedReport)
                    }, failureHandler: failureHandler)
                }
        }
    }
    
    func addGridItemsToReport(reportId: String, gridItemIds: [String], successHandler: () -> (), failureHandler: (error: NSError) -> ()) {
        let pointers = gridItemIds.map { gridItemId in ParseData.pointer("GridItem", objectId: gridItemId) }
        
        let jsonChanges = [
            "gridItems": ParseData.addRelation(pointers)
        ]
        
        request(ParseRouter.UpdateObject(className: "Report", objectId: reportId, jsonChanges: jsonChanges))
            .validate()
            .responseJSON { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to save the report!"))
                } else {
                    successHandler()
                }
        }
    }
    
    func getReport(unitId: String, timestamp: ReportTimestamp, successHandler: (report: Report) -> (), failureHandler: (error: NSError) -> ()) {
        
        request(ParseRouter.GetReport(unitId: unitId, timestamp: timestamp))
            .validate()
            .responseJSON { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to get the requested report!"))
                } else if let json = (returnObject as? NSDictionary)?["result"] as? [String: AnyObject] {
                    let report:Decoded<Report> = decode(json)
                    
                    switch report {
                    case .Success(let box):
                        successHandler(report: box.value)
                    case .TypeMismatch(let error):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the requested report!",
                            reason: "Type mismatch: \(error)"))
                    case .MissingKey(let key):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the requested report!",
                            reason: "Missing key: \(key)"))
                    }
                } else {
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the requested report!",
                        reason: "Malformed JSON response."))
                }
        }
    }
    
    func getReport(reportId: String, successHandler: (report: Report) -> (), failureHandler: (error: NSError) -> ()) {
        
        request(ParseRouter.GetExistingReport(reportId: reportId))
            .validate()
            .responseJSON { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to get the requested report!"))
                } else if let json = (returnObject as? NSDictionary)?["result"] as? [String: AnyObject] {
                    let report:Decoded<Report> = decode(json)
                    
                    switch report {
                    case .Success(let box):
                        successHandler(report: box.value)
                    case .TypeMismatch(let error):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the requested report!",
                            reason: "Type mismatch: \(error)"))
                    case .MissingKey(let key):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the requested report!",
                            reason: "Missing key: \(key)"))
                    }
                } else {
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the requested report!",
                        reason: "Malformed JSON response."))
                }
        }
    }
    
    func getCurrentReports(facilityId: String, successHandler: (reports: [Report]) -> (), failureHandler: (error: NSError) -> ()) {
        
        // do some task
        request(ParseRouter.GetCurrentReports(facilityId: facilityId, currentTime: StaffingUtils.currentHour(), currentDate: NSDate()))
            .validate()
            .responseJSON
        { (request, response, returnObject, error) in
                
        
            // update some UI
        
            if (error != nil) {
                failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                    defaultDescription: "Unable to get the requested report!"))
            } else if let json = (returnObject as? NSDictionary)?["result"] as? [AnyObject] {
                let report:Decoded<[Report]> = decode(json)
                
                switch report {
                case .Success(let box):
                    successHandler(reports: box.value)
                case .TypeMismatch(let error):
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the current reports!",
                        reason: "Type mismatch: \(error)"))
                case .MissingKey(let key):
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the current reports!",
                        reason: "Missing key: \(key)"))
                }
            } else {
                failureHandler(error: ParseData.malformedError(
                    description: "Unable to get the current reports!",
                    reason: "Malformed JSON response."))
            }   
        }
    }
    
    func getLastDayReports(facilityId: String, successHandler: (reports: [Report]) -> (), failureHandler: (error: NSError) -> ())
    {

        request(ParseRouter.GetLastDayReports(facilityId: facilityId))
            .validate()
            .responseJSON
        { (request, response, returnObject, error) in
            
            if (error != nil) {
                failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                    defaultDescription: "Unable to get the requested report!"))
            } else if let json = (returnObject as? NSDictionary)?["result"] as? [AnyObject] {
                
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0)) {

                    let report:Decoded<[Report]> = decode(json)
                
                    dispatch_async(dispatch_get_main_queue()) {
                        switch report {
                        case .Success(let box):
                            successHandler(reports: box.value)
                        case .TypeMismatch(let error):
                            failureHandler(error: ParseData.malformedError(
                                description: "Unable to get the current reports!",
                                reason: "Type mismatch: \(error)"))
                        case .MissingKey(let key):
                            failureHandler(error: ParseData.malformedError(
                                description: "Unable to get the current reports!",
                                reason: "Missing key: \(key)"))
                        }
                    }
                }
            } else {
                failureHandler(error: ParseData.malformedError(
                    description: "Unable to get the current reports!",
                    reason: "Malformed JSON response."))
            }
        }
    }
}