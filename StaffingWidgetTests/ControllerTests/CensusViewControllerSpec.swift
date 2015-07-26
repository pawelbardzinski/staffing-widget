import Quick
import Nimble

class CensusViewControllerSpec: QuickSpec {
    override func spec() {
        describe("a CensusViewControllerSpec") {
            var censusVc: CensusViewController!
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
            censusVc = storyboard.instantiateViewControllerWithIdentifier("census") as! CensusViewController
            censusVc.censusClient = RecordClientTestImplementation()
            censusVc.loadView()
//          TODO: Ticket #122 censusVc.viewDidLoad()
            context("when loaded from nib") {
                it("the view should not be nil") {
                    expect(censusVc.view).toNot(beNil())
                }
                it("the container outlets should not be nil after the view has been loaded") {
                    expect(censusVc.scrollView).toNot(beNil())
                    expect(censusVc.buttonContainer).toNot(beNil())
                    expect(censusVc.confirmContainer).toNot(beNil())
                    expect(censusVc.finalizeView).toNot(beNil())
                }
                it("the control outlets should not be nil after the view has been loaded") {
                    expect(censusVc.censusControl).toNot(beNil())
                    expect(censusVc.previousCensusLabel).toNot(beNil())
                    expect(censusVc.staffingTableView).toNot(beNil())
                    expect(censusVc.varianceReasonDropdown).toNot(beNil())
                    expect(censusVc.varianceCommentsTextView).toNot(beNil())
                    expect(censusVc.confirmButton).toNot(beNil())
                    expect(censusVc.cancelButton).toNot(beNil())
                }
                it("the constraint outlets should not be nil after the view has been loaded") {
                    expect(censusVc.staffingGridHeightConstraint).toNot(beNil())
                    expect(censusVc.confirmContainerHeight).toNot(beNil())
                    expect(censusVc.tableViewHeight).toNot(beNil())
                    expect(censusVc.scrollViewBottom).toNot(beNil())
                }
            }
        }
    }
}
