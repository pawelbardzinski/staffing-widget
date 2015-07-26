import Quick
import Nimble
import UIKit

class StaffCellSpec: QuickSpec {
    override func spec() {
        describe("a StaffCell") {
            var censusVc: CensusViewController!
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
            censusVc = storyboard.instantiateViewControllerWithIdentifier("census") as! CensusViewController
            censusVc.loadView()

            let cell: StaffCell = censusVc.staffingTableView.dequeueReusableCellWithIdentifier("StaffCell") as! StaffCell
            
            context("when loaded from nib") {
                it("should have valid outlets") {
                    expect(cell.typeNameLabel).toNot(beNil())
                    expect(cell.gridValueLabel).toNot(beNil())
                    expect(cell.varianceLabel).toNot(beNil())
                    expect(cell.availableStaffStepper).toNot(beNil())
                    expect(cell.requestedStaffStepper).toNot(beNil())
                }
            }
        }
    }
}
