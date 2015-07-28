//
//  StepControl.swift
//  KWStepperDemo
//
//  Created by Seth Hein on 5/12/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

enum StepControlSize {
    case Small, Large
}

class StepControl: UIControl, KWStepperDelegate, UITextFieldDelegate {
    
    var stepper: KWStepper!
    
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet var view: UIView!
    @IBOutlet weak var plusButton: UIButton!
    
    var value: Double! {
        set {
            stepper.value = newValue
        }
        
        get {
            return stepper.value
        }
    }
    
    var minimumValue: Double!
        {
        set {
            stepper?.minimumValue = newValue
        }
        get {
            return stepper?.minimumValue
        }
    }
    
    var maximumValue: Double!
        {
        set {
            stepper?.maximumValue = newValue
        }
        get {
            return stepper?.maximumValue
        }
    }
    var initialValue: Double!
        {
        set {
            stepper?.value = newValue
        }
        get {
            return self.minimumValue
        }
    }
    
    override var tintColor: UIColor!
        {
        set {
            valueField.textColor = newValue
            self.minusButton.tintColor = newValue
            self.plusButton.tintColor = newValue
        }
        get {
            return self.tintColor
        }
    }
    
    var size: StepControlSize = .Large {
        didSet {
            switch size {
            case .Small:
                valueField.font = UIFont.systemFontOfSize(17)
                valueField.adjustsFontSizeToFitWidth = false
                break
            case .Large:
                valueField.font = UIFont.systemFontOfSize(28)
                valueField.adjustsFontSizeToFitWidth = true
                break
            }
        }
    }
    
    var editable: Bool = true {
        didSet {
            plusButton.hidden = !self.editable
            minusButton.hidden = !self.editable
            valueField.enabled = editable
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSBundle.mainBundle().loadNibNamed("StepControl", owner: self, options: nil)
        self.view.frame = self.bounds
        self.addSubview(self.view)
        
        valueField.addTarget(self, action:"textValueChanged:", forControlEvents:UIControlEvents.EditingChanged);
        valueField.delegate = self
        valueField.textColor = UIColor.whiteColor()
        valueField.keyboardType = UIKeyboardType.NumberPad
        
        valueField.contentVerticalAlignment = UIControlContentVerticalAlignment.Center;
        valueField.textAlignment = NSTextAlignment.Center;
        
        minusButton.setImage(minusButton.imageView?.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: UIControlState.Normal)
        minusButton.setImage(minusButton.imageView?.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal), forState: UIControlState.Highlighted)
        
        plusButton.setImage(plusButton.imageView?.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: UIControlState.Normal)
        plusButton.setImage(plusButton.imageView?.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal), forState: UIControlState.Highlighted)
        
        configureStepper()
    }
    
    override init (frame : CGRect) {
        super.init(frame : frame)
    }
    
    /**
    Executed when the value is changed.
    */
    var valueChangedCallback: (() -> ())?
    
    @IBAction func valueFieldEditingDidBegin(sender: AnyObject) {
        
        let rootView : UIView? = UIApplication.sharedApplication().keyWindow?.rootViewController?.view
        let viewRect : CGRect? = rootView?.bounds
        
        valueField.text = ""
    }
    
    func configureStepper() {
        stepper = KWStepper(
            decrementButton: minusButton,
            incrementButton: plusButton)
        
        plusButton.addTarget(self, action: Selector("valueChanged"), forControlEvents: UIControlEvents.TouchUpInside);
        minusButton.addTarget(self, action: Selector("valueChanged"), forControlEvents: UIControlEvents.TouchUpInside);
        
        stepper.autoRepeat = true
        stepper.autoRepeatInterval = 0.10
        stepper.wraps = false
        
        updateFieldValue()
        stepper.incrementStepValue = 1
        stepper.decrementStepValue = 1
        
        stepper.delegate = self
        
        stepper.valueChangedCallback = {
            [weak self] in
            
            // update the field
            self?.updateFieldValue()
        }
        
        stepper.decrementCallback = {
            [weak self] in
            
            //println("decrementCallback: The stepper did decrement")
        }
        
        stepper.incrementCallback = {
            [weak self] in
            
            //println("incrementCallback: The stepper did increment")
        }
    }
    
    func valueChanged() {
        self.valueChangedCallback?()
    }
    
    func updateFieldValue()
    {
        if ((valueField.text as NSString).doubleValue != stepper.value)
        {
            self.valueField.text = StaffingUtils.formatStaffing(stepper.value)
        }
    }

    func textValueChanged(sender: AnyObject) {
        stepper.value = (valueField.text as NSString).doubleValue
        valueChanged()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldDidEndEditing(textField: UITextField) {
        if (self.valueField.text.isEmpty)
        {
            self.valueField.text = "0"
            stepper.value = 0
            valueChanged()
        }
    }
}
