//
//  VarianceCell.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 6/15/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

class FloatPoolCell: UITableViewCell {

    @IBOutlet weak var typeNameLabel: UILabel!
    @IBOutlet weak var availableLabel: UILabel!
    @IBOutlet weak var availableStepper: StepControl!
    @IBOutlet weak var draggableIconImageView: UIImageView!

    var floatPoolItem: FloatPoolItem!
    var staffingChanged: (() -> ())?

    var actualStaff: Double {
        return availableStepper.value
    }

    var availableStaff: Double {
        let staffChange = actualStaff - floatPoolItem.actualStaff

        return floatPoolItem.availableStaff + staffChange
    }

    var canDragFromCell: Bool {
        return floatPoolItem.actualStaff > 0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        availableStepper.tintColor = UIColor.blackColor()
        availableStepper.size = .Small
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(floatPoolItem: FloatPoolItem, collapsed: Bool, editing: Bool) {
        self.floatPoolItem = floatPoolItem
        availableStepper.hidden = !editing
        availableLabel.hidden = editing
        draggableIconImageView.hidden = editing

        if collapsed {
            typeNameLabel.text = "Float Pool - \(floatPoolItem.staffTypeName)"
        } else {
            typeNameLabel.text = floatPoolItem.staffTypeName
        }

        availableLabel.text = StaffingUtils.formatStaffing(floatPoolItem.actualStaff)
        availableStepper.value = Double(floatPoolItem.actualStaff)

        draggableIconImageView.alpha = canDragFromCell ? 1.0 : 0.3

        availableStepper.valueChangedCallback = {
            self.staffingChanged?()
        }
    }
}
