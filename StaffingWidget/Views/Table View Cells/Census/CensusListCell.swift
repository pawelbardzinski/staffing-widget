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
    
    var record : CensusRecord!
    
    override func setSelected(selected: Bool, animated: Bool) {
        let statusColor = statusView.backgroundColor
        super.setSelected(selected, animated: animated)
        statusView.backgroundColor = statusColor
    }
    
    func configureWithRecord(record: CensusRecord) {
        self.record = record
        
        titleLabel.text = "\(StaffingUtils.formattedRecordTime(record.recordTime)) - \(record.unit.name)"
        
        let todaysDateString = StaffingUtils.recordDateFormatter().stringFromDate(NSDate())
        let upcoming = todaysDateString == record.recordDateString && StaffingUtils.currentHour() < record.recordTime

        switch record.status {
            case .New:
                if upcoming {
                    statusView.accessibilityLabel = "Upcoming";
                    statusView.backgroundColor = StaffingColors.UpcomingRecord.color()
                } else {
                    statusView.backgroundColor = StaffingColors.LateUnfilledRecord.color()
                }
            case .Saved, .Adjusted:
                statusView.accessibilityLabel = "Late Unconfirmed"
                statusView.backgroundColor = StaffingColors.LateUnconfirmedRecord.color()
            case .Confirmed:
                statusView.accessibilityLabel = "Complete"
                statusView.backgroundColor = StaffingColors.CompleteRecord.color()
            default:
                log.warning("Unrecognized record status: " + record.status.rawValue)
        }
        
        statusView.layer.cornerRadius = 4.0
    }
}
