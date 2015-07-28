// Record Client for testing
//

import Foundation

class RecordClientTestImplementation: CensusClient {
    
    func saveRecord(record: CensusRecord, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> () ) {
        //noop
    }
    
    func getRecord(unitId: String, timestamp: RecordTimestamp, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> () ) {
        var record = self.record
        record.unit.objectId = unitId
        successHandler(record: record)
    }

    func getRecord(recordId: String, successHandler: (record: CensusRecord) -> (), failureHandler: (error: NSError) -> () ) {
        var record = self.record
        record.objectId = recordId
        successHandler(record: record)
    }
    
    func getCurrentWorksheet(facilityId: String, successHandler: (worksheet: Worksheet) -> (), failureHandler: (error: NSError) -> ()) {
        var worksheet = self.worksheet
        successHandler(worksheet: worksheet)
    }
    
    func getWorksheet(facilityId: String, timestamp: RecordTimestamp, successHandler: (worksheet: Worksheet) -> (), failureHandler: (error: NSError) -> ()) {
        var worksheet = self.worksheet
        successHandler(worksheet: worksheet)
    }
    
    func saveWorksheet(worksheet: Worksheet, successHandler: (worksheet: Worksheet) -> (), failureHandler: (error: NSError) -> ()) {
        // TODO: implement this
    }
    
    func getLastDayRecords(facilityId: String, successHandler: (records: [CensusRecord]) -> (), failureHandler: (error: NSError) -> ()) {
        var records = [self.record]
        successHandler(records: records)
        
    }
    
    func getInstanceTargetByStaffTypeReport(month: String?, successHandler: (instanceTargetItems: [InstanceTargetItem]) -> (), failureHandler: (error: NSError) -> ()) {
        successHandler(instanceTargetItems: [])
    }
    
    func getPersonHoursReport(month: String?, successHandler: (unitHoursItems: [UnitHoursItem]) -> (), failureHandler: (error: NSError) -> ()) {
        successHandler(unitHoursItems: [])
    }
    
    var worksheet: Worksheet {
        var worksheet = Worksheet(facilityId: "replace-this", recordDateString: self.record.recordDateString, recordTime: self.record.recordTime, records: [self.record], changes: [self.staffChange], floatPool: [])
        return worksheet
        
    }
    
    var staffChange: StaffChange {
        var change = StaffChange(changeType: .Move, staffTypeName: "", count: 1, fromUnit:Unit(), toUnit:Unit())
        return change
    }
    var record: CensusRecord {
        var record:CensusRecord
        var unit = Unit(objectId: "123", name: "Intensive Care",
            floor:5, maxCensus:19,shiftTimes: [NSTimeInterval(25200), NSTimeInterval(39600), NSTimeInterval(54000), NSTimeInterval(68400), NSTimeInterval(82800)],
            varianceReasons: ["Fake reason", "Other"])
        let currentDate = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        record = CensusRecord(objectId: "", status: RecordStatus.Confirmed, gridItems: self.gridItems, unit: unit, recordDateString: dateFormatter.stringFromDate(currentDate),recordTime: NSTimeInterval(25200), census: 21, previousCensus: 20, reason: "why not?", comments: nil)
        return record;
    }
    
    var gridItems: [GridItem] {
        let testGrid = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        var grids = [GridItem(objectId: "131181", staffTypeName: "CNA", index: 0, staffGrid: testGrid, required: true, visible:true, availableStaff: 6, requestedStaff: 6, changes: [self.staffChange])]
        let testGridRN = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,6]
        grids.append(GridItem(objectId: "131182", staffTypeName: "RN/LPN", index: 1, staffGrid: testGridRN, required: true, visible: true, availableStaff: 7, requestedStaff: 6, changes: [self.staffChange]))
        let testGridCN = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131183", staffTypeName: "Charge Nurse", index: 2, staffGrid: testGridCN, required: true, visible: true, availableStaff: 1, requestedStaff: 1, changes: [self.staffChange]))
        let testGridUC = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131184", staffTypeName: "Unit Clerk", index: 3, staffGrid: testGridUC, required: false, visible: true, availableStaff: 3, requestedStaff: 2.5, changes: [self.staffChange]))
        let testGridNA = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131183", staffTypeName: "Nurse Assistant", index: 4, staffGrid: testGridNA, required: true, visible: false, availableStaff: 4, requestedStaff: 4, changes: [self.staffChange]))
        return grids
    }

}
