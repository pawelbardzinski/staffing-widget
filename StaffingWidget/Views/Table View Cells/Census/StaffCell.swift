//
//  StaffCell.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 5/13/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

class StaffCell: UITableViewCell {
    
    @IBOutlet weak var typeNameLabel: UILabel!
    @IBOutlet weak var gridValueLabel: UILabel!
    @IBOutlet weak var varianceLabel: UILabel!
    @IBOutlet weak var availableStaffStepper: StepControl!
    @IBOutlet weak var requestedStaffStepper: StepControl!

    var gridItem: GridItem!
    
    var staffVariance: Double {
        get {
            return actualStaff - Double(recommendedStaff)
        }
    }

    var actualStaff: Double {
        return availableStaffStepper.value
    }

    var availableStaff: Double {
        let staffChange = actualStaff - gridItem.actualStaff

        return gridItem.availableStaff + staffChange
    }
    
    var requestedStaff: Double {
        return requestedStaffStepper.value
    }
    
    var recommendedStaff:Int = 0
    
    var staffingChanged: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        varianceLabel.layer.cornerRadius = 2
        
        availableStaffStepper.tintColor = UIColor.blackColor()
        requestedStaffStepper.tintColor = UIColor.blackColor()
        
        availableStaffStepper.size = .Small
        requestedStaffStepper.size = .Small
        
        availableStaffStepper.valueChangedCallback = {
            self.updateVariance()
            self.staffingChanged?()
        }
        
        requestedStaffStepper.valueChangedCallback = {
            self.updateVariance()
            self.staffingChanged?()
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureForGridItem(gridItem: GridItem, patientCount: Int, isLocked: Bool) {
        self.gridItem = gridItem

        availableStaffStepper.editable = (UserManager.roleInfo?.inputAvailableStaff ?? false) && !isLocked
        requestedStaffStepper.editable = (UserManager.roleInfo?.inputActualStaff ?? false) && !isLocked

        recommendedStaff = gridItem.recommendedStaffForCensus(patientCount) ?? 0

        typeNameLabel.text = gridItem.staffTypeName
        gridValueLabel.text = "\(recommendedStaff)"

        // Set set this to actual staff so staffing changes are displayed,
        // but changes via the stepper are made to availableStaff
        availableStaffStepper.value = Double(gridItem.actualStaff)
        requestedStaffStepper.value = Double(gridItem.requestedStaff)
        
        updateVariance()
    }
    
    func updateVariance() {
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
