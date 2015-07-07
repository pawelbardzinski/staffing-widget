//
//  ParseExtensions.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 5/21/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation
import Runes
import Argo

let DefaultErrorDescription = "Something went wrong. Please try again!"

class ParseData {
    // Based on http://stackoverflow.com/a/28016692/1917313
    private static let isoDateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)!
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        return formatter
    }()
    
    static func relation(className: String) -> [String: AnyObject] {
        return [
            "__type": "Relation",
            "className": className
        ]
    }
    
    static func pointer(className: String, objectId: String) -> [String: AnyObject] {
        return [
            "__type": "Pointer",
            "className": className,
            "objectId": objectId
        ]
    }
    
    static func date(isoString: String) -> NSDate {
        return isoDateFormatter.dateFromString(isoString)!
    }
    
    // Example: "2011-08-21T18:02:52.249Z"
    static func date(date: NSDate) -> [String: AnyObject] {
        return [
            "__type": "Date",
            "iso": isoDateFormatter.stringFromDate(date)
        ]
    }
    
    static func addRelation(pointers: [[String: AnyObject]]) -> [String: AnyObject] {
        return [
            "__op": "AddRelation",
            "objects": pointers
        ]
    }
    
    static func error(response: NSHTTPURLResponse?, error: NSError, data: AnyObject?, defaultDescription: String = DefaultErrorDescription) -> NSError {
        // See a list of error codes at https://parse.com/docs/ios/guide#errors
        
        var description = defaultDescription
        
        if let jsonResponse = data as? [String: AnyObject] {
            let errorCode = jsonResponse["code"] as! Int
            let error = jsonResponse["error"] as! String
            
            if (errorCode == 200 || errorCode == 201 || error == "invalid login parameters") {
                description = "Wrong username or password"
            }
            
            return NSError(domain: "com.lelander.staffingwidget", code: response!.statusCode, userInfo: [
                NSLocalizedDescriptionKey: description, NSLocalizedFailureReasonErrorKey: error, "errorCode": errorCode
                ])
        } else {
            return NSError(domain: "com.lelander.staffingwidget", code: response!.statusCode, userInfo: [
                NSLocalizedDescriptionKey: description, NSLocalizedFailureReasonErrorKey: error.localizedDescription
                ])
        }
    }
    
    static func malformedError(description: String = DefaultErrorDescription, reason: String? = nil) -> NSError {
        if reason != nil {
            return NSError(domain: "com.lelander.staffingwidget", code: 0, userInfo: [
                NSLocalizedDescriptionKey: description, NSLocalizedFailureReasonErrorKey: reason!
                ])
        } else {
            return NSError(domain: "com.lelander.staffingwidget", code: 0, userInfo: [
                NSLocalizedDescriptionKey: description
                ])
        }
    }
}

extension NSDate: Decodable {
    static func create(isoString: String) -> NSDate {
        return ParseData.date(isoString)
    }
    
    public static func decode(j: JSON) -> Decoded<NSDate> {
        return NSDate.create
            <^> j <| "iso"
    }
}