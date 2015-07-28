import Quick
import Nimble

class RecordSpec: QuickSpec {
    override func spec() {
        describe("a record") {
            
            var record:CensusRecord?
            var unit = Unit(objectId: "123", name:"Intensive Care",
                floor:5, maxCensus:19,shiftTimes: [NSTimeInterval(25200),NSTimeInterval(39600),NSTimeInterval(54000),NSTimeInterval(68400),NSTimeInterval(82800)],
                varianceReasons: ["Fake reason", "Other"])
            beforeEach() {
                let currentDate = NSDate()
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                record = CensusRecord(objectId:"", status: .New, gridItems:self.gridItems, unit:unit, recordDateString:dateFormatter.stringFromDate(currentDate),recordTime:NSTimeInterval(25200), census:21, previousCensus:20, reason:"why not?", comments:nil)
            }
            context("when retrieving the next record time") {
                it("should return the next shift time to record based on the current record time") {
                    record?.recordTime = NSTimeInterval(39600) //be explicit
                    expect(record?.nextRecordTime) == NSTimeInterval(54000)
                }
                it("should return the first shift time if the record time is outside all record times") {
                    record?.recordTime = NSTimeInterval(84600)
                    expect(record?.nextRecordTime) == NSTimeInterval(25200)
                    record?.recordTime = NSTimeInterval(0)
                    expect(record?.nextRecordTime) == NSTimeInterval(25200)
                }
            }
            it("should have 1 or more grid items that are visible and required") {
                expect(record?.gridItems).notTo(beNil())
                expect(record?.gridItems.count) == 6
                expect(record?.visibleGridItems.count) == 5
            }
            it("should return a max census value from grid items") {
                expect(record?.maxCensus) == 22
            }
            context("when getting the grid WHPPD") {
                it("should return an accurate whppd") {
                    expect(round(10*record!.gridWHPPD)/10) == 28.6
                }
            }
            context("when getting the actual WHPPD") {
                it("should return an accuarate actual whppd") {
                    expect(round(10*record!.availableWHPPD)/10) == 24.0
                }
            }
        }
    }
    
    var gridItems: [GridItem] {
        let testGrid = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        var grids = [GridItem(objectId: "131181", staffTypeName:"CNA", index: 0, staffGrid:testGrid, required:true, visible:true, availableStaff: 6, requestedStaff:6, changes: [])]
        let testGridRN = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,6]
        grids.append(GridItem(objectId: "131182", staffTypeName: "RN/LPN", index: 1, staffGrid: testGridRN, required: true, visible: true, availableStaff: 7, requestedStaff: 6, changes: []))
        let testGridCN = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131183", staffTypeName: "Charge Nurse", index: 2, staffGrid: testGridCN, required: true, visible: true, availableStaff: 1, requestedStaff: 1, changes: []))
        let testGridUC = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131184", staffTypeName: "Unit Clerk", index: 3, staffGrid: testGridUC, required: false, visible: true, availableStaff: 3, requestedStaff: 2.5, changes: []))
        let testGridNA = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131183", staffTypeName: "Nurse Assistant", index: 4, staffGrid: testGridNA, required: true, visible: false, availableStaff: 4, requestedStaff: 4, changes: []))
        let testGridSW = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131183", staffTypeName: "Software Support", index: 5, staffGrid: testGridSW, required: false, visible: false, availableStaff: 0, requestedStaff: 0, changes: []))
        return grids
    }
}
