//
//  CensusListCell.swift
//  StaffingWidget
//
//  Created by Seth Hein on 6/23/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

class CensusListCell: UITableViewCell {

    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var report : Report!
    
    override func setSelected(selected: Bool, animated: Bool) {
        let statusColor = statusView.backgroundColor
        super.setSelected(selected, animated: animated)
        statusView.backgroundColor = statusColor
    }
    
    func configureWithReport(report: Report) {
        self.report = report
        
        titleLabel.text = "\(StaffingUtils.formattedReportingTime(report.reportingTime)) - \(report.unit.name)"
        
        let todaysDateString = StaffingUtils.reportDateFormatter().stringFromDate(NSDate())
        if (report.confirmed == false && report.objectId != nil)
        {
            statusView.backgroundColor = StaffingColors.LateUnconfirmedReport.color()
        } else if (report.confirmed == true) {
            statusView.backgroundColor = StaffingColors.CompleteReport.color()
        }
        else if (todaysDateString == report.reportingDateString && StaffingUtils.currentHour() < report.reportingTime)
        {
            statusView.backgroundColor = StaffingColors.UpcomingReport.color()
        } else // report.objectId will be nil, so the report is late and unfilled here
        {
            statusView.backgroundColor = StaffingColors.LateUnfilledReport.color()
        }
        
        statusView.layer.cornerRadius = 4.0
    }
}
