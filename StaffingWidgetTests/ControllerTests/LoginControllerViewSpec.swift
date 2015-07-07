import Quick
import Nimble

class LoginControllerViewSpec: QuickSpec {
    override func spec() {
        describe("a LoginControllerViewSpec") {
            var loginVc: LoginViewController!
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
            loginVc = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
            
            loginVc.loadView()
            loginVc.viewDidLoad()
            context("when loaded from nib") {
                it("the view should not be nil") {
                    expect(loginVc.view).toNot(beNil())
                }
                it("the control outlets should not be nil after the view has been loaded") {
                    expect(loginVc.errorLabel).toNot(beNil())
                    expect(loginVc.usernameField).toNot(beNil())
                    expect(loginVc.passwordField).toNot(beNil())
                }
                
            }
        }

    }
}
