import Quick
import Nimble
import StaffingWidget

class UnitSpec: QuickSpec {
    override func spec() {
        describe("a unit") {
            let unit = Unit(
                objectId:"test",
                name:"ICU",
                floor:5,
                maxCensus:24,
                shiftTimes: [25200,39600,54000,68400,82800],
                varianceReasons: ["Fake reason", "Other"])
            it("has a name") {
                expect(unit.name).notTo(beEmpty())
            }
            it("will have a floor") {
                expect(unit.floor).to(beGreaterThan(0))
            }
            it("will have 1 or more record times"){
                expect(unit.shiftTimes).notTo(beEmpty())
                expect(unit.shiftTimes.count).to(beGreaterThan(1))
            }
            
        }
    }
}
