import Quick
import Nimble

class AddStaffCellSpec: QuickSpec {
    override func spec() {
        describe("an AddStaffCell") {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
            var censusVc = storyboard.instantiateViewControllerWithIdentifier("census") as! CensusViewController
            censusVc.loadView()
            var recordClient:CensusClient = RecordClientTestImplementation()
            
            var testRecord:CensusRecord!
            
            recordClient.getRecord("test", successHandler: {
                (record) -> () in
                testRecord = record
                }, failureHandler: {
                    (error) -> () in
            })
            var cell: AddStaffCell = censusVc.staffingTableView.dequeueReusableCellWithIdentifier("AddStaffCell") as! AddStaffCell
           
            context("when loaded from nib") {
                it("should have a valid outlet") {
                    expect(cell.typeDropdown).toNot(beNil())
                }
            }
            context("when configured") {
                it("should have a populated list of non-visible items") {
                    cell.configureForStaffTypes(testRecord.gridItems.filter({ $0.visible == false }).map {
                        gridItem in gridItem.staffTypeName
                        })
                    expect(cell.typeDropdown.items.count) == testRecord.gridItems.filter({ $0.visible == false }).count
                }
            }
        }
    }
}
