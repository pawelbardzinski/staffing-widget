import Quick
import Nimble

class LoginValidatorSpec: QuickSpec {
    override func spec() {
        describe("the login validator") {
            let validator = LoginValidator()
            it("will validate that an email address is valid") {
                expect(LoginValidator.isValidEmailAddress("testme@this.net")).to(beTruthy())
                expect(LoginValidator.isValidEmailAddress("testmet")).toNot(beTruthy())
            }
            it("will validate that a password is valid"){
                expect(LoginValidator.isValidPassword(nil)).toNot(beTruthy())
                expect(LoginValidator.isValidPassword("")).toNot(beTruthy())
                expect(LoginValidator.isValidPassword(" test")).toNot(beTruthy())
                expect(LoginValidator.isValidPassword("test ")).toNot(beTruthy())
                expect(LoginValidator.isValidPassword("my sample password")).toNot(beTruthy())
                expect(LoginValidator.isValidPassword("myFavor!teP@ssw0rd")).to(beTruthy())
            }
        }
    }
}
