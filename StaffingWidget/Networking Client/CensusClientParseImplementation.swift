//
//  CensusClientParseImplementation.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 5/21/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Argo
import Alamofire

class CensusClientParseImplementation:NSObject, CensusClient {
    
    func saveRecord(record: CensusRecord, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> ()) {
    
        if record.objectId != nil {
            saveExistingRecord(record, successHandler: successHandler, failureHandler: failureHandler)
        } else {
            saveNewRecord(record, successHandler: successHandler, failureHandler: failureHandler)
        }
    }
    
    func saveExistingRecord(record: CensusRecord, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> ()) {
        var operations: [ParseRouter] = []
        
        operations.append(ParseRouter.UpdateObject(className: "CensusRecord", objectId: record.objectId!,
            jsonChanges: record.jsonChanges))
        
        for gridItem in record.gridItems {
            operations.append(ParseRouter.UpdateObject(className: "GridItem", objectId: gridItem.objectId!,
                jsonChanges: gridItem.jsonChangesForCensus(record.census)))
        }
        
        request(ParseRouter.BatchOperation(operations: operations))
            .validate()
            .responseJSON { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to save the record!"))
                } else {
                    successHandler(record: record)
                }
        }
    }
    
        
    func saveNewRecord(record: CensusRecord, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> ()) {
        var operations: [ParseRouter] = []
        
        operations.append(ParseRouter.CreateObject(className: "CensusRecord", json: record.json))
        
        for gridItem in record.gridItems {
            operations.append(ParseRouter.CreateObject(className: "GridItem", json: gridItem.jsonForCensus(record.census)))
        }
        
        request(ParseRouter.BatchOperation(operations: operations))
            .validate()
            .responseJSON { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to save the record!"))
                } else {
                    let json = returnObject as! [[String: AnyObject]]?
                    
                    let recordId: String = ((json!)[0]["success"] as! [String: String])["objectId"]!
                    
                    let gridItemIds: [String] = Array<String>((json!)[1..<json!.count].map {
                        response in (response["success"] as! [String: String])["objectId"]!
                        })
                    
                    self.addGridItemsToRecord(recordId, gridItemIds: gridItemIds, successHandler: {
                        var updatedRecord = record
                        updatedRecord.objectId = recordId
                        for index in 0..<updatedRecord.gridItems.count {
                            updatedRecord.gridItems[index].objectId = gridItemIds[index]
                        }
                        successHandler(record: updatedRecord)
                    }, failureHandler: failureHandler)
                }
        }
    }
    
    func addGridItemsToRecord(recordId: String, gridItemIds: [String], successHandler: () -> (), failureHandler: (error: NSError) -> ()) {
        let pointers = gridItemIds.map { gridItemId in ParseData.pointer("GridItem", objectId: gridItemId) }
        
        let jsonChanges = [
            "gridItems": ParseData.addRelation(pointers)
        ]
        
        request(ParseRouter.UpdateObject(className: "CensusRecord", objectId: recordId, jsonChanges: jsonChanges))
            .validate()
            .responseJSON { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to save the record!"))
                } else {
                    successHandler()
                }
        }
    }
    
    func getRecord(unitId: String, timestamp: RecordTimestamp, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> ()) {
        
        request(ParseRouter.GetRecord(unitId: unitId, timestamp: timestamp))
            .validate()
            .responseJSON { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to get the requested record!"))
                } else if let json = (returnObject as? NSDictionary)?["result"] as? [String: AnyObject] {
                    let record:Decoded<CensusRecord> = decode(json)
                    
                    switch record {
                    case .Success(let box):
                        successHandler(record: box.value)
                    case .TypeMismatch(let error):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the requested record!",
                            reason: "Type mismatch: \(error)"))
                    case .MissingKey(let key):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the requested record!",
                            reason: "Missing key: \(key)"))
                    }
                } else {
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the requested record!",
                        reason: "Malformed JSON response."))
                }
        }
    }
    
    func getRecord(recordId: String, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> ()) {
        
        request(ParseRouter.GetExistingRecord(recordId: recordId))
            .validate()
            .responseJSON { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to get the requested record!"))
                } else if let json = (returnObject as? NSDictionary)?["result"] as? [String: AnyObject] {
                    let record:Decoded<CensusRecord> = decode(json)
                    
                    switch record {
                    case .Success(let box):
                        successHandler(record: box.value)
                    case .TypeMismatch(let error):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the requested record!",
                            reason: "Type mismatch: \(error)"))
                    case .MissingKey(let key):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the requested record!",
                            reason: "Missing key: \(key)"))
                    }
                } else {
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the requested record!",
                        reason: "Malformed JSON response."))
                }
        }
    }

    func getCurrentWorksheet(facilityId: String, successHandler: (worksheet: Worksheet) -> (), failureHandler: (error: NSError) -> ()) {
        getWorksheet(facilityId, timestamp: UserManager.facility!.nextRecordTime, successHandler: successHandler, failureHandler: failureHandler)
    }

    func getWorksheet(facilityId: String, timestamp: RecordTimestamp, successHandler: (worksheet: Worksheet) -> (), failureHandler: (error: NSError) -> ()) {

        request(ParseRouter.GetWorksheet(facilityId: facilityId, timestamp: timestamp))
            .validate()
            .responseJSON
        { (request, response, returnObject, error) in
        
            if (error != nil) {
                failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                    defaultDescription: "Unable to get the requested worksheet!"))
            } else if let json = (returnObject as? NSDictionary)?["result"] as? NSDictionary {
                let worksheet:Decoded<Worksheet> = decode(json)
                
                switch worksheet {
                case .Success(let box):
                    successHandler(worksheet: box.value)
                case .TypeMismatch(let error):
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the requested worksheet!",
                        reason: "Type mismatch: \(error)"))
                case .MissingKey(let key):
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the requested worksheet!",
                        reason: "Missing key: \(key)"))
                }
            } else {
                failureHandler(error: ParseData.malformedError(
                    description: "Unable to get the requested worksheet!",
                    reason: "Malformed JSON response."))
            }   
        }
    }

    func saveWorksheet(worksheet: Worksheet, successHandler: (worksheet: Worksheet) -> (), failureHandler: (error: NSError) -> ()) {

        var editedWorksheet = worksheet
        
        request(ParseRouter.SaveWorksheet(worksheet: worksheet))
        .validate()
        .responseJSON
        { (request, response, returnObject, error) in

            if (error != nil) {
                failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to save the worksheet!"))
            } else {
                for (index, record) in enumerate(editedWorksheet.records) {
                    if record.status == .Saved {
                        editedWorksheet.records[index].status = RecordStatus.Adjusted
                    }
                }

                successHandler(worksheet: editedWorksheet)
            }
        }
    }
    
    func getLastDayRecords(facilityId: String, successHandler: (records: [CensusRecord]) -> (), failureHandler: (error: NSError) -> ())
    {

        request(ParseRouter.GetLastDayRecords(facilityId: facilityId))
            .validate()
            .responseJSON
        { (request, response, returnObject, error) in
            
            if (error != nil) {
                failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                    defaultDescription: "Unable to get the requested record!"))
            } else if let json = (returnObject as? NSDictionary)?["result"] as? [AnyObject] {
                
                let records:Decoded<[CensusRecord]> = decode(json)
                
                switch records {
                case .Success(let box):
                    successHandler(records: box.value)
                case .TypeMismatch(let error):
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the current records!",
                        reason: "Type mismatch: \(error)"))
                case .MissingKey(let key):
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the current records!",
                        reason: "Missing key: \(key)"))
                }
            } else {
                failureHandler(error: ParseData.malformedError(
                    description: "Unable to get the current records!",
                    reason: "Malformed JSON response."))
            }
        }
    }
    
    func getInstanceTargetByStaffTypeReport(month: String?, successHandler: (instanceTargetItems: [InstanceTargetItem]) -> (), failureHandler: (error: NSError) -> ())
    {
        request(ParseRouter.GetInstanceTargetByStaffTypeReport(thisMonth: month))
            .validate()
            .responseJSON
            { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to get the requested record!"))
                } else if let json = (returnObject as? NSDictionary)?["result"] as? [AnyObject] {
                    
                    let records:Decoded<[InstanceTargetItem]> = decode(json)
                    
                    switch records {
                    case .Success(let box):
                        successHandler(instanceTargetItems: box.value)
                    case .TypeMismatch(let error):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the instance target report!",
                            reason: "Type mismatch: \(error)"))
                    case .MissingKey(let key):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the instance target report!",
                            reason: "Missing key: \(key)"))
                    }
                } else {
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the instance target report!",
                        reason: "Malformed JSON response."))
                }
        }
    }
    
    func getPersonHoursReport(month: String?, successHandler: (unitHoursItems: [UnitHoursItem]) -> (), failureHandler: (error: NSError) -> ())
    {
        request(ParseRouter.GetPersonHoursReport(thisMonth: month))
            .validate()
            .responseJSON
            { (request, response, returnObject, error) in
                
                if (error != nil) {
                    failureHandler(error: ParseData.error(response, error: error!, data: returnObject,
                        defaultDescription: "Unable to get the requested record!"))
                } else if let json = (returnObject as? NSDictionary)?["result"] as? [AnyObject] {
                    
                    let records:Decoded<[UnitHoursItem]> = decode(json)
                    
                    switch records {
                    case .Success(let box):
                        successHandler(unitHoursItems: box.value)
                    case .TypeMismatch(let error):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the instance target report!",
                            reason: "Type mismatch: \(error)"))
                    case .MissingKey(let key):
                        failureHandler(error: ParseData.malformedError(
                            description: "Unable to get the instance target report!",
                            reason: "Missing key: \(key)"))
                    }
                } else {
                    failureHandler(error: ParseData.malformedError(
                        description: "Unable to get the instance target report!",
                        reason: "Malformed JSON response."))
                }
        }
    }
}
