//
//  UnitTitleCell.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 6/30/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

class UnitTitleCell: UITableViewCell {

    @IBOutlet weak var unitNameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!

    var editTappedCallback: (() -> ())?
    
    func configureForFloatPool(editing: Bool, editTapped: () -> ()) {
        unitNameLabel.text = "Float Pool"
        editButton.setTitle(editing ? "Save" : "Edit", forState: .Normal)
        editButton.hidden = false
        editTappedCallback = editTapped
    }

    func configure(unitName: String, recordTime: NSTimeInterval) {
        let timeString = StaffingUtils.formattedRecordTime(recordTime)
        
        unitNameLabel.text = "\(timeString) - \(unitName)"
        editButton.hidden = true
    }

    @IBAction func editTapped(sender: AnyObject) {
        if editTappedCallback != nil {
            editTappedCallback!()
        }
    }
}
