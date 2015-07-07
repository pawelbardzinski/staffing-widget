import Quick
import Nimble

class ConfigurationManagerSpec: QuickSpec {
    
    //these will break if defaults-release.json is changed, test run in non-debug
    override func spec() {
        describe("the Configuration Manager") {
            var configManager:ConfigurationManager = ConfigurationManager()
            configManager.configurationClient = ConfigurationTestFileClient()

            it("will have one or more units") {
                configManager.getUnitsForFacility("1", successHandler: {
                    (units) -> () in
                    expect(units).notTo(beEmpty())
                    expect(units.count) == 2
                    let unitZero = units[0]
                    expect(unitZero.objectId).notTo(beEmpty())
                    expect(unitZero.name).to(equal("Pediatrics"))
                    expect(unitZero.floor).to(equal(5))
                    expect(unitZero.shiftTimes.count)==5
                    expect(unitZero.maxCensus)==26
                }, failureHandler: {
                    (error) -> () in
                    expect(error).to(beNil())
                })
            }
        }
     }
}
