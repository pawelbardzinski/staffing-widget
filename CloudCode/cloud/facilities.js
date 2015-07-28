/* global Parse */

var _ = require ('underscore');
var users = require ('cloud/users.js');

_.flatMap = _.compose(_.flatten, _.map);

Parse.Cloud.define("getFacility", function(request, response) {
  
    // pull in our request parameters
    var facilityId = request.params.facilityId;
    
    var query = new Parse.Query("Facility");
    query.equalTo("objectId", facilityId);
    
    var facility;
	var json;
    
    query.first().then(function(facilityResponse) {
        if (!facilityResponse) {
            throw new Error("Facility not found: " + facilityId);
        }
        
        facility = facilityResponse;
        
        var query = new Parse.Query("Unit");
        query.equalTo("facility", facility);
    
        return query.find();
    }).then(function(units) {
        var recordTimes = _.flatMap(units, function(unit) { return unit.get("shiftTimes"); });
        
        // Sort record times from earliest to latest
        recordTimes.sort(function(a, b) {
            return a - b;
        });
        
        return _.unique(recordTimes);
    }).then(function(shiftTimes) {
        json = JSON.parse(JSON.stringify(facility));
        json["shiftTimes"] = shiftTimes;

		return getStaffTypes();
	}).done(function(staffTypes) {        
		json["staffTypes"] = staffTypes;
        response.success(json);
    }).fail(function(error) {
        response.error(error);
    });
});

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
        
        return users.setUpRoles(facility);
        
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

// for data manipulation
Parse.Cloud.define("updateGrid", function(request, response) {
	var unitId = request.params.unitId;
	var staffTitle = request.params.staffTitle;
	var grids = request.params.grids;

	var Unit = Parse.Object.extend("Unit");
	var unit = new Unit();
	unit.id = unitId;

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

function getStaffTypes() {

	var promise = new Parse.Promise();
	var StaffShift = Parse.Object.extend("StaffShift");
	var staffShiftQuery = new Parse.Query(StaffShift);
	staffShiftQuery.equalTo("dayOfTheWeek", 0);

	staffShiftQuery.find().then(function(staffShifts) {
		var staffTypes = _.flatMap(staffShifts, function(shift) {
			return shift.get("title");
		});

		promise.resolve(_.unique(staffTypes));
	});

	return promise;
}

exports.getStaffTypes = getStaffTypes