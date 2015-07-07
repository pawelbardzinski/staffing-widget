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
    
    
    func configure(unitName: String, reportingTime: NSTimeInterval) {
        let timeString = StaffingUtils.formattedReportingTime(reportingTime)
        
        unitNameLabel.text = "\(timeString) - \(unitName)"
    }
}
