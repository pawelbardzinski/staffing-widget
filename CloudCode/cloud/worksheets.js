/* global Parse */

var _ = require ('underscore');
var Records = require('cloud/records.js');
var facilities = require('cloud/facilities.js');

var Facility = Parse.Object.extend("Facility");
var FloatPoolItem = Parse.Object.extend("FloatPoolItem");

Parse.Cloud.define("getWorksheet", function(request, response) {
  
     // pull in our request parameters
    var facilityId = request.params.facilityId;
    var time = request.params.time;
    var dateString = request.params.dateString;
    
    var facility = new Facility();
    facility.id = facilityId;
    
    // For later
    var records = [];
    var changes = [];
     
    console.log(JSON.stringify(Records));
     
    var query = new Parse.Query("Unit");
    query.equalTo("facility", facility);
    
    query.find().then(function(units) {
        var unitPromises = [];
        
        _.each(units, function(unit) {
            var promise = Records.getRecordForTimestamp(unit, time, dateString).then(function(record) {
                return record ? Records.createRecordJSON(unit, record, 0) : undefined;
            }).then(function(json) {
                if (json != undefined)
                    records.push(json);
            });
            
            unitPromises.push(promise);
        });
        
        return Parse.Promise.when(unitPromises);
    }).then(function() {
        var query = new Parse.Query("StaffChange");
        query.equalTo("facility", facility);
        query.equalTo("recordDateString", dateString);
        query.equalTo("recordTime", time);
        query.include("fromUnit").include("toUnit");
        
        return query.find();
    }).then(function(staffChanges) {
        changes = staffChanges
        
        var query = new Parse.Query("FloatPoolItem");
        query.equalTo("facility", facility);
        query.equalTo("recordDateString", dateString);
        query.equalTo("recordTime", time);
        
        return query.find();
    }).then(function(floatPool) {
        if (floatPool.length == 0) {
            return facilities.getStaffTypes().then(function(staffTypes) {
                return _.map(staffTypes, function(staffTypeName, index) {
                    return {
                        "staffTypeName": staffTypeName,
                        "index": index,
                        "availableStaff": 0
                    }
                });
            });
        } else {
            return floatPool
        }
    }).done(function(floatPool) {
        response.success({
            "facilityId": facilityId,
            "records": records,
            "floatPool": floatPool,
            "changes": changes,
            "recordDateString": dateString,
            "recordTime": time
        });
    }).fail(function(error) {
        response.error(error);
    });
});

Parse.Cloud.define("saveWorksheet", function(request, response) {
  
     // pull in our request parameters
    var facilityId = request.params.facilityId;
    var time = request.params.recordTime;
    var dateString = request.params.recordDateString;
    var changes = request.params.changes;
    var floatPool = request.params.floatPool;
    
    var StaffChange = Parse.Object.extend("StaffChange");
    
    var Facility = Parse.Object.extend("Facility");
    var facility = new Facility();
    facility.id = facilityId;
    
    // For later
    var records = [];
     
    var query = new Parse.Query("StaffChange");
    query.equalTo("facility", facility);
    query.equalTo("recordDateString", dateString);
    query.equalTo("recordTime", time);
    
    query.find().then(function(changes) {
        return Parse.Object.destroyAll(changes);
    }).then(function() {
        var query = new Parse.Query("FloatPoolItem");
        query.equalTo("facility", facility);
        query.equalTo("recordDateString", dateString);
        query.equalTo("recordTime", time);
        
        return query.find();
    }).then(function(floatPool) {
        return Parse.Object.destroyAll(floatPool);
    }).then(function() {
        var changeObjects = [];
        
        _.each(changes, function(change) {
            var staffChange = new StaffChange();
            staffChange.set("facility", facility);
            staffChange.set("staffTypeName", change.staffTypeName);
            staffChange.set("changeType", change.changeType);
            staffChange.set("count", change.count);
            staffChange.set("fromUnit", change.fromUnit);
            staffChange.set("toUnit", change.toUnit);
            staffChange.set("recordDateString", dateString);
            staffChange.set("recordTime", time);
            
            changeObjects.push(staffChange);
        });
        
        return Parse.Object.saveAll(changeObjects);
    }).then(function() {
        var floatPoolItems = [];
        
        _.each(floatPool, function(floatItem) {
            var floatPoolItem = new FloatPoolItem();
            floatPoolItem.set("facility", facility);
            floatPoolItem.set("staffTypeName", floatItem.staffTypeName);
            floatPoolItem.set("availableStaff", floatItem.availableStaff);
            floatPoolItem.set("actualStaff", floatItem.actualStaff);
            floatPoolItem.set("index", floatItem.index);
            floatPoolItem.set("recordDateString", dateString);
            floatPoolItem.set("recordTime", time);
            
            floatPoolItems.push(floatPoolItem);
        });
        
        return Parse.Object.saveAll(floatPoolItems);
    }).then(function() {
        var query = new Parse.Query("Unit");
        query.equalTo("facility", facility);
        
        return query.find();
    }).then(function(units) {
        var unitPromises = [];
        
        _.each(units, function(unit) {
            var promise = Records.getRecordForTimestamp(unit, time, dateString).then(function(record) {
                if (record && record.get("status") == "saved") {
                    console.log("Adjusting record for " + record.get("unit").id)
                    record.set("status", "adjusted");
                
                    return record.save();
                } else {
                    return record;
                }
            }).then(function(record) {
                return  record ? Records.createRecordJSON(unit, record, 0) : undefined;
            }).then(function(json) {
                if (json != undefined)
                    records.push(json);
            });
            
            unitPromises.push(promise);
        });
        
        return Parse.Promise.when(unitPromises);
    }).done(function() {
        response.success();
    }).fail(function(error) {
        response.error(error);
    });
});