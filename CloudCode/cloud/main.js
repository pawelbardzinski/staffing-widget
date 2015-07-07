var _ = require ('underscore');

Date.prototype.reportDateFormat = function() {
   var year = this.getFullYear().toString();
   var month = (this.getMonth()+1).toString(); // getMonth() is zero-based
   var day = this.getDate().toString();
   if (month.length < 2) month = '0' + month;
   if (day.length < 2) day = '0' + day;
    
   return [year, month, day].join('-');
};

function chronologicalReports(a,b) {
    if (a.get("reportingDateString") > b.get("reportingDateString"))
    {
        return -1;
    } else if (a.get("reportingDateString") < b.get("reportingDateString"))
    {
        return 1;
    } else if (a.get("reportingTime") != b.get("reportingTime")) {
        return b.get("reportingTime") - a.get("reportingTime");
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

Parse.Cloud.define("createUnitsWithTestData", function(request, response) {
    var facilityName = request.params.facilityName;
    var unitNames = request.params.units;
    var gridTemplate = request.params.gridTemplate;
    var maxCensus = request.params.maxCensus;
    var staffNames = request.params.staffNames;
    var floor = request.params.floor;
    var shiftTimes = request.params.shiftTimes;
    
    // convert shift times to seconds
    for (var y = 0; y < shiftTimes.length; y++)
    {
        shiftTimes[y] = shiftTimes[y] * 60 * 60;
        console.log(shiftTimes[y])
    }
    
    // setup the grid of grids template
    var gridOfGrids = [];
    while (gridOfGrids.length < shiftTimes.length)
    {
        gridOfGrids.push(gridTemplate);
    }
    
    // for returning the facility at the end
    var facilityId;
    var facility;
    
    var Facility = Parse.Object.extend("Facility");
    
    var query = new Parse.Query(Facility);
    query.equalTo("name", facilityName);
    
    // save the facility
    query.find().then(function(facilities) {
        
        if (facilities.length == 0)
        {
            facility = new Facility();
            facility.set("name", facilityName);
        } else {
            facility = facilities[0];
        }
        
        return facility.save();
        
    }).then(function(facility) {
        // store facility id for the final return
        facilityId = facility.id;
        
        var unitsToSave = [];
        var Unit = Parse.Object.extend("Unit");
        
        // create all the units
        for (var x = 0; x < unitNames.length; x++)
        {   
            // create a unit
            var unit = new Unit();
            unit.set("name", unitNames[x]);
            unit.set("facility", facility);   
            unit.set("floor", floor);
            unit.set("maxCensus", maxCensus);   
            unit.set("shiftTimes", shiftTimes)
            unitsToSave.push(unit);            
        }
        
        return Parse.Object.saveAll(unitsToSave);
    }).then(function(newUnits){
        
        // if no units, return
        if (newUnits.length == 0)
        {
            throw new Error("no units created");
        }
        
        // relate the units to the Facility
        var facility = newUnits[0].get("facility");
        var relationship = facility.relation("units")
        relationship.add(newUnits);
        
        facility.save();
        
        // create StaffShifts for each Unit
        var unitPromises = [];
        
        _.each(newUnits, function(unit) {

            var promise = new Parse.Promise();
            var StaffShift = Parse.Object.extend("StaffShift");
            var staffShiftsToSave = [];
            
            // for every day of the week
            for (var dayIndex = 0; dayIndex < 7; dayIndex++)
            {
                // for every staff name
                for (var staffIndex = 0; staffIndex < staffNames.length; staffIndex++)
                {
                    var staffShift = new StaffShift();
                    staffShift.set("grids", gridOfGrids);
                    staffShift.set("required", true)
                    staffShift.set("unit", unit);
                    staffShift.set("title", staffNames[staffIndex]);
                    staffShift.set("dayOfTheWeek", dayIndex);
                    staffShift.set("index", staffIndex);
                    staffShiftsToSave.push(staffShift);
                }
            }
            
            // save the StaffShifts and relate them to the unit
            Parse.Object.saveAll(staffShiftsToSave, function (staffShifts, error) {
                if (staffShifts) {
                    var staffRelation = unit.relation("staffShifts");
                    staffRelation.add(staffShifts)
                
                    promise.resolve(unit.save());
                
                } else {
                    promise.reject(error);
                }
            });
            
            
            // add promise to the list
            unitPromises.push(promise);
        });

        // Return a new promise that is resolved when all of the promises in the array are finished.
        return Parse.Promise.when(unitPromises);
            
    }).then(function(){
        
        return setUpRoles(facility);
        
    }).done(function() {
        // return the facility
        response.success(facility);
    }).fail(function(error) {
        // oh no!
        response.error(error);
    });
});

Parse.Cloud.define("deleteFacility", function(request, response) {
    var facilityId = request.params.facilityId;
    
    var Facility = Parse.Object.extend("Facility");
    var Unit = Parse.Object.extend("Unit");
    var StaffShift = Parse.Object.extend("StaffShift");
    
    var facility;
    var units;
    
    var query = new Parse.Query(Facility);
    query.equalTo("objectId", facilityId);
    
    query.find().then(function(facilityResponse) {
        if (facilityResponse.length != 1) {
            throw new Error("Facility not found!");
        }
        facility = facilityResponse[0];
        
        var query = new Parse.Query(Unit);
        query.equalTo("facility", facility);
    
        return query.find();
    }).then(function(unitsResponse) {
        units = unitsResponse;
        
        // Delete all staff shifts
        var promises = [];
        
        units.forEach(function(unit) {
            var relation = unit.relation("staffShifts");
                	
            promises.push(relation.query().find().then(function(shifts) {
                return Parse.Object.destroyAll(shifts);
            }));
        });
        
        return Parse.Promise.when(promises);
    }).then(function() {
        // Delete all units
        return Parse.Object.destroyAll(units);
    }).then(function() {
        var query = new Parse.Query(Parse.Role);
        query.equalTo("facility", facility);
    
        return query.find();
    }).then(function(roles) {
        // Delete all roles
        return Parse.Object.destroyAll(roles);
    }).then(function() {
        facility.destroy();
    }).done(function(json) {
        response.success();
    }).fail(function(error) {
        response.error(error);
    });
});

Parse.Cloud.define("updateUserRole", function(request, response) {
	var username = request.params.username;
	var role = request.params.role;
	var assignedUnits = request.params.assignedUnits;
    
    var query = new Parse.Query("_User");
	query.equalTo("username", username);
    
    query.find().then(function(users) {
        if (users.length != 1)
            throw new Error("User not found!");
        
        return updateUserRole(users[0], role, assignedUnits);
    }).done(function() {
		response.success();
	}).fail(function(error) {
        response.error(error);
    });
});

// for data manipulation
Parse.Cloud.define("updateGrid", function(request, response) {
	var unitId = request.params.unitId;
	var staffTitle = request.params.staffTitle;
	var grids = request.params.grids;

	var Unit = Parse.Object.extend("Unit");
	var unit = new Unit();
	unit.id = unitId;

	var StaffShift = Parse.Object.extend("StaffShift");
	var query = new Parse.Query("StaffShift");
	query.equalTo("unit", unit);
	query.equalTo("title", staffTitle);
	query.find().then(function(staffShifts) {
		for (var x = 0; x < staffShifts.length; x++)
		{
			staffShifts[x].set("grids", grids);
		}

		return Parse.Object.saveAll(staffShifts);
	}).done(function(staffShifts) {
		response.success(staffShifts);
	}).fail(function(error) {
        response.error(error);
    });
});

Parse.Cloud.define("getReport", function(request, response) {
  
    // pull in our request parameters
    var unitId = request.params.unitId;
    var reportingTime = parseInt(request.params.reportingTime);
    var reportingDateString = request.params.reportingDateString; // need to append ms to timestamp
  
    getOrCreateReport(unitId, reportingTime, reportingDateString).done(function(json) {
        response.success(json);
    }).fail(function(error) {
        response.error(error);
    });
});

function getOrCreateReport(unitId, reportingTime, reportingDateString)
{
    // Create a variable to store the unit and shiftIndex in later
    var unit;
    var shiftIndex = -1;

    // Get the day of the week to find the shift 
    var reportingDate = new Date(reportingDateString);
    var dayOfTheWeek = reportingDate.getDay();
    
    var query = new Parse.Query("Unit");
    query.equalTo("objectId", unitId);

    return query.find().then(function(units) {
        if (units.length != 1) {
            throw new Error("Requested unit not found!")
        }

        unit = units[0];

        var shiftTimes = unit.get("shiftTimes");
		var totalShiftTimes = shiftTimes.length;
        shiftIndex = shiftTimes.indexOf(reportingTime);

        if (shiftIndex == -1) {
            throw new Error("Requested reporting time does not exist")
        }

        var query = new Parse.Query("Report");
  
        query.equalTo("unit", unit);
        query.lessThanOrEqualTo("reportingDateString", reportingDateString);        
		query.limit(totalShiftTimes + 1);
		query.descending('reportingDateString,reportingTime');

        return query.find()
    }).then(function(reportResults) {
		
		var existingReport;
		var previousReport;
		for (var x = 0; x < reportResults.length; x++)
		{

			if ((reportResults[x].get("reportingDateString") == reportingDateString && reportResults[x].get("reportingTime") < reportingTime) || (reportResults[x].get("reportingDateString") != reportingDateString))
			{
				previousReport = reportResults[x];
				break;
			}
			else if (reportResults[x].get("reportingDateString") == reportingDateString && reportResults[x].get("reportingTime") == reportingTime) {
				existingReport = reportResults[x];
				if (reportResults.length > x+1)
				{
					previousReport = reportResults[x+1];
				}
				break;
			}
		}

		var previousCensus = 0;
		if (previousReport) {
			previousCensus = previousReport.get("census");
		}

        if (existingReport) {
            // we have a single unique report.  Lets generate and return the JSON
            return createReportJSON(unit, existingReport, previousCensus)
        } else {
            return createNewReportJSON(unit, shiftIndex, reportingDateString, reportingTime, previousCensus)
        } 
    })
}

Parse.Cloud.define("getExistingReport", function(request, response) {
  
    // pull in our request parameters
    var reportId = request.params.reportId;
    
    var query = new Parse.Query("Report");
    query.equalTo("objectId", reportId);
    query.include("unit");

    query.first().then(function(report) {
        if (!report) {
            throw new Error("Requested report not found!")
        }

        var unit = report.get("unit");
        
        return createReportJSON(unit, report);
    }).done(function(json) {
        response.success(json);
    }).fail(function(error) {
        response.error(error);
    });
});

Parse.Cloud.define("getCurrentReports", function(request, response) {
  
     // pull in our request parameters
    var facilityId = request.params.facilityId;
    var currentTime = request.params.currentTime;
    var dateString = request.params.dateString;
    
    
    var Facility = Parse.Object.extend("Facility");
    var facility = new Facility();
    facility.id = facilityId;
    
    // For later
    var reports = [];
     
    var query = new Parse.Query("Unit");
    query.equalTo("facility", facility);
    
    query.find().then(function(units) {
        var unitPromises = [];
        
        _.each(units, function(unit) {
            var promise = getCurrentReport(unit, currentTime, dateString).then(function(json) {
                if (json != undefined)
                    reports.push(json);
            });
            
            unitPromises.push(promise);
        });
        
        return Parse.Promise.when(unitPromises);
    }).done(function() {
        response.success(reports);
    }).fail(function(error) {
        response.error(error);
    });
    
    function getCurrentReport(unit, currentTime, reportingDateString) {
        console.log("Retrieving report for unit: " + unit.id)
    
        var shiftIndex = -1;
        var shifts = unit.get("shiftTimes");
        for (var i = 0; i < shifts.length; i++) {
            if (shifts[i] > currentTime) {
                shiftIndex = i;
                break;
            }
        
        }
    
        if (shiftIndex == -1) {
            shiftIndex = 0;
            reportingDay++;
        }
    
        var reportingTime = shifts[shiftIndex];
      
        var query = new Parse.Query("Report");
  
        query.equalTo("unit", unit);
        query.equalTo("reportingDateString", reportingDateString);
        query.equalTo("reportingTime", reportingTime);
    
        return query.find().then(function(reports) {
            if (reports.length == 1) {
                return createReportJSON(unit, reports[0]);
            } else if (reports.length > 1) {
                throw new Error("Too many reports for the specified day and time!")
            }
        })
    } 
});

Parse.Cloud.define("getLastDayReports", function(request, response) {
  
     // pull in our request parameters
    var facilityId = request.params.facilityId;
    var currentSecondsFromMidnight = parseInt(request.params.currentSecondsFromMidnight);    
    var currentDateString = request.params.currentDateString
    
    // get time 24 hours ago
    var yesterdayDate = new Date(currentDateString)
    yesterdayDate.setDate(yesterdayDate.getDate()-1)
    var yesterdayDateString = yesterdayDate.reportDateFormat()
    
    var Facility = Parse.Object.extend("Facility");
    var facility = new Facility();
    facility.id = facilityId;
    
    // For later
    var reports = [];
     
    var query = new Parse.Query("Unit");
    query.equalTo("facility", facility);
    
    query.find().then(function(units) {
        
        var unitPromises = [];
        
        _.each(units, function(unit) {
            var shiftTimes = unit.get("shiftTimes")
            for (var shiftIndex = 0; shiftIndex < shiftTimes.length; shiftIndex++)
            {
                // yesterday
                var promiseForYesterday = getOrCreateReport(unit.id, shiftTimes[shiftIndex], yesterdayDateString).then(function(json) {
                    if (json != undefined)
                        reports.push(json);
                });
                
                unitPromises.push(promiseForYesterday);
                
                // today
                // if our current time is after the previous shift, then create the report
                // this will give us all past reports, and the next upcoming report, and no more
                if (shiftIndex == 0 || shiftTimes[shiftIndex-1] < currentSecondsFromMidnight)
                {
                    var promiseForToday = getOrCreateReport(unit.id, shiftTimes[shiftIndex], currentDateString).then(function(json) {
                        if (json != undefined)
                            reports.push(json);
                    });

                    unitPromises.push(promiseForToday);
                }
            }
        });
        
        return Parse.Promise.when(unitPromises);
    }).done(function() {
        
        reports.sort(chronologicalReports);
        
        response.success(reports);
    }).fail(function(error) {
        response.error(error);
    });
});

// fires off the push notifications if there are variances in the report
Parse.Cloud.afterSave("Report", function(request) {
	var report = request.object;
    var relation = report.relation("gridItems");
    var unitName = "";
	var reportReason = report.get("reason");
	var reportComments = report.get("comments");
	var reportingTime = report.get("reportingTime");
	var reportId = report.id;
    
    var now = new Date();
    report.set("reportingDate", now);
    report.save();

	var negativeVarianceQuery = relation.query();
	negativeVarianceQuery.lessThan("staffVariance", 0);
    negativeVarianceQuery.count().then(function(numberGridItems) {	
		if (numberGridItems == 0)
        {
			return;
		}

		var unit = report.get("unit");
		
		unit.fetch().then(function(unit) {
			// get the emails of users to notify
			var emails = unit.get("notificationEmails");
			unitName = unit.get("name");
			
			//query.containedIn(
			var userQuery = new Parse.Query(Parse.User);
			userQuery.containedIn("username", emails);
			return userQuery.find();
		}).then(function(users) {
			// query the installations
			var installationQuery = new Parse.Query(Parse.Installation);
			
			installationQuery.containedIn("user", users);
			
			Parse.Push.send({
				where: installationQuery,
				data: {
					alert: "Report time: " + formatTime(reportingTime) + " " + unitName + " Variance: " + reportReason + " - " + reportComments,
					reportId: reportId,
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
		});
	});
});

function formatTime(time) {
    var hours = time/3600;
    var postfix = hours >= 12 ? "PM" : "AM";

    if (hours == 0) {
        return "12 " + postfix;
    } else if (hours > 12) {
        return (hours - 12) + " " + postfix;
    } else {
        return hours + " " + postfix;
    }
}
  
function createNewReportJSON(unit, shiftIndex, reportingDateString, reportingTime, previousCensus) {
    if (previousCensus == undefined) previousCensus = 0;
    
    var dateFromString = new Date(reportingDateString);
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
                "actualStaff": 0,
                "staffTypeName": staffShifts[a].get("title"),
                "staffVariance": 0,
                "grid": staffShifts[a].get("grids")[shiftIndex],
                "required": staffShifts[a].get("required"),
                "visible": staffShifts[a].get("required"),
                "index": staffShifts[a].get("index"),
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
            "reportingDateString": reportingDateString,
            "reportingTime": reportingTime,
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

function createReportJSON(unit, report, previousCensus) {
    if (previousCensus == undefined) previousCensus = 0;
    
    var relation = report.relation("gridItems");
  
    return relation.query().find().then(function(gridItemResults) {
        var gridItems = [];
            
        for (var a = 0; a < gridItemResults.length; a++) {
          
            var gridItem = {
                "objectId": gridItemResults[a].id,
                "availableStaff": gridItemResults[a].get("availableStaff"),
                "actualStaff": gridItemResults[a].get("actualStaff"),
                "staffTypeName": gridItemResults[a].get("staffTypeName"),
                "staffVariance": gridItemResults[a].get("staffVariance"),
                "grid": gridItemResults[a].get("grid"),
                "required": gridItemResults[a].get("required"),
                "visible": gridItemResults[a].get("visible"),
                "index": gridItemResults[a].get("index"),
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
            "objectId": report.id,
            "unit": unit,
            "reportingDateString": report.get("reportingDateString"),
            "reportingTime": report.get("reportingTime"),
            "census": report.get("census"),
			"previousCensus": previousCensus,
            "comments": report.get("comments"),
            "reason": report.get("reason"),
            "confirmed": report.get("confirmed"),
            "gridItems": gridItems,
			"get": getFunc
        };

        return json;  
    });
}

function getFunc(param) {
	return this[param];
}

function updateUserRole(user, roleName, assignedUnits) {
    var facility;
    var units;
    var role;
    
    return user.get("facility").fetch().then(function(facilityResponse) {
        facility = facilityResponse;
        
        var query = new Parse.Query("Unit");
        query.equalTo("facility", facility);
        
        return query.find();
    }).then(function(unitsResponse) {
        units = unitsResponse;
        
        // First remove user from all assigned units
        
        _.each(units, function(unit) {
            if (assignedUnits.indexOf(unit.id) == -1) {
                unit.getACL().setReadAccess(user, false);
                unit.getACL().setWriteAccess(user, false);
            } else {
                unit.getACL().setReadAccess(user, true);
            }
        });
        
        return Parse.Object.saveAll(units);
    }).then(function() {
        var query = new Parse.Query(Parse.Role);
        return query.equalTo("users", user).find();
    }).then(function(roles) {
        // Remove the user from all roles
        
        _.each(roles, function(role) {
            role.getUsers().remove(user);
        });
        
        return Parse.Object.saveAll(roles);
    }).then(function() {
        var query = new Parse.Query(Parse.Role);
        return query.equalTo("name", facility.id + " - " + roleName).include("info").find();
    }).then(function(roles) {
        if (roles.length == 0)
            throw new Error("Role not found: " + roleName);
        else if (roles.length != 1)
            throw new Error("There can be only one instance of the specified role!");
        
        role = roles[0];
        
        // Add the user to the role
        role.getUsers().add(user);
        return role.save();
    }).then(function() {
        user.set("roleInfo", role.get("info"));
        return user.save(null, { useMasterKey: true });
    });
}
  
function setUpRoles(facility) {
    var roleACL = new Parse.ACL();
    roleACL.setRoleReadAccess("admin", true);
    roleACL.setRoleWriteAccess("admin", true);
    
    var facilityRole = new Parse.Role(facility.id, roleACL);
    facilityRole.set("facility", facility);
    
    var facilityACL = new Parse.ACL();
    facilityACL.setRoleReadAccess("admin", true);
    facilityACL.setRoleWriteAccess("admin", true);
    
    var rolesInfo = [];
    
    return facilityRole.save().then(function() {
        // Get a list of all role info objects
        facilityACL.setRoleReadAccess(facilityRole, true);
        
        var RoleInfo = Parse.Object.extend("RoleInfo");
        
        var query = new Parse.Query(RoleInfo);
        
        return query.find();
    }).then(function(list) {
        // Create a role for the facility based on each role info object
        rolesInfo = list;
        
        var roles = [];
        
        _.each(rolesInfo, function(roleInfo) {
            var role = new Parse.Role(facility.id + " - " + roleInfo.get("name"), roleACL);
            role.set("info", roleInfo);
            role.set("facility", facility);
            
            roles.push(role);
        });
        
        return Parse.Object.saveAll(roles);
    }).then(function(roles) {
        _.each(roles, function(role) {
            facilityRole.getRoles().add(role);
        });
        
        return facilityRole.save();
    }).then(function() {
        // Allow a user with edit facility perms to write to the facility object    
        _.each(rolesInfo, function(roleInfo) {
            if (roleInfo.get("editFacility") == true) {
                facilityACL.setRoleWriteAccess(facility.id + " - " + roleInfo.get("name"), true);
            }
        });
    
        // Retrieve all units
        var query = new Parse.Query("Unit");
        query.equalTo("facility", facility);
        
        return query.find();
    }).then(function(units) {
        // Allow a user with edit facility perms to read and write all units
        // Allow a user with view all units perms to read all units
        _.each(units, function(unit) {
            var unitACL = new Parse.ACL();
            
            unitACL.setRoleReadAccess("admin", true);
            unitACL.setRoleWriteAccess("admin", true);
                    
            _.each(rolesInfo, function(roleInfo) {
                if (roleInfo.get("editFacility") == true) {
                    unitACL.setRoleReadAccess(facility.id + " - " + roleInfo.get("name"), true);
                    unitACL.setRoleWriteAccess(facility.id + " - " + roleInfo.get("name"), true);
                } else if (roleInfo.get("viewAllUnits") == true) {
                    unitACL.setRoleReadAccess(facility.id + " - " + roleInfo.get("name"), true);
                }
            });
            
            unit.setACL(unitACL);
        });
        
        return Parse.Object.saveAll(units);
    }).then(function() {
        facility.setACL(facilityACL);
        return facility.save();
    });
}
