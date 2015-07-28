
//
//  WHPPDCell.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 6/2/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

class WHPPDCell: UITableViewCell {
    
    @IBOutlet weak var gridValueLabel: UILabel!
    @IBOutlet weak var availableStaffLabel: UILabel!
    
    func configure(gridWHPPD: Double, availableWHPPD: Double) {
        gridValueLabel.text = String(format: "%.1f", gridWHPPD)
        availableStaffLabel.text = String(format: "%.1f", availableWHPPD)
    }
}
