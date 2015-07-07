import Quick
import Nimble

class AddStaffCellSpec: QuickSpec {
    override func spec() {
        describe("an AddStaffCell") {
            var censusVc: CensusViewController!
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
            censusVc = storyboard.instantiateViewControllerWithIdentifier("census") as! CensusViewController
            censusVc.loadView()
            
            let cell: AddStaffCell = censusVc.staffingTableView.dequeueReusableCellWithIdentifier("AddStaffCell") as! AddStaffCell
            
            context("when loaded from nib") {
                it("should have a valid outlet") {
                    expect(cell.typeDropdown).toNot(beNil())
                }
            }
        }
    }
}
