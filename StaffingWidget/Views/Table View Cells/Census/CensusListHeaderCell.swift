//
//  CensusListHeaderCell.swift
//  StaffingWidget
//
//  Created by Seth Hein on 7/8/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit
import SLExpandableTableView

class CensusListHeaderCell: UITableViewCell, UIExpandingTableViewCell {
    
    private var _loading: Bool = false
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    var loading: Bool {
        @objc(isLoading) get {return _loading}
        @objc(setLoading:) set{ _loading = newValue}
    }
    
    var expansionStyle: UIExpansionStyle = UIExpansionStyleCollapsed
    
    
    func setExpansionStyle(style: UIExpansionStyle, animated: Bool) {

        // rotate 90 degrees
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            
            self.iconImageView.transform = CGAffineTransformMakeRotation((style.value == UIExpansionStyleExpanded.value) ? CGFloat(M_PI_2) : CGFloat(0))
            
        })
    }
}
