import Quick
import Nimble

class CensusListCellSpec: QuickSpec {
    override func spec() {
        describe("a CensusListCell") {
            //TODO: enable with ticket #122 and #125
//            var censusVc: CensusViewController!
//            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
//            censusVc = storyboard.instantiateViewControllerWithIdentifier("census") as! CensusViewController
//            censusVc.recordClient = RecordClientTestImplementation()
//            censusVc.loadView()
//            censusVc.viewDidLoad()
//            let cell: CensusListCell = censusVc.censusListTVC.tableView.dequeueReusableCellWithIdentifier("CensusListCell") as! CensusListCell
//            
//            context("when loaded from nib") {
//                it("should have valid outlets") {
//                    expect(cell.statusView).toNot(beNil())
//                    expect(cell.titleLabel).toNot(beNil())
//                }
//            }
//            context("after the cell as been configured with a record") {
//                var record: Record = RecordClientTestImplementation().record
//                cell.configureWithRecord(record)
//                it("it should have a formatted title label based on the record") {
//                    record.recordTime = NSTimeInterval(25200)
//                    expect(cell.titleLabel) == "7 AM - ICU"
//                }
//                it("should have background color"){
//                    expect(cell.statusView.backgroundColor).toNot(beNil())
//                }
//                it("the background color should be the same as LateUnconfirmed when the record is unconfirmed") {
//                    expect(cell.statusView.backgroundColor) == StaffingColors.LateUnconfirmedRecord.color()
//                }
//                it("the background color should be the same as CompleteRecord when the record is confirmed") {
//                    expect(cell.statusView.backgroundColor) == StaffingColors.CompleteRecord.color()
//                }
//                it("the background color should be the same as UpcomingRecord when the record is for today and before the record time") {
//                    expect(cell.statusView.backgroundColor) == StaffingColors.UpcomingRecord.color()
//                }
//                it("the background color should be the same as LateUnfilledRecord when the record is late") {
//                    record.objectId = nil
//                    expect(cell.statusView.backgroundColor) == StaffingColors.LateUnfilledRecord.color()
//                }
//            }
        }
    }
}
