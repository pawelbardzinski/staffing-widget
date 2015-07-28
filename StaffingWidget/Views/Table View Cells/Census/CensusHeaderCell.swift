//
// Created by Michael Spencer on 7/12/15.
// Copyright (c) 2015 ANH. All rights reserved.
//

import Foundation

class CensusHeaderCell: UITableViewCell {

    @IBOutlet weak var availableLabel: UILabel!

    func configure(recordStatus: RecordStatus) {
        switch recordStatus {
            case .New, .Saved, .Adjusted:
                availableLabel.text = "Available Staff"
            case .Confirmed:
                availableLabel.text = "Actual Staff"
            case .Unknown:
                log.warning("Unknown record status, defaulting to Available Staff")
                availableLabel.text = "Available Staff"
        }
    }
}
