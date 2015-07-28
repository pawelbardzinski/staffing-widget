/* global Parse */

var _ = require ('underscore');
var utils = require('cloud/utils.js');

Parse.Cloud.define("getRecord", function(request, response) {
  
    // pull in our request parameters
    var unitId = request.params.unitId;
    var recordTime = parseInt(request.params.recordTime);
    var recordDateString = request.params.recordDateString; // need to append ms to timestamp
  
    getOrCreateRecord(unitId, recordTime, recordDateString).done(function(json) {
        response.success(json);
    }).fail(function(error) {
        response.error(error);
    });
});

function getOrCreateRecord(unitId, recordTime, recordDateString) {
    // Create a variable to store the unit and shiftIndex in later
    var unit;
    var shiftIndex = -1;
    
    var query = new Parse.Query("Unit");
    query.equalTo("objectId", unitId);

    return query.find().then(function(units) {
        if (units.length != 1) {
            throw new Error("Requested unit not found!")
        }

        unit = units[0];

        var shiftTimes = unit.get("shiftTimes");
		var totalShiftTimes = shiftTimes.length;
        shiftIndex = shiftTimes.indexOf(recordTime);

        if (shiftIndex == -1) {
            throw new Error("Requested record time does not exist")
        }

        var query = new Parse.Query("CensusRecord");
  
        query.equalTo("unit", unit);
        query.lessThanOrEqualTo("recordDateString", recordDateString);        
		query.limit(totalShiftTimes + 1);
		query.descending('recordDateString,recordTime');

        return query.find()
    }).then(function(recordResults) {
		
		var existingRecord;
		var previousRecord;
		for (var x = 0; x < recordResults.length; x++)
		{

			if ((recordResults[x].get("recordDateString") == recordDateString && recordResults[x].get("recordTime") < recordTime) || (recordResults[x].get("recordDateString") != recordDateString))
			{
				previousRecord = recordResults[x];
				break;
			}
			else if (recordResults[x].get("recordDateString") == recordDateString && recordResults[x].get("recordTime") == recordTime) {
				existingRecord = recordResults[x];
				if (recordResults.length > x+1)
				{
					previousRecord = recordResults[x+1];
				}
				break;
			}
		}

		var previousCensus = 0;
		if (previousRecord) {
			previousCensus = previousRecord.get("census");
		}

        if (existingRecord) {
            // we have a single unique record.  Lets generate and return the JSON
            return createRecordJSON(unit, existingRecord, previousCensus)
        } else {
            return createNewRecordJSON(unit, shiftIndex, recordDateString, recordTime, previousCensus)
        } 
    });
}

Parse.Cloud.define("getExistingRecord", function(request, response) {
  
    // pull in our request parameters
    var recordId = request.params.recordId;
    
    var query = new Parse.Query("CensusRecord");
    query.equalTo("objectId", recordId);
    query.include("unit");

    query.first().then(function(record) {
        if (!record) {
            throw new Error("Requested record not found!")
        }

        var unit = record.get("unit");
        
        return createRecordJSON(unit, record);
    }).done(function(json) {
        response.success(json);
    }).fail(function(error) {
        response.error(error);
    });
});

Parse.Cloud.define("getLastDayRecords", function(request, response) {
  
     // pull in our request parameters
    var facilityId = request.params.facilityId;
    var currentSecondsFromMidnight = parseInt(request.params.currentSecondsFromMidnight);    
    var currentDateString = request.params.currentDateString;
    
    var Facility = Parse.Object.extend("Facility");
    var facility = new Facility();
    facility.id = facilityId;
    
    // For later
    var records = [];
     
    var query = new Parse.Query("Unit");
    query.equalTo("facility", facility);
    query.exists("shiftTimes");
    query.find().then(function(units) {
        
        var unitPromises = [];
        
        _.each(units, function(unit) {
            var shiftTimes = unit.get("shiftTimes")
            for (var shiftIndex = 0; shiftIndex < shiftTimes.length; shiftIndex++)
            {
                var lockTime = shiftTimes[shiftIndex] + 30 * 60;
                
                var editable = currentSecondsFromMidnight < lockTime;
                
                // if our current time is after the previous shift, then create the record
                // this will give us all past records, and the next upcoming record, and no more
                if ((shiftIndex == 0 || shiftTimes[shiftIndex-1] < currentSecondsFromMidnight) && editable)
                {
                    var promiseForToday = getOrCreateRecord(unit.id, shiftTimes[shiftIndex], currentDateString).then(function(json) {
                        if (json != undefined)
                            records.push(json);
                    });

                    unitPromises.push(promiseForToday);
                }
            }
        });
        
        return Parse.Promise.when(unitPromises);
    }).done(function() {
        
        records.sort(chronologicalRecords);
        
        response.success(records);
    }).fail(function(error) {
        response.error(error);
    });
});

// fires off the push notifications if there are variances in the record
Parse.Cloud.afterSave("CensusRecord", function(request) {

    Parse.Cloud.useMasterKey();
    
	// the updated record
	var record = request.object;
	var gridItemsRelation = record.relation("gridItems");
	
	// update the grid items to point to the censusRecord
	gridItemsRelation.query().find().then(function(gridItems) {

		if (gridItems.length > 0 && gridItems[0].get("censusRecord") === undefined)
		{
			_.each(gridItems, function(gridItem) {
				gridItem.set("censusRecord", record);
			});
				
			Parse.Object.saveAll(gridItems);		
		}
	});

	// catch the record that isn't confirmed for the first time
	if (record.get("status") != "confirmed" || record.get("previousStatus") == "confirmed")
	{
		// update previous status if necessary
		if (record.get("status") != record.get("previousStatus"))
		{
			record.set("previousStatus", record.get("status"));
			record.save();
		}
		return;
	}

	// update previous status
	record.set("previousStatus", record.get("status"));
	record.save();
	
	// send the notification
	var unitName = "";
	var recordReason = record.get("reason");
	var recordComments = record.get("comments");
	var recordTime = record.get("recordTime");
	var recordId = record.id;
	
	var now = new Date();
	record.set("recordDate", now);
	record.save();
	
	var users = [];
	var unit;
	var unitACL;
	
	record.get("unit").fetch().then(function(unitResponse) {
		
		unit = unitResponse;
		unitACL = unit.getACL();
		
		return unit.get("facility").fetch();
	}).then(function(facility) {
		
		if (!facility.get("notifications")) {
			throw new Error("Notifications are disabled for " + facility.get("name"));
		}
		
		var negativeQuery = record.relation("gridItems").query();
		var positiveQuery = record.relation("gridItems").query();
		negativeQuery.lessThan("staffVariance", facility.get("negativeNotificationThreshold"));
		positiveQuery.greaterThan("staffVariance", facility.get("positiveNotificationThreshold"));
		
		return Parse.Query.or(positiveQuery, negativeQuery).count();
	}).then(function(numberGridItems) {	
		if (numberGridItems == 0)
		{
			throw new Error("No grid items have a variance above the threshold!");
		}
		
		var roleQuery = new Parse.Query(Parse.Role);
		roleQuery.include("info");
		
		roleQuery.equalTo("facility", unit.get("facility"));
		
		return roleQuery.find();
	}).then(function(roles) {
		
		var promises = [];
		
		_.each(roles, function(role) {
			var info = role.get("info");
			
			if (info !== undefined && info.get("notifications") && unitACL.getRoleReadAccess(role)) {
				promises.push(role.getUsers().query().find().then(function(roleUsers) {
					users = users.concat(roleUsers);
				}));
			}
		});
		
		return Parse.Promise.when(promises);
	}).then(function() {
		
		var userQuery = new Parse.Query(Parse.User);
		userQuery.include("roleInfo");
		
		userQuery.equalTo("facility", unit.get("facility"));
		
		return userQuery.find();
	}).then(function(facilityUsers) {
		
		_.each(facilityUsers, function(user) {
			var info = user.get("roleInfo");
			
			if (info !== undefined && info.get("notifications") && unitACL.getReadAccess(user)) {
				users.push(user);
			}
		});
	}).done(function() {
		console.log(users.length + " users will be notified");
		
		// query the installations
		var installationQuery = new Parse.Query(Parse.Installation);
		
		installationQuery.containedIn("user", users);
		
		Parse.Push.send({
			where: installationQuery,
			data: {
				alert: "Record time: " + utils.formatTime(recordTime) + " " + unitName + 
                       " Variance: " + recordReason + " - " + recordComments,
				recordId: recordId,
				sound: "default"
			}
		}, {
			success: function() {
				// Push was successful
				return;
			},
			error: function(error) {
				// Handle error
				console.log(error);
			}
		});
	}).fail(function(error) {
		console.log(error);
	});
});

function createNewRecordJSON(unit, shiftIndex, recordDateString, recordTime, previousCensus) {
    if (previousCensus == undefined) previousCensus = 0;
    
    var dateFromString = new Date(recordDateString);
    var dayOfTheWeek = dateFromString.getDay();
    
    var relation = unit.relation("staffShifts");
    var shiftQuery = relation.query();

    // Time based query filter
    shiftQuery.equalTo("dayOfTheWeek", dayOfTheWeek);

    return shiftQuery.find().then(function(staffShifts) {
        var gridItems = [];

        for (var a = 0; a < staffShifts.length; a++) {
            var gridItem = {
                "availableStaff": 0,
                "requestedStaff": 0,
                "staffTypeName": staffShifts[a].get("title"),
                "staffVariance": 0,
                "grid": staffShifts[a].get("grids")[shiftIndex],
                "required": staffShifts[a].get("required"),
                "visible": staffShifts[a].get("required"),
                "index": staffShifts[a].get("index"),
                "changes": [],
				"recordDateString": recordDateString,
				"get": getFunc

            };

            gridItems.push(gridItem);
        }
        
        gridItems.sort(function(a, b) {
            return a["index"] - b["index"];
        });

        return gridItems;
    }).then(function(gridItems) {
        var json = {
            "unit": unit,
            "recordDateString": recordDateString,
            "recordTime": recordTime,
			"status": "new",
            "census": previousCensus,
			"previousCensus": previousCensus,
            "comments": "",
            "reason": "",
            "confirmed": false,
            "gridItems": gridItems,
			"get": getFunc
        };
        
        return json;
    });
}
    
