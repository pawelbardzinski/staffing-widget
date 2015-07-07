//
//  UIView+FirstResponder.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/21/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

extension UIView {
    func currentFirstResponder() -> UIResponder? {
        if self.isFirstResponder() {
            return self
        }
        
        for view in self.subviews {
            if let responder = view.currentFirstResponder() {
                return responder
            }
        }
        
        return nil
    }
}