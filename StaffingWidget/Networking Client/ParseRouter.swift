//
//  ParseRoutes.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/20/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Alamofire

enum ParseRouter: URLRequestConvertible {
    static let baseURLString = "https://api.parse.com/1"
    
    case Login(username: String, password: String)
    case CreateObject(className: String, json: [String: AnyObject])
    case ReadObject(className: String, objectId: String)
    case QueryObjects(className: String, parameters: [String: AnyObject])
    case UpdateObject(className: String, objectId: String, jsonChanges: [String: AnyObject])
    case DestroyObject(className: String, objectId: String)
    case UpsertObject(className: String, objectId: String?, json: [String: AnyObject])
    case BatchOperation(operations: [ParseRouter])
    case GetRecord(unitId: String, timestamp: RecordTimestamp)
    case GetExistingRecord(recordId: String)
    case GetWorksheet(facilityId: String, timestamp: RecordTimestamp)
    case SaveWorksheet(worksheet: Worksheet)
    case GetFacility(facilityId: String)
    case GetLastDayRecords(facilityId: String)
    case GetInstanceTargetByStaffTypeReport(thisMonth: String?)
    case GetPersonHoursReport(thisMonth: String?)
    
    var method: Alamofire.Method {
        switch self {
        case .Login:
            return .GET
        case .CreateObject:
            return .POST
        case .ReadObject:
            return .GET
        case .QueryObjects:
            return .GET
        case .UpdateObject:
            return .PUT
        case .DestroyObject:
            return .DELETE
        case .UpsertObject(let className, let objectId, let json):
            return objectId == nil ? .POST : .PUT
        case .BatchOperation:
            return .POST
        case .GetRecord:
            return .POST
        case .GetExistingRecord:
            return .POST
        case .GetWorksheet, .SaveWorksheet:
            return .POST
        case .GetFacility(let facilityId):
            return .POST
        case .GetLastDayRecords(let facilityId):
            return .POST
        case .GetInstanceTargetByStaffTypeReport(let thisMonth):
            return .POST
        case .GetPersonHoursReport(let thisMonth):
            return .POST
        }
    }
    
    var path: String {
        switch self {
        case .Login:
            return "/login"
        case .CreateObject(let className, let json):
            return "/classes/\(className)"
        case .ReadObject(let className, let objectId):
            return "/classes/\(className)/\(objectId)"
        case .QueryObjects(let className, let parameters):
            return "/classes/\(className)/"
        case .UpdateObject(let className, let objectId, let json):
            return "/classes/\(className)/\(objectId)"
        case .DestroyObject(let className, let objectId):
            return "/classes/\(className)/\(objectId)"
        case .UpsertObject(let className, let objectId, let json):
            if objectId != nil {
                return "/classes/\(className)/\(objectId)"
            } else {
                return "/classes/\(className)"
            }
        case .BatchOperation:
            return "/batch"
        case .GetRecord:
            return "/functions/getRecord"
        case .GetExistingRecord:
            return "/functions/getExistingRecord"
        case .GetWorksheet:
            return "/functions/getWorksheet"
        case .SaveWorksheet:
            return "/functions/saveWorksheet"
        case .GetFacility(let facilityId):
            return "/functions/getFacility/"
        case .GetLastDayRecords(let facilityId):
            return "/functions/getLastDayRecords"
        case .GetInstanceTargetByStaffTypeReport(let thisMonth):
            return "/functions/instanceTargetByStaffTypeReport"
        case .GetPersonHoursReport(let thisMonth):
            return "/functions/personHoursByUnitReport"
        }
    }
    
    // MARK: URLRequestConvertible
    
    var URLRequest: NSURLRequest {
        let URL = NSURL(string: ParseRouter.baseURLString)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
        mutableURLRequest.HTTPMethod = method.rawValue
        
        // parse headers
        #if DEBUG
        mutableURLRequest.setValue("jjQlIo5A3HWAMRMCkH8SnOfimVfCi6QlOV9ZNO2T", forHTTPHeaderField: "X-Parse-Application-Id")
        mutableURLRequest.setValue("Fe2miwj6i5iAKC9Pyzl6KdRRk9QmV9lt7BmbqP4E", forHTTPHeaderField: "X-Parse-REST-API-Key")
        #else
        mutableURLRequest.setValue("5pYOx25qvyg4IVXyu128IuRlbnJtwLgwCTsHXCpO", forHTTPHeaderField: "X-Parse-Application-Id")
        mutableURLRequest.setValue("xkuupM8jCHRcR15G0WJ1BjAixZEzf8vrTiyWrUjr", forHTTPHeaderField: "X-Parse-REST-API-Key")
        #endif
        
        if (UserManager.isLoggedIn)
        {
            let sessionToken = UserManager.sessionToken
            mutableURLRequest.setValue(sessionToken, forHTTPHeaderField: "X-Parse-Session-Token")
        }
        
        switch self {
        case .Login(let username, let password):
            return ParameterEncoding.URL.encode(mutableURLRequest, parameters: ["username":username, "password": password]).0
        case .QueryObjects(let className, let parameters):
            return ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
        case .CreateObject(let className, let json):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .UpdateObject(let className, let objectId, let json):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .UpsertObject(let className, let objectId, let json):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .BatchOperation(let operations):
            let json = [
                "requests": operations.map { operation in operation.batchJSON }
            ]
            
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .GetRecord(let unitId, let timestamp):
            let json: [String: AnyObject] = [
                "unitId": unitId,
                "recordTime": timestamp.time,
                "recordDateString": StaffingUtils.recordDateFormatter().stringFromDate(timestamp.date)
            ]
            
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .GetExistingRecord(let recordId):
            let json: [String: AnyObject] = [
                "recordId": recordId
            ]
            
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .GetWorksheet(let facilityId, let timestamp):
            let json: [String: AnyObject] = [
                "facilityId": facilityId,
                "time": timestamp.time,
                "dateString": StaffingUtils.recordDateFormatter().stringFromDate(timestamp.date)
            ]
            
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .SaveWorksheet(let worksheet):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: worksheet.json).0
        case .GetFacility(let facilityId):
            let json: [String: AnyObject] = [
                    "facilityId": facilityId
            ]

            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .GetLastDayRecords(let facilityId):
            
            let date = NSDate()
            let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            let midnight = cal!.startOfDayForDate(date)
            
            let json: [String: AnyObject] = [
                "facilityId": facilityId,
                "currentSecondsFromMidnight": date.timeIntervalSinceDate(midnight),
                "currentDateString": StaffingUtils.recordDateFormatter().stringFromDate(date)
            ]
            
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .GetInstanceTargetByStaffTypeReport(let thisMonth):
            
            if let monthString = thisMonth
            {
                let json: [String: AnyObject] = [
                    "thisMonthString": monthString
                ]
                
                return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
            } else {
                return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: [:]).0
            }
            
        case .GetPersonHoursReport(let thisMonth):
            
            if let monthString = thisMonth
            {
                let json: [String: AnyObject] = [
                    "thisMonthString": monthString
                ]
                
                return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
            } else {
                return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: [:]).0
            }
        default:
            return mutableURLRequest
        }
    }
    
    var batchJSON: [String: AnyObject] {
        switch self {
        case .CreateObject(let className, let json):
            return [
                "method": "\(method.rawValue)",
                "path": "/1\(path)",
                "body": json
            ]
        case .UpdateObject(let className, let objectId, let json):
            return [
                "method": "\(method.rawValue)",
                "path": "/1\(path)",
                "body": json
            ]
        case .DestroyObject(let className, let objectId):
            return [
                "method": "\(method.rawValue)",
                "path": "/1\(path)"
            ]
        case .UpsertObject(let className, let objectId, let json):
            return [
                "method": "\(method.rawValue)",
                "path": "/1\(path)",
                "body": json
            ]
        default:
            NSException(name: "Unsupported batch operation",
                reason: "The operation '\(self)' is not supported in batch operations", userInfo: nil).raise()
            return [:]
        }
    }
}