exports.getRecordForTimestamp = function(unit, recordTime, recordDateString) {
    console.log("Retrieving record for unit: " + unit.id)

    var query = new Parse.Query("CensusRecord");

    query.equalTo("unit", unit);
    query.equalTo("recordDateString", recordDateString);
    query.equalTo("recordTime", recordTime);

    return query.find().then(function(records) {
        if (records.length == 1) {
            return records[0];
        } else if (records.length > 1) {
            throw new Error("Too many records for the specified day and time!")
        }
    });
} 

function createRecordJSON(unit, record, previousCensus) {
    if (previousCensus == undefined) previousCensus = 0;
    
    var gridItems = [];
        
    var relation = record.relation("gridItems");
  
    return relation.query().find().then(function(gridItemResults) {
        var promises = [];       
            
        for (var a = 0; a < gridItemResults.length; a++) {
            promises.push(createGridItemJSON(gridItemResults[a], record).then(function(json) {
                gridItems.push(json);
            }));
        }
        
        return Parse.Promise.when(promises);
    }).then(function() {
        gridItems.sort(function(a, b) {
            return a["index"] - b["index"];
        });

        return gridItems;
    }).then(function(gridItems) {
        var json = {
            "objectId": record.id,
            "unit": unit,
            "recordDateString": record.get("recordDateString"),
            "recordTime": record.get("recordTime"),
            "census": record.get("census"),
			"previousCensus": previousCensus,
            "comments": record.get("comments"),
            "reason": record.get("reason"),
			"status": record.get("status"),
            "gridItems": gridItems,
			"get": getFunc
        };

        return json;  
    });
    
    function createGridItemJSON(gridItemResult, record) {
        var query1 = new Parse.Query("StaffChange");
        query1.equalTo("recordDateString", record.get("recordDateString"));
        query1.equalTo("recordTime", record.get("recordTime"));
        query1.equalTo("staffTypeName", gridItemResult.get("staffTypeName"));
        query1.equalTo("fromUnit", record.get("unit"));
        
        var query2 = new Parse.Query("StaffChange");
        query2.equalTo("recordDateString", record.get("recordDateString"));
        query2.equalTo("recordTime", record.get("recordTime"));
        query2.equalTo("staffTypeName", gridItemResult.get("staffTypeName"));
        query2.equalTo("toUnit", record.get("unit"));
        
        return Parse.Query.or(query1, query2).include("fromUnit").include("toUnit").find().then(function(changes) {
            var mappedChanges = changes.map(function(change) {
                if (change.get("toUnit") && change.get("toUnit").id == record.get("unit").id) {
                    return change
                } else {
                    var reversedChange = change.get("changeType") == "move" ? "move"
                            : change.get("changeType") == "flex_off" ? "call_extra"
                            : change.get("changeType") == "call_extra" ? "flex_off"
                            : "" 
                    
                    return {
                        "staffTypeName": change.get("staffTypeName"),
                        "changeType": reversedChange,
                        "count": -1 * change.get("count"),
                        "fromUnit": change.get("toUnit"),
                        "toUnit": change.get("fromUnit")
                    }
                }
            });
                
            var gridItem = {
                "objectId": gridItemResult.id,
                "availableStaff": gridItemResult.get("availableStaff"),
                "requestedStaff": gridItemResult.get("requestedStaff"),
                "staffTypeName": gridItemResult.get("staffTypeName"),
                "staffVariance": gridItemResult.get("staffVariance"),
                "grid": gridItemResult.get("grid"),
                "required": gridItemResult.get("required"),
                "visible": gridItemResult.get("visible"),
                "index": gridItemResult.get("index"),
                "changes": mappedChanges,
				"recordDateString": gridItemResult.get("recordDateString"),
				"get": getFunc
            };
            
            return gridItem;
        });
    }
}

function getFunc(param) {
	return this[param];
}

function chronologicalRecords(a,b) {
    if (a.get("recordDateString") > b.get("recordDateString"))
    {
        return -1;
    } else if (a.get("recordDateString") < b.get("recordDateString"))
    {
        return 1;
    } else if (a.get("recordTime") != b.get("recordTime")) {
        return b.get("recordTime") - a.get("recordTime");
    } else {
		if (a.unit.get("name") > b.unit.get("name"))
		{
			return -1;
		} else if (a.unit.get("name") < b.unit.get("name"))
		{
			return 1;
		} 
		return 0;
	}
}

exports.createRecordJSON = createRecordJSON
