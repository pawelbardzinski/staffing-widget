import Quick
import Nimble
import StaffingWidget

class FacilitySpec: QuickSpec {
    override func spec() {
        describe("a facility") {
            let hospital = Facility(name: "One Medical", shiftTimes: [NSTimeInterval(21600),NSTimeInterval(36000),NSTimeInterval(50400)])

            it("has a name"){
                expect(hospital.name).notTo(beEmpty())
            }
            it("should have 1 or more shift times"){
                expect(hospital.shiftTimes).notTo(beEmpty())
                expect(hospital.shiftTimes.count).to(beGreaterThan(0))
            }
        }
        
    }
}
