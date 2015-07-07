import Quick
import Nimble

class WHPPDCellSpec: QuickSpec {
    override func spec() {
        describe("a WHPPDCell") {
            var censusVc: CensusViewController!
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
            censusVc = storyboard.instantiateViewControllerWithIdentifier("census") as! CensusViewController
            censusVc.loadView()
            
            let cell: WHPPDCell = censusVc.staffingTableView.dequeueReusableCellWithIdentifier("WHPPDCell") as! WHPPDCell
            
            context("when loaded from nib") {
                it("should have valid outlets") {
                    expect(cell.gridValueLabel).toNot(beNil())
                    expect(cell.actualStaffLabel).toNot(beNil())
                }
            }
            context("after the view has been loaded") {
                it("configure should format the gridValueLabel correctly") {
                    cell.configure(22.32, actualWHPPD: 22.0)
                    expect(cell.gridValueLabel.text) == "22.3"
                    cell.configure(22.7901, actualWHPPD: 22.0)
                    expect(cell.gridValueLabel.text) == "22.8"
                }
            }
        }
    }
}
