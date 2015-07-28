import Quick
import Nimble

class UnitTitleCellSpec: QuickSpec {
    override func spec() {
        describe("a UnitTitle cell") {
            var recordVc: WorksheetViewController!
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
            recordVc = storyboard.instantiateViewControllerWithIdentifier("WorksheetViewController") as! WorksheetViewController
            recordVc.loadView()
            recordVc.viewDidLoad()
            let cell: UnitTitleCell = recordVc.tableView.dequeueReusableCellWithIdentifier("TitleCell") as! UnitTitleCell
            
            context("when loaded from nib") {
                it("should have a valid outlet") {
                    expect(cell.unitNameLabel).toNot(beNil())
                }
            }
            context("after the view has been loaded") {
                it("calling configure should set the unitNameLabel with a correctly formated label") {
                    cell.configure("ICU", recordTime: NSTimeInterval(25200))
                    expect(cell.unitNameLabel.text) == "7 AM - ICU"
                    cell.configure("ACL", recordTime: NSTimeInterval(66681))
                    expect(cell.unitNameLabel.text) == "6 PM - ACL"
                }
            }
        }
    }
}
