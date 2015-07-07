import Quick
import Nimble
import StaffingWidget

class FacilitySpec: QuickSpec {
    override func spec() {
        describe("a facility"){
            let units = [Unit(
                objectId:"test",
                name:"Intensive Care",
                floor:5,
                maxCensus:0,
                shiftTimes: [NSTimeInterval(21600),NSTimeInterval(36000),NSTimeInterval(50400)],
                varianceReasons: ["Fake reason", "Other"])]
            let hospital = Facility(name: "One Medical",units:units)
            it("has a name"){
                expect(hospital.name).notTo(beEmpty())
            }
            it("should have 1 or more units"){
                expect(hospital.units).notTo(beEmpty())
                expect(hospital.units.count).to(beGreaterThan(0))
            }
        }
        
    }
}
