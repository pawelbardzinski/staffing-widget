/* global Parse */

var _ = require ('underscore');
var utils = require ('cloud/utils.js');
var facilities = require ('cloud/facilities.js');

function getThisMonthString() {
	var todayDate = new Date()
	return utils.recordDateString(todayDate).substring(0,7);
}

Parse.Cloud.define("instanceTargetByStaffTypeReport", function(request, response) {

	var thisMonthString = request.params.thisMonthString;
	if (!thisMonthString)
	{
		thisMonthString = getThisMonthString();
	}

	var responseData = [];

	// get unique staff types
	facilities.getStaffTypes().then(function(staffTypes) {

		// do a count query on gridItems for all negative, all equal, and all positive results
		
		var staffCountPromises = [];

		var GridItem = Parse.Object.extend("GridItem");
		var Record = Parse.Object.extend("CensusRecord");

        _.each(staffTypes, function(staffType) {

			var responseObj = {};
			responseObj["staffTypeName"] = staffType;

			var recordQuery = new Parse.Query(Record);
			recordQuery.equalTo("status", "confirmed");
			recordQuery.startsWith("recordDateString", thisMonthString);

			// below instances
			var belowPromise = new Parse.Promise();
			var belowGridQuery = new Parse.Query(GridItem);
			belowGridQuery.equalTo("staffTypeName", staffType);
			belowGridQuery.lessThan("staffVariance", 0);
			belowGridQuery.matchesQuery("censusRecord", recordQuery);
			
			belowGridQuery.count().then(function(count) {
				responseObj["below"] = count;
				belowPromise.resolve();
			});

			staffCountPromises.push(belowPromise);

			// at instances
			var atPromise = new Parse.Promise();
			var atGridQuery = new Parse.Query(GridItem);
			atGridQuery.equalTo("staffTypeName", staffType);
			atGridQuery.equalTo("staffVariance", 0);
			atGridQuery.matchesQuery("censusRecord", recordQuery);
			
			atGridQuery.count().then(function(count) {
				responseObj["at"] = count;
				atPromise.resolve();
			});

			staffCountPromises.push(atPromise);

			// above instances
			var abovePromise = new Parse.Promise();
			var aboveGridQuery = new Parse.Query(GridItem);
			aboveGridQuery.equalTo("staffTypeName", staffType);
			aboveGridQuery.greaterThan("staffVariance", 0);
			aboveGridQuery.matchesQuery("censusRecord", recordQuery);
			
			aboveGridQuery.count().then(function(count) {
				responseObj["above"] = count;
				abovePromise.resolve();
			});

			responseData.push(responseObj);

			staffCountPromises.push(abovePromise);

		});

        return Parse.Promise.when(staffCountPromises);		

	}).done(function() {
        // return the facility
        response.success(responseData);
    }).fail(function(error) {
        // oh no!
        response.error(error);
    });
});

