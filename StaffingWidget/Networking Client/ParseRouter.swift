//
//  ParseRoutes.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/20/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

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
    case GetReport(unitId: String, timestamp: ReportTimestamp)
    case GetExistingReport(reportId: String)
    case GetCurrentReports(facilityId: String, currentTime: NSTimeInterval, currentDate: NSDate)
    case GetUnitsForFacility(facilityId: String)
    case GetLastDayReports(facilityId: String)
    
    var method: Method {
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
        case .GetReport:
            return .POST
        case .GetExistingReport:
            return .POST
        case .GetCurrentReports:
            return .POST
        case .GetUnitsForFacility(let facilityId):
            return .GET
        case .GetLastDayReports(let facilityId):
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
        case .GetReport:
            return "/functions/getReport"
        case .GetExistingReport:
            return "/functions/getExistingReport"
        case .GetCurrentReports:
            return "/functions/getCurrentReports"
        case .GetUnitsForFacility(let facilityId):
            return "/classes/Unit/"
        case .GetLastDayReports(let facilityId):
            return "/functions/getLastDayReports"
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
        case .GetReport(let unitId, let timestamp):
            let json: [String: AnyObject] = [
                "unitId": unitId,
                "reportingTime": timestamp.time,
                "reportingDateString": StaffingUtils.reportDateFormatter().stringFromDate(timestamp.date)
            ]
            
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .GetExistingReport(let reportId):
            let json: [String: AnyObject] = [
                "reportId": reportId
            ]
            
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .GetCurrentReports(let facilityId, let currentTime, let currentDate):
            let json: [String: AnyObject] = [
                "facilityId": facilityId,
                "currentTime": currentTime,
                "dateString": StaffingUtils.reportDateFormatter().stringFromDate(currentDate)
            ]
            
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
        case .GetUnitsForFacility(let facilityId):
            return ParameterEncoding.URL.encode(mutableURLRequest, parameters: ["where": ["facility":["__type": "Pointer", "className": "Facility", "objectId": facilityId]]]).0
        case .GetLastDayReports(let facilityId):
            
            let date = NSDate()
            let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            let midnight = cal!.startOfDayForDate(date)
            
            let json: [String: AnyObject] = [
                "facilityId": facilityId,
                "currentSecondsFromMidnight": date.timeIntervalSinceDate(midnight),
                "currentDateString": StaffingUtils.reportDateFormatter().stringFromDate(date)
            ]
            
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json).0
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