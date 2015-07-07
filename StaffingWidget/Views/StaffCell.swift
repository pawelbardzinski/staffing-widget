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
    @IBOutlet weak var actualStaffStepper: StepControl!
    
    var staffVariance: Double {
        get {
            return actualStaff - Double(gridStaff)
        }
    }

    var availableStaff: Double {
        get {
            return availableStaffStepper.value
        }
    }
    
    var actualStaff: Double {
        get {
            return actualStaffStepper.value
        }
    }
    
    var gridStaff:Int = 0
    
    var staffingChanged: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        varianceLabel.layer.cornerRadius = 2
        
        availableStaffStepper.editable = UserManager.roleInfo?.inputAvailableStaff ?? false
        actualStaffStepper.editable = UserManager.roleInfo?.inputActualStaff ?? false
        
        availableStaffStepper.tintColor = UIColor.blackColor()
        actualStaffStepper.tintColor = UIColor.blackColor()
        
        availableStaffStepper.size = .Small
        actualStaffStepper.size = .Small
        
        availableStaffStepper.valueChangedCallback = {
            self.updateVariance()
            self.staffingChanged?()
        }
        
        actualStaffStepper.valueChangedCallback = {
            self.updateVariance()
            self.staffingChanged?()
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureForGridItem(gridItem: GridItem, patientCount: Int) {
        gridStaff = gridItem.gridStaffForCensus(patientCount) ?? 0

        typeNameLabel.text = gridItem.staffTypeName
        gridValueLabel.text = "\(gridStaff)"
        availableStaffStepper.value = Double(gridItem.availableStaff)
        actualStaffStepper.value = Double(gridItem.actualStaff)
        
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