Parse.Cloud.define("personHoursByUnitReport", function(request, response) {

	var thisMonthString = request.params.thisMonthString;
	if (!thisMonthString)
	{
		thisMonthString = getThisMonthString();
	}

	// go through each unit
	var unitQuery = new Parse.Query("Unit");
	unitQuery.exists("shiftTimes");
	var responseData = [];

	unitQuery.find().then(function(units) {
		var unitPromises = [];

		_.each(units, function(unit) {

			var shiftTimes = unit.get("shiftTimes");

			var unitPromise = new Parse.Promise();
			var shiftLengths = {};
			var unitStats = {};
			unitStats["unitName"] = unit.get("name");
			
			// calculate shift length for all but the last shift
			for (var shiftIndex = 0; shiftIndex < shiftTimes.length - 1; shiftIndex++)
			{
				var shiftLength = shiftTimes[shiftIndex + 1] - shiftTimes[shiftIndex];
				shiftLengths[shiftTimes[shiftIndex]] = shiftLength;
			}
			
			// calculate the last shift
			var shiftLength = ((24 * 3600) + shiftTimes[0]) - shiftTimes[shiftTimes.length - 1];
			shiftLengths[shiftTimes[shiftTimes.length - 1]] = shiftLength;
			
			// get the grid items for this unit
			var recordQuery = new Parse.Query("CensusRecord");
			recordQuery.equalTo("unit", unit);
			recordQuery.equalTo("status", "confirmed");
			recordQuery.startsWith("recordDateString", thisMonthString);
			
			// below instances
			var gridQuery = new Parse.Query("GridItem");
			gridQuery.matchesQuery("censusRecord", recordQuery);
			gridQuery.include(["censusRecord"]);

			var actualPersonHours = 0;
			var guidelinePersonHours = 0;
			
			gridQuery.find().then(function(gridItems) {

				if (gridItems.length > 0)
				{
					var promise = Parse.Promise.as();				
					_.each(gridItems, function(gridItem) {
						
						// For each item, extend the promise with a function to delete it.
						promise = promise.then(function() {

							var shiftTime = gridItem.get("censusRecord").get("recordTime");
							var shiftLengthInHours = shiftLengths[shiftTime] / 3600;
							actualPersonHours += gridItem.get("actualStaff") * shiftLengthInHours;
							guidelinePersonHours += gridItem.get("recommendedStaff") * shiftLengthInHours

							// Return a promise that will be resolved when the delete is finished.
							return Parse.Promise.as("Success");
						});
					});

					return promise;
				} 
			}).then(function() {
				unitStats["guidelinePersonHours"] = guidelinePersonHours;
				unitStats["actualPersonHours"] = actualPersonHours;
				
				responseData.push(unitStats);
				
				unitPromise.resolve();
			});
			
			unitPromises.push(unitPromise);
			
		});

        return Parse.Promise.when(unitPromises);		
		
	}).done(function() {
        // return the facility
        response.success(responseData);
    }).fail(function(error) {
        // oh no!
        response.error(error);
    });
});

Parse.Cloud.define("instanceTargetByUnitReport", function(request, response) {

	var thisMonthString = request.params.thisMonthString;
	if (!thisMonthString)
	{
		thisMonthString = getThisMonthString();
	}

	var responseData = [];

	// get units
    var query = new Parse.Query("Unit");
    query.find().then(function(units) {

		var staffCountPromises = [];

		var GridItem = Parse.Object.extend("GridItem");
		var Record = Parse.Object.extend("CensusRecord");

        _.each(units, function(unit) {

			var responseObj = {};
			responseObj["objectId"] = unit.id;
			responseObj["name"] = unit.get("name");

			var recordQuery = new Parse.Query(Record);
			recordQuery.equalTo("status", "confirmed");
			recordQuery.equalTo("unit", unit);
			recordQuery.startsWith("recordDateString", thisMonthString);

			// below instances
			var belowPromise = new Parse.Promise();
			var belowGridQuery = new Parse.Query(GridItem);
			belowGridQuery.lessThan("staffVariance", 0);
			belowGridQuery.matchesQuery("censusRecord", recordQuery);
			
			belowGridQuery.count().then(function(count) {
				responseObj["below"] = count;
				belowPromise.resolve();
			});

			staffCountPromises.push(belowPromise);

			// at instances
			var atPromise = new Parse.Promise();
			var atGridQuery = new Parse.Query(GridItem);
			atGridQuery.equalTo("staffVariance", 0);
			atGridQuery.matchesQuery("censusRecord", recordQuery);
			
			atGridQuery.count().then(function(count) {
				responseObj["at"] = count;
				atPromise.resolve();
			});

			staffCountPromises.push(atPromise);

			// above instances
			var abovePromise = new Parse.Promise();
			var aboveGridQuery = new Parse.Query(GridItem);
			aboveGridQuery.greaterThan("staffVariance", 0);
			aboveGridQuery.matchesQuery("censusRecord", recordQuery);
			
			aboveGridQuery.count().then(function(count) {
				responseObj["above"] = count;
				abovePromise.resolve();
			});

			staffCountPromises.push(abovePromise);

			responseData.push(responseObj);

		});

        return Parse.Promise.when(staffCountPromises);		

	}).done(function() {
        // return the facility
        response.success(responseData);
    }).fail(function(error) {
        // oh no!
        response.error(error);
    });

});
