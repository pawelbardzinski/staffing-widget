//
// Created by Michael Spencer on 7/16/15.
// Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

class StaffTypeSwitcherCell: UITableViewCell {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!

    var nextStaffTypeName: String!
    var previousStaffTypeName: String!

    var staffTypeNameChanged: ((staffTypeName: String) -> ())!

    func configure(previousStaffTypeName: String?, nextStaffTypeName: String?, staffTypeNameChanged: (staffTypeName: String) -> ()) {
        
        if (nextStaffTypeName != nil)
        {
            nextButton.setTitle("\(nextStaffTypeName!) >", forState: .Normal)
        }
        nextButton.hidden = nextStaffTypeName == nil

        if (previousStaffTypeName != nil)
        {
            previousButton.setTitle("< \(previousStaffTypeName!)", forState: .Normal)
        }
        previousButton.hidden = previousStaffTypeName == nil

        self.nextStaffTypeName = nextStaffTypeName
        self.previousStaffTypeName = previousStaffTypeName
        self.staffTypeNameChanged = staffTypeNameChanged
    }

    @IBAction func nextPressed(sender: AnyObject) {
        staffTypeNameChanged(staffTypeName: nextStaffTypeName)
    }

    @IBAction func previousPressed(sender: AnyObject) {
        staffTypeNameChanged(staffTypeName: previousStaffTypeName)
    }
}
