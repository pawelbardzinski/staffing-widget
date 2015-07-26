import Quick
import Nimble

class StaffingUtilsSpec: QuickSpec {
    override func spec() {
        describe("the StaffingUtils") {
            it("should return an hour as an NSTimeInterval") {
                var expectedTime = NSTimeInterval(12 * 3600)
                expect(StaffingUtils.hour(12)).to(equal(expectedTime))
                expectedTime = NSTimeInterval(23 * 3600)
                expect(StaffingUtils.hour(23)).to(equal(expectedTime))
            }
            it("should add a meridiem suffix to the hour") {
                expect(StaffingUtils.formattedRecordTime(NSTimeInterval(13 * 3600))).to(equal("1 PM"))
                expect(StaffingUtils.formattedRecordTime(NSTimeInterval(8 * 3600))).to(equal("8 AM"))
                expect(StaffingUtils.formattedRecordTime(NSTimeInterval(22 * 3600))).to(equal("10 PM"))
            }
            it("should return the current hour and minute as an NSTimeInterval") {
                let components = NSCalendar.currentCalendar().components(.CalendarUnitHour | .CalendarUnitMinute, fromDate: NSDate())

                let expectedHour = NSTimeInterval(components.hour * 60 * 60 + components.minute * 60);
                expect(StaffingUtils.currentHour()).to(equal(expectedHour))
            }
            it("can add a + prefix to the staffing number") {
                var expectedResult = "+23.1"
                expect(StaffingUtils.formatStaffing(23.1, includePlusSymbol: true)).to(equal(expectedResult))
                expectedResult = "+18"
                expect(StaffingUtils.formatStaffing(18, includePlusSymbol: true)).to(equal(expectedResult))
            }
            it("can format and not add a + prefix to the staffing number") {
                var expectedResult = "23.1"
                expect(StaffingUtils.formatStaffing(23.1)).to(equal(expectedResult))
                expectedResult = "18"
                expect(StaffingUtils.formatStaffing(18.0)).to(equal(expectedResult))
            }
        }
    }
}
