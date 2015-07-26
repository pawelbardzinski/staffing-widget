//
//  LoginViewController.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/13/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import JVFloatLabeledTextField

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    var loginClient: LoginClient!
    var configurationManager : ConfigurationManager!
    var viewPasswordButton: UIButton!
    
    var viewPassword: Bool = false {
        didSet {
            if (viewPassword) {
                viewPasswordButton.alpha = 1.0
                viewPasswordButton.tintColor = nil // Set to the default tint when selected
                passwordField.secureTextEntry = false
            } else {
                viewPasswordButton.alpha = 0.54
                viewPasswordButton.tintColor = UIColor.blackColor()
                passwordField.secureTextEntry = true
            }
        }
    }
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var usernameField: JVFloatLabeledTextField!
    @IBOutlet weak var passwordField: JVFloatLabeledTextField!
    
    @IBAction func usernameDidEndOnExit(sender: AnyObject) {
        
        passwordField.becomeFirstResponder()
        
    }
    @IBAction func passwordDidEndOnExit(sender: AnyObject) {
        
        var contentView = PKHUDProgressView()
        PKHUD.sharedHUD.contentView = contentView
        PKHUD.sharedHUD.show()
        
        loginToAPI()
    }

    
    @IBAction func usernameValueChanged(sender: AnyObject) {
        if let activeColor : UIColor? = usernameField?.floatingLabelActiveTextColor
        {
            if (activeColor == UIColor.redColor())
            {
                usernameField.floatingLabelActiveTextColor = self.view.tintColor
                usernameField.floatingLabelTextColor = UIColor.grayColor()
            }
        }
    }
    
    @IBAction func passwordValueChanged(sender: AnyObject) {
        if let activeColor : UIColor? = passwordField?.floatingLabelActiveTextColor
        {
            if (activeColor == UIColor.redColor())
            {
                passwordField.floatingLabelActiveTextColor = self.view.tintColor
                passwordField.floatingLabelTextColor = UIColor.grayColor()
            }
        }
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        let validEmail = LoginValidator.isValidEmailAddress(usernameField.text)
        let validPassword = LoginValidator.isValidPassword(passwordField.text)
        
        if (textField == usernameField && !validEmail)
        {
            // email error UI
            usernameField.floatingLabelActiveTextColor = UIColor.redColor()
            usernameField.floatingLabelTextColor = UIColor.redColor()
        } else if (textField == passwordField && !validPassword)
        {
            // password error UI
            passwordField.floatingLabelActiveTextColor = UIColor.redColor()
            passwordField.floatingLabelTextColor = UIColor.redColor()
        }
        
        return true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        usernameField.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewPasswordButton = UIButton()
        viewPasswordButton.setImage(UIImage(named: "Visibility")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: UIControlState.Normal)
        
        self.passwordField.rightView = viewPasswordButton
        self.passwordField.rightView?.bounds = CGRectMake(0, 0, 24, 24)
        self.passwordField.rightViewMode = .Always
        
        viewPasswordButton.addTarget(self, action: Selector("viewPasswordButtonTapped"),
                forControlEvents: UIControlEvents.TouchUpInside)
        
        // Set the view password button state to update the password button
        viewPassword = false
    }
    
    func viewPasswordButtonTapped() {
        viewPassword = !viewPassword
    }
    
    func loginToAPI() {
        loginClient.login(usernameField.text, password: passwordField.text, successHandler: {
            () -> () in
            
            // sync the units and stuff
            self.configurationManager.getFacilityDefaults(UserManager.facilityId!, successHandler: {
                () -> () in
                // got the facility details
                
                PKHUD.sharedHUD.hide(animated: false)
                
                self.dismissViewControllerAnimated(true, completion: nil)
                
            }, failureHandler: {
                (error) -> () in
                
                PKHUD.sharedHUD.hide(animated: false)
                
                // failed to get facility
                self.displayError(error, tryAgainCallback: {
                    self.loginToAPI()
                })
            })
            
            
        }, failureHandler: { (error : NSError) -> () in
            // fail
            PKHUD.sharedHUD.hide(animated: true)
            
            log.error("Login failed: " + error.localizedDescription)
            
            if let reason = error.localizedFailureReason {
                log.error("Reason for failure: " + reason)
            }
            
            self.errorLabel.text = error.localizedDescription
            self.passwordField.text = ""
            self.passwordField.becomeFirstResponder()
        })
    }
}
