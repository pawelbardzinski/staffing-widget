import Quick
import Nimble

class GridItemSpec: QuickSpec {
    override func spec() {
        describe("a grid item") {
            var gridItem: GridItem?
            let testGrid =  [1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6]
            beforeEach() {
                gridItem = GridItem(objectId: "131181", staffTypeName:"CNA", index: 3, staffGrid:testGrid, required:true, visible:true, availableStaff: 6, requestedStaff:6, changes: [])
            }
            it("should have a max census that is 1 less than the number of grid entries") {
                expect(gridItem?.maxCensus) == testGrid.count-1
                gridItem?.staffGrid = [] //just in case the api has an issue
                expect(gridItem?.maxCensus) == 0
            }
            it("should have a resource that is the difference between the available and requested staff"){
                expect(gridItem?.resourceVariance == 0)
                gridItem?.availableStaff = 10
                expect(gridItem?.resourceVariance == 4)
            }
            context("when determining the grid staff for census") {
                it("should return nil if the census is out of range of the grid items") {
                    expect(gridItem?.recommendedStaffForCensus(-1)).to(beNil())
                    expect(gridItem?.recommendedStaffForCensus(30)).to(beNil())
                }
                it("should return the grid staff value based on the census") {
                    expect(gridItem?.recommendedStaffForCensus(2)) == 1
                    expect(gridItem?.recommendedStaffForCensus(testGrid.endIndex-1)) == 6
                }
            }
            context("when determining the staff variance") {
                it("should return nil if the census is out of range of he grid items") {
                    expect(gridItem?.staffVarianceForCensus(testGrid.count)).to(beNil())
                    expect(gridItem?.staffVarianceForCensus(-1)).to(beNil())
                }
                it("should return a variance based on the census") {
                    gridItem?.availableStaff = 6
                    expect(gridItem?.staffVarianceForCensus(10)) == 2
                    gridItem?.availableStaff = 0
                    expect(gridItem?.staffVarianceForCensus(8)) == -3
                }
            }
            context("when testing equality") {
                it("should equal another grid item only when the object id and and name are the same") {
                    var testItem = GridItem(objectId: "131181", staffTypeName:"CNA", index: 0, staffGrid:testGrid, required:true, visible:true, availableStaff: 6, requestedStaff:6, changes: [])
                    var testItem2 = GridItem(objectId: "131181", staffTypeName:"CNA", index: 0, staffGrid:testGrid, required:true, visible:true, availableStaff: 6, requestedStaff:6, changes: [])
                    
                    expect(testItem) == testItem2
                    testItem.objectId = nil;
                    testItem2.objectId = nil;
                    expect(testItem) == testItem2
                }
                it("should not equal another grid item if the object id and name are not the same") {
                    
                    var testItem = GridItem(objectId: "131181", staffTypeName:"CNA", index: 0, staffGrid:testGrid, required:true, visible:true, availableStaff: 6, requestedStaff:6, changes: [])
                    var testItem2 = GridItem(objectId: "131181", staffTypeName:"RN", index: 0, staffGrid:testGrid, required:true, visible:true, availableStaff: 6, requestedStaff:6, changes: [])
                    
                    expect(testItem) != testItem2
                    testItem2.staffTypeName = testItem.staffTypeName
                    testItem2.objectId = "23"
                    expect(testItem) != testItem2
                }
            }
            context("when a json representation is needed") {
                it("should have a valid json export") {
                    expect(gridItem?.jsonForCensus(8)).notTo(beNil())
                    if let jsonData = gridItem?.jsonForCensus(8) {
                        expect(jsonData.count) == 11
                        expect(jsonData["staffTypeName"] as? String) == "CNA"
                        expect(jsonData["index"] as? Int) == 3
                        expect(jsonData["grid"] as? [Int]) == testGrid
                        expect(jsonData["required"] as? Bool) == true
                        expect(jsonData["visible"] as? Bool) == true
                        expect(jsonData["availableStaff"] as? Int) == 6
                        expect(jsonData["requestedStaff"] as? Int) == 6
                        expect(jsonData["staffVariance"] as? Int) == 3
                        expect(jsonData["recommendedStaff"] as? Int) == 3
                        expect(jsonData["resourceVariance"] as? Int) == 0
                    }
                }
                it("should have a valid changes for census export") {
                    expect(gridItem?.jsonChangesForCensus(0)).notTo(beNil())
                    if let jsonData = gridItem?.jsonChangesForCensus(3) {
                        expect(jsonData["visible"] as? Bool) == true
                        expect(jsonData["availableStaff"] as? Int) == 6
                        expect(jsonData["requestedStaff"] as? Int) == 6
                        expect(jsonData["recommendedStaff"] as? Int) == 2
                        expect(jsonData["staffVariance"] as? Int) == 4
                    }
                }
            }
        }
      
    }
}
