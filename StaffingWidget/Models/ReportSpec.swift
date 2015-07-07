import Quick
import Nimble

class ReportSpec: QuickSpec {
    override func spec() {
        describe("a report") {
            
            var report:Report?
            var unit = Unit(objectId: "123", name:"Intensive Care",
                floor:5, maxCensus:19,shiftTimes: [NSTimeInterval(25200),NSTimeInterval(39600),NSTimeInterval(54000),NSTimeInterval(68400),NSTimeInterval(82800)],
                varianceReasons: ["Fake reason", "Other"])
            beforeEach() {
                let currentDate = NSDate()
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                report = Report(objectId:"", gridItems:self.gridItems, unit:unit, reportingDateString:dateFormatter.stringFromDate(currentDate),reportingTime:NSTimeInterval(25200), census:21, previousCensus:20, confirmed:false, reason:"why not?", comments:nil)
            }
            context("when retrieving the next reporting time") {
                it("should return the next shift time to report based on the current reporting time") {
                    report?.reportingTime = NSTimeInterval(39600) //be explicit
                    expect(report?.nextReportingTime) == NSTimeInterval(54000)
                }
                it("should return the first shift time if the reporting time is outside all reporting times") {
                    report?.reportingTime = NSTimeInterval(84600)
                    expect(report?.nextReportingTime) == NSTimeInterval(25200)
                    report?.reportingTime = NSTimeInterval(0)
                    expect(report?.nextReportingTime) == NSTimeInterval(25200)
                }
            }
            it("should have 1 or more grid items that are visible and required") {
                expect(report?.gridItems).notTo(beNil())
                expect(report?.gridItems.count) == 6
                expect(report?.visibleGridItems.count) == 5
            }
            it("should return a max census value from grid items") {
                expect(report?.maxCensus) == 22
            }
            context("when getting the grid WHPPD") {
                it("should return an accurate whppd") {
                    expect(round(10*report!.gridWHPPD)/10) == 28.6
                }
            }
            context("when getting the actual WHPPD") {
                it("should return an accuarate actual whppd") {
                    expect(round(10*report!.actualWHPPD)/10) == 22.3
                }
            }
        }
    }
    
    var gridItems: [GridItem] {
        let testGrid = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        var grids = [GridItem(objectId: "131181", staffTypeName:"CNA", index: 0, staffGrid:testGrid, required:true, visible:true, availableStaff: 6, actualStaff:6)]
        let testGridRN = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,6]
        grids.append(GridItem(objectId: "131182", staffTypeName: "RN/LPN", index: 1, staffGrid: testGridRN, required: true, visible: true, availableStaff: 7, actualStaff: 6))
        let testGridCN = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131183", staffTypeName: "Charge Nurse", index: 2, staffGrid: testGridCN, required: true, visible: true, availableStaff: 1, actualStaff: 1))
        let testGridUC = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131184", staffTypeName: "Unit Clerk", index: 3, staffGrid: testGridUC, required: false, visible: true, availableStaff: 3, actualStaff: 2.5))
        let testGridNA = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131183", staffTypeName: "Nurse Assistant", index: 4, staffGrid: testGridNA, required: true, visible: false, availableStaff: 4, actualStaff: 4))
        let testGridSW = [1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5]
        grids.append(GridItem(objectId: "131183", staffTypeName: "Software Support", index: 5, staffGrid: testGridSW, required: false, visible: false, availableStaff: 0, actualStaff: 0))
        return grids
    }
}