import Quick
import Nimble
import UIKit

class StepControlSpec: QuickSpec {
    override func spec() {
        describe("a StepControl") {
            // Would prefer to load directly from the NIB, but it results in an exec_bad_access
            var censusVc: CensusViewController!
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
            censusVc = storyboard.instantiateViewControllerWithIdentifier("census") as! CensusViewController
            censusVc.loadView()
            
            var stepControl = censusVc.censusControl
            // let nib = UINib(nibName: "StepControl", bundle: NSBundle(forClass: self.dynamicType))
            // var a = nib.instantiateWithOwner(nil, options: nil)
            context("when loaded from nib") {
                it("should have a valid view") {
                    expect(stepControl.view).toNot(beNil())
                }
                it("should have valid outlets") {
                    expect(stepControl.valueField).toNot(beNil())
                    expect(stepControl.minusButton).toNot(beNil())
                    expect(stepControl.plusButton).toNot(beNil())
                }
            }
            context("after the view has been loaded") {
                it("should be able to increment the census by tapping on it") {
                    stepControl.value = 0
                    stepControl.plusButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    expect(stepControl.value) == 1
                    stepControl.plusButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    expect(stepControl.value) == 2
                }
                it("should not be able to increment the census beyond the maximum value"){
                    stepControl.maximumValue = 50
                    for var index = 0.0; index <= stepControl.maximumValue; index++ {
                        stepControl.plusButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    }
                    expect(stepControl.value) == stepControl.maximumValue
                }
                it("should be able to increment the census with a decimal value") {
                    stepControl.value = 22
                    stepControl.stepper.incrementStepValue = 0.5
                    stepControl.plusButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    expect(stepControl.value) == 22.5
                }
                it("should be able to decrement the census by tapping on it") {
                    stepControl.value = 4
                    stepControl.minusButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    expect(stepControl.value) == 3
                    stepControl.minusButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    expect(stepControl.value) == 2
                }
                it("should be able to decrement the census with a decimal value") {
                    stepControl.value = 33
                    stepControl.stepper.decrementStepValue = 0.5
                    stepControl.minusButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    expect(stepControl.value) == 32.5
                }
                it("should not be able to decrement the census below the minumum value") {
                    expect(stepControl.minimumValue) == 0
                    stepControl.value = 0
                    stepControl.minusButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                    expect(stepControl.value) == 0
                }
                
            }

        }
    }
}