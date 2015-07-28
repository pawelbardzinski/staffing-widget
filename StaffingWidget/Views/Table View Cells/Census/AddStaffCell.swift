//
//  AddStaffCell.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 5/14/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

class AddStaffCell: UITableViewCell {
    
    @IBOutlet weak var typeDropdown: Dropdown!
    
    var staffTypes = [String]()
    
    /**
     * Executed when an item from the type dropdown is selected
     */
    var addGridItemCallback: ((String) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        typeDropdown.selectedItemChangedCallback = { selectedItem in
            self.addGridItemCallback?(selectedItem)
            self.typeDropdown.selectedIndex = -1
        }
    }
    
    func configureForStaffTypes(staffTypes: Array<String>) {
        self.staffTypes = staffTypes
        
        typeDropdown.items = staffTypes
    }
}
