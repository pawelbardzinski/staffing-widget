//
// Created by Michael Spencer on 7/16/15.
// Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

class StaffChangeCell: UITableViewCell {

    @IBOutlet weak var changeLabel: UILabel!
    @IBOutlet weak var minusButton: UIButton!

    var removeChange: ((change: StaffChange) -> ())!
    var change: StaffChange!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        minusButton.tintColor = UIColor.redColor()
        minusButton.setImage(minusButton.imageView?.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: .Normal)
    }

    func configure(gridItem: GridItem?, change: StaffChange, removeChange: (change: StaffChange) -> ()) {
        self.change = change
        self.removeChange = removeChange

        minusButton.hidden = false
        changeLabel.text = change.description

        minusButton.enabled = gridItem != nil ? gridItem!.actualStaff >= 1 : true
    }

    func configureWithNoSelectedChanges(staffTypeName: String) {
        self.change = nil
        self.removeChange = nil

        minusButton.hidden = true
        changeLabel.text = "No changes yet for \(staffTypeName)"
    }

    func configureWithNoChanges() {
        self.change = nil
        self.removeChange = nil

        minusButton.hidden = true
        changeLabel.text = "No changes yet"
    }

    @IBAction func minusPressed(sender: AnyObject) {
        removeChange(change: change.minusOne)
    }
}
