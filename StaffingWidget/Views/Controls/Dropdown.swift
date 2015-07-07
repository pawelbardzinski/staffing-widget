//
//  Dropdown.swift
//  StaffingWidget
//
//  Created by Michael Spencer on 5/12/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

@IBDesignable
class Dropdown: UITextField, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    var selectedIndex: Int = -1 {
        didSet {
            self.text = self.selectedItem
        }
    }
    
    var selectedItem: String? {
        set {
            self.selectedIndex = newValue != nil ? find(items, newValue!) ?? -1 : -1
        }
        
        get {
            return self.selectedIndex >= 0 ? self.items[self.selectedIndex] : nil
        }
    }
    
    var items: [String] = [String]()

    var popoverController: UIPopoverController?
    
    /**
     * Executed when the value is changed.
     */
    var selectedItemChangedCallback: ((String) -> ())?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.setUpView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setUpView()
    }

    func setUpView() {
        self.rightView = UIImageView(image: UIImage(named: "expand-more"))
        self.rightView?.alpha = 0.54
        self.rightView?.bounds = CGRectMake(0, 0, 24, 24)
        self.rightViewMode = .Always

        self.delegate = self
    }

    func openDropdown() {
        let tableViewController = UITableViewController(style: .Plain)
        
        tableViewController.tableView.delegate = self
        tableViewController.tableView.dataSource = self
        
        self.popoverController = UIPopoverController(contentViewController: tableViewController)
        
        self.popoverController?.presentPopoverFromRect(self.rightView!.frame, inView: self,
                permittedArrowDirections: UIPopoverArrowDirection.Up, animated: true)
    }

    override func rightViewRectForBounds(bounds: CGRect) -> CGRect {
        var rect = super.rightViewRectForBounds(bounds)
        rect.origin.x -= 5

        return rect
    }

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        openDropdown()
        return false
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("TableViewCell") as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "TableViewCell")
        }

        cell!.textLabel!.text = self.items[indexPath.row]
        cell?.accessoryType = self.items[indexPath.row] == self.selectedItem
                ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
    
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.popoverController?.dismissPopoverAnimated(true)
        self.popoverController = nil
        
        self.selectedIndex = indexPath.row
        
        self.selectedItemChangedCallback?(self.selectedItem!)
    }
}
