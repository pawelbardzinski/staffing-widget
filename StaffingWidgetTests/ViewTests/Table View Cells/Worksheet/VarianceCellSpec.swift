import Quick
import Nimble

class VarianceCellSpec: QuickSpec {
    override func spec() {
        describe("a Variance Cell") {
            var cell: VarianceCell!
            beforeEach() {
            var recordVc: WorksheetViewController!
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
            recordVc = storyboard.instantiateViewControllerWithIdentifier("WorksheetViewController") as! WorksheetViewController
            recordVc.loadView()
            recordVc.viewDidLoad()
            cell = recordVc.tableView.dequeueReusableCellWithIdentifier("VarianceCell") as! VarianceCell
            }
            //make sure everything is wired
            context("when loaded") {
                it("should have valid outlets") {
                    expect(cell.typeNameLabel).toNot(beNil())
                    expect(cell.recommendedLabel).toNot(beNil())
                    expect(cell.availableLabel).toNot(beNil())
                    expect(cell.requestedLabel).toNot(beNil())
                    expect(cell.varianceLabel).toNot(beNil())
                    expect(cell.draggableIconImageView).toNot(beNil())
                }
            }
            context("when configured") {
                let recordClient = RecordClientTestImplementation()
                var record = recordClient.record
                var gridItem = recordClient.gridItems[0]
                
                it("should accept a drag gesture event if the record is not already locked") {
                    //make sure record is editable
                    record.status = RecordStatus.Adjusted
                    record.recordTime = RecordTimestamp.now().time
                    cell.configure(record, gridItem: gridItem, collapsed: true)
                    expect(cell.canDragToCell()).to(beTrue())
                }
                it("should not accept a drag to gesture when the record is locked") {
                    //make sure record is locked
                    record.status = RecordStatus.Confirmed
                    cell.configure(record, gridItem: gridItem, collapsed: true)
                    expect(cell.canDragToCell()).toNot(beTrue())
                }
                it("should allow a drag from gesture when the record is not locked and actual staff is greater than 0") {
                    //make sure record is editable
                    record.status = RecordStatus.Adjusted
                    record.recordTime = RecordTimestamp.now().time
                    gridItem.availableStaff = 2.0
                    gridItem.changes = []
                    cell.configure(record, gridItem: gridItem, collapsed: true)
                    expect(cell.canDragFromCell).to(beTrue())
                }
                it("should not allow a drag from gesture when the actual staff is 0 or less") {
                    
                    record.status = RecordStatus.Adjusted
                    record.recordTime = RecordTimestamp.now().time
                    //this sets up the available staff to be 0
                    gridItem.availableStaff = 0.0
                    gridItem.changes = []
                    cell.configure(record, gridItem: gridItem, collapsed: true)
                    expect(cell.canDragFromCell).toNot(beTrue())
                }
                it("should not accept a drag from gesture when the record is locked") {
                    //make sure record is locked
                    record.status = RecordStatus.Confirmed
                    gridItem.availableStaff = 2.0
                    gridItem.changes = []
                    cell.configure(record, gridItem: gridItem, collapsed: true)
                    expect(cell.canDragFromCell).toNot(beTrue())
                }
                it("should have a recommended label") {
                    cell.configure(record, gridItem: gridItem, collapsed: false)
                    expect(cell.recommendedLabel.text) == "5"
                }
                it("should have an available label") {
                    cell.configure(record, gridItem: gridItem, collapsed: false)
                    expect(cell.availableLabel.text) == "2"
                }

                it("should have a requested label") {
                    cell.configure(record, gridItem: gridItem, collapsed: false)
                    expect(cell.requestedLabel.text) == "6"
                }

                it("should display a variance label with the background color determined by the resource variance") {
                    gridItem.availableStaff = 6
                    cell.configure(record, gridItem: gridItem, collapsed: false)
                    expect(cell.varianceLabel.text) == "0"
                    expect(
                        CGColorEqualToColor(cell.varianceLabel.layer.backgroundColor, StaffingColors.NoVariance.color().CGColor))
                    gridItem.availableStaff = 10
                    cell.configure(record, gridItem: gridItem, collapsed: false)
                    expect(cell.varianceLabel.text) == "+4"
                    expect(
                        CGColorEqualToColor(cell.varianceLabel.layer.backgroundColor, StaffingColors.PostiveVariance.color().CGColor))
                    gridItem.availableStaff = 4
                    cell.configure(record, gridItem: gridItem, collapsed: false)
                    expect(cell.varianceLabel.text) == "-2"
                    expect(
                        CGColorEqualToColor(cell.varianceLabel.layer.backgroundColor, StaffingColors.NegativeVariance.color().CGColor))
                }
                context("when the variance cell is collapsed") {
                    it("should display type name label that includes the time, unit and staff type") {
                        record.recordTime = NSTimeInterval(25200)
                        cell.configure(record, gridItem: gridItem, collapsed: true)
                        expect(cell.typeNameLabel.text) == "7 AM - \(record.unit.name) - \(gridItem.staffTypeName)"
                    }
                }
                context("when the variance cell is not collapsed") {
                    it("should display staff type name as the type name label") {
                        cell.configure(record, gridItem: gridItem, collapsed: false)
                        expect(cell.typeNameLabel.text) == gridItem.staffTypeName
                    }
                }
            }
        }
    }
}
