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
    @IBOutlet weak var requestedLabel: UILabel!
    @IBOutlet weak var varianceLabel: UILabel!
    @IBOutlet weak var draggableIconImageView: UIImageView!

    var record: CensusRecord!
    var gridItem: GridItem!

    var canDragFromCell: Bool {
        return !record.isLocked && gridItem.actualStaff > 0
    }

    func canDragToCell(staffTypeName: String? = nil, fromUnit: Unit? = nil) -> Bool {
        var canDragToCell = !record.isLocked

        if staffTypeName != nil {
            canDragToCell = canDragToCell && gridItem.staffTypeName == staffTypeName
        }

        if fromUnit != nil {
            canDragToCell = canDragToCell && record.unit != fromUnit
        }
        
        return canDragToCell
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(record: CensusRecord, gridItem: GridItem, collapsed: Bool = false) {
        self.record = record
        self.gridItem = gridItem

        let census = record.census
        
        let recommendedStaff = gridItem.recommendedStaffForCensus(census)!
        let recordString = StaffingUtils.formattedRecordTime(record.recordTime)

        if collapsed {
            typeNameLabel.text = "\(recordString) - \(record.unit.name) - \(gridItem.staffTypeName)"
        } else {
            typeNameLabel.text = gridItem.staffTypeName
        }
        recommendedLabel.text = "\(recommendedStaff)"
        availableLabel.text = StaffingUtils.formatStaffing(gridItem.actualStaff)
        requestedLabel.text = StaffingUtils.formatStaffing(gridItem.requestedStaff)
        varianceLabel.text = StaffingUtils.formatStaffing(gridItem.resourceVariance, includePlusSymbol: true)

        draggableIconImageView.alpha = canDragToCell() || canDragFromCell ? 1.0 : 0.3
        
        if gridItem.resourceVariance > 0 {
            varianceLabel.layer.backgroundColor = StaffingColors.PostiveVariance.color().CGColor
        } else if gridItem.resourceVariance < 0 {
            varianceLabel.layer.backgroundColor = StaffingColors.NegativeVariance.color().CGColor
        } else {
            varianceLabel.layer.backgroundColor = StaffingColors.NoVariance.color().CGColor
        }
    }

}
