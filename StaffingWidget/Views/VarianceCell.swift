//
//  VarianceCell.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 6/15/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

class VarianceCell: UITableViewCell {

    @IBOutlet weak var typeNameLabel: UILabel!
    @IBOutlet weak var recommendedLabel: UILabel!
    @IBOutlet weak var availableLabel: UILabel!
    @IBOutlet weak var actualLabel: UILabel!
    @IBOutlet weak var varianceLabel: UILabel!
    @IBOutlet weak var draggableIconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(unitName: String, reportingTime: NSTimeInterval, gridItem: GridItem, census: Int) {
        
        let staffVariance = gridItem.staffVarianceForCensus(census)!
        let gridStaff = gridItem.gridStaffForCensus(census)!
        let reportingString = StaffingUtils.formattedReportingTime(reportingTime)
        
        typeNameLabel.text = "\(reportingString) - \(unitName) - \(gridItem.staffTypeName)"
        recommendedLabel.text = "\(gridStaff)"
        availableLabel.text = StaffingUtils.formatStaffing(gridItem.availableStaff)
        actualLabel.text = StaffingUtils.formatStaffing(gridItem.actualStaff)
        varianceLabel.text = StaffingUtils.formatStaffing(staffVariance, includePlusSymbol: true)
        
        if staffVariance > 0 {
            varianceLabel.layer.backgroundColor = UIColor(red: 0.8, green: 1, blue: 0.8, alpha: 1).CGColor
        } else if staffVariance < 0 {
            varianceLabel.layer.backgroundColor = UIColor(red: 1, green: 0.8, blue: 0.8, alpha: 1).CGColor
        } else {
            varianceLabel.layer.backgroundColor = UIColor.clearColor().CGColor
        }
    }
    
    func configure(gridItem: GridItem, census: Int) {
        
        let staffVariance = gridItem.staffVarianceForCensus(census)!
        let gridStaff = gridItem.gridStaffForCensus(census)!
        
        typeNameLabel.text = gridItem.staffTypeName
        recommendedLabel.text = "\(gridStaff)"
        availableLabel.text = StaffingUtils.formatStaffing(gridItem.availableStaff)
        actualLabel.text = StaffingUtils.formatStaffing(gridItem.actualStaff)
        varianceLabel.text = StaffingUtils.formatStaffing(staffVariance, includePlusSymbol: true)
        
        if staffVariance > 0 {
            varianceLabel.layer.backgroundColor = UIColor(red: 0.8, green: 1, blue: 0.8, alpha: 1).CGColor
        } else if staffVariance < 0 {
            varianceLabel.layer.backgroundColor = UIColor(red: 1, green: 0.8, blue: 0.8, alpha: 1).CGColor
        } else {
            varianceLabel.layer.backgroundColor = UIColor.clearColor().CGColor
        }
    }

}
