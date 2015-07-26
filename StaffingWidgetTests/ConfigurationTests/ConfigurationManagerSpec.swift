import Quick
import Nimble

class ConfigurationManagerSpec: QuickSpec {
    
    //these will break if defaults-release.json is changed, test run in non-debug
    override func spec() {
        describe("the Configuration Manager") {
            var configManager:ConfigurationManager = ConfigurationManager()
            configManager.configurationClient = ConfigurationTestFileClient()
        }
     }
}
