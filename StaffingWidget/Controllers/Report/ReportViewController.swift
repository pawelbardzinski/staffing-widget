//
//  ReportViewController.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/27/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

class ReportViewController: UITableViewController {
    
    var reportId: String?
    var draggablePersonImageView: UIImageView!
    var offsetX: CGFloat!
    var offsetY: CGFloat!
    var longPressedIndexPath: NSIndexPath!
    var previousIndexPath: NSIndexPath!
    var draggingStaffType: String!

    // MARK: - Properties
    var assembly: ApplicationAssembly!
    let reportClient: ReportClient = ReportClientParseImplementation()
    
    var reports = [Report]()

    var gridItems: [[String: Any]] {
        var list = [[String: Any]]()
        
        if selectedStaffType != nil {
            for report in reports {
                let gridItem: [GridItem] = report.gridItems.filter({ $0.staffTypeName == self.selectedStaffType })
                
                if gridItem.count == 1 {
                    let gridItemInfo: [String: Any] = [
                        "unitName": report.unit.name,
                        "census": report.census,
                        "reportingTime": report.reportingTime,
                        "gridItem": gridItem[0]
                    ]
                    
                    list.append(gridItemInfo)
                }
            }
        }
        
        return list
    }
    
    var selectedStaffType: String? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var collapsed: Bool {
        return selectedStaffType != nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if reportId != nil {
            self.navigationItem.title = "Variance Report"
            self.tableView.allowsSelection = false
        } else {
            let doubleTap = UITapGestureRecognizer(target: self, action: "doubleTap:")
            doubleTap.numberOfTapsRequired = 2
            doubleTap.numberOfTouchesRequired = 1
            self.tableView.addGestureRecognizer(doubleTap)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserManager.isLoggedIn {
            reloadReport()
        }
    }
    
    func doubleTap(tap: UITapGestureRecognizer) {
        if tap.state == .Ended {
            if collapsed {
                selectedStaffType = nil
            } else {
                let point = tap.locationInView(tap.view)
                let indexPath = self.tableView.indexPathForRowAtPoint(point)
                
                if indexPath != nil {
                    let report = self.reports[indexPath!.section]
                    
                    if indexPath!.row > 1 && indexPath!.row < report.gridItems.count + 2 {
                        let gridItem = report.gridItems[indexPath!.row - 2]
                        selectedStaffType = gridItem.staffTypeName
                    }
                }
            }
        }
    }
    
    func personLongPress(gesture: UILongPressGestureRecognizer)
    {
        let state = gesture.state
        let location = gesture.locationInView(self.tableView)
        
        let indexPathForCell = self.tableView.indexPathForRowAtPoint(location)
        
        switch state {
        case .Began:
            
            if (draggablePersonImageView == nil)
            {
                draggablePersonImageView = UIImageView(image: UIImage(named: "person"))
                self.view.addSubview(draggablePersonImageView)
            }
            
            let cell = tableView.cellForRowAtIndexPath(indexPathForCell!) as! VarianceCell
            let centerInCell = cell.draggableIconImageView.center
            let center = cell.draggableIconImageView.superview!.convertPoint(centerInCell, toView: view)
            
            let componentsOfString = cell.typeNameLabel.text?.componentsSeparatedByString(" - ")
            if let componentCount = componentsOfString?.count
            {
                draggingStaffType = componentsOfString?[componentCount - 1]
            }
            
            longPressedIndexPath = NSIndexPath(forRow: indexPathForCell!.row, inSection: indexPathForCell!.section)
            
            draggablePersonImageView.alpha = 0
            draggablePersonImageView.frame = cell.draggableIconImageView.frame
            draggablePersonImageView.center = center

            
            offsetX = location.x - draggablePersonImageView.frame.origin.x
            offsetY = location.y - draggablePersonImageView.frame.origin.y
            
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                
                cell.draggableIconImageView.alpha = 0.0
                self.draggablePersonImageView.alpha = 0.6
                self.draggablePersonImageView.transform = CGAffineTransformMakeScale(1.05, 1.05)
                
            }, completion: { (bool) -> Void in
                cell.draggableIconImageView.hidden = true
            })
            
            
        case .Changed:
            
            draggablePersonImageView.frame = CGRectMake(location.x - offsetX, location.y - offsetY, draggablePersonImageView.frame.size.width, draggablePersonImageView.frame.size.height)
            
            if (indexPathForCell != nil )
            {
                let cell = tableView.cellForRowAtIndexPath(indexPathForCell!)
            
                if (cell!.isKindOfClass(VarianceCell))
                {
                    let varianceCell = cell as! VarianceCell
                    
                    let componentsOfString = varianceCell.typeNameLabel.text?.componentsSeparatedByString(" - ")
                    if let componentCount = componentsOfString?.count
                    {
                        let varianceStaffType = componentsOfString?[componentCount - 1]
                        
                        if (varianceStaffType == draggingStaffType)
                        {
                            cell?.contentView.backgroundColor = StaffingColors.CompleteReport.color().colorWithAlphaComponent(0.2)
                        }
                    }
                }
                
                if (previousIndexPath != nil && (indexPathForCell != previousIndexPath))
                {
                    let previousCell = tableView.cellForRowAtIndexPath(previousIndexPath!)
                    
                    previousCell?.contentView.backgroundColor = UIColor.whiteColor()
                    
                    previousIndexPath = NSIndexPath(forRow: indexPathForCell!.row, inSection: indexPathForCell!.section)
                } else {
                    previousIndexPath = NSIndexPath(forRow: indexPathForCell!.row, inSection: indexPathForCell!.section)
                }
            }

            
        default:

            let originalCell = tableView.cellForRowAtIndexPath(longPressedIndexPath) as! VarianceCell
            
            if (indexPathForCell != nil)
            {
                let cell = tableView.cellForRowAtIndexPath(indexPathForCell!)
            
                if (cell!.isKindOfClass(VarianceCell))
                {
                    let varianceCell = cell as! VarianceCell
                    
                    let componentsOfString = varianceCell.typeNameLabel.text?.componentsSeparatedByString(" - ")
                    if let componentCount = componentsOfString?.count
                    {
                        let varianceCellStaffType = componentsOfString?[componentCount - 1]
                    
                        if (varianceCellStaffType == draggingStaffType)
                        {
                            
                            var originalActual = (originalCell.actualLabel.text as NSString?)!.doubleValue
                            if (originalActual >= 1)
                            {
                                // if the cells have the same staff type, then we can update the numbers
                                    
                                var originalReport = reports[collapsed ? (longPressedIndexPath.row - 1) : longPressedIndexPath.section]
                                for (var gridIndex = 0; gridIndex < originalReport.gridItems.count; gridIndex++)
                                {
                                    if (originalReport.gridItems[gridIndex].staffTypeName == draggingStaffType)
                                    {
                                        originalReport.gridItems[gridIndex].actualStaff = originalReport.gridItems[gridIndex].actualStaff - 1.0
                                        
                                    }
                                }
                                reports[collapsed ? (longPressedIndexPath.row - 1) : longPressedIndexPath.section] = originalReport
                                
                                var newReport = reports[collapsed ? (indexPathForCell!.row - 1) : indexPathForCell!.section]
                                for (var gridIndex = 0; gridIndex < newReport.gridItems.count; gridIndex++)
                                {
                                    if (newReport.gridItems[gridIndex].staffTypeName == draggingStaffType)
                                    {
                                        newReport.gridItems[gridIndex].actualStaff = newReport.gridItems[gridIndex].actualStaff + 1.0
                                        
                                    }
                                }
                                reports[collapsed ? (indexPathForCell!.row - 1) : indexPathForCell!.section] = newReport
                                
                                tableView.reloadData()
                            }
                        
                        }
                    }
                }
                
                cell?.contentView.backgroundColor = UIColor.whiteColor()
            }
            

            originalCell.draggableIconImageView.alpha = 0.0
            originalCell.draggableIconImageView.hidden = false
            
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                
                originalCell.draggableIconImageView.alpha = 1.0
                self.draggablePersonImageView.alpha = 0.0
                self.draggablePersonImageView.bounds = originalCell.draggableIconImageView.bounds
                
                }, completion: { (bool) -> Void in
                    
            })
            
        }
    }
    
    func reloadReport() {
        var contentView = PKHUDProgressView()
        PKHUD.sharedHUD.contentView = contentView
        PKHUD.sharedHUD.show()
        
        if reportId != nil {
            reportClient.getReport(reportId!, successHandler: { (report) -> () in
                PKHUD.sharedHUD.hide(animated: true)
                self.reports = [report]
                self.tableView.reloadData()
            }, failureHandler: { (error) -> () in
                PKHUD.sharedHUD.hide(animated: false)
                self.displayError(error) {
                    self.reloadReport()
                }
            })
        } else {
            reportClient.getCurrentReports(UserManager.facilityId!, successHandler: { (reports) -> () in
                PKHUD.sharedHUD.hide(animated: true)
                self.reports = reports
                self.tableView.reloadData()
            }, failureHandler: { (error) -> () in
                PKHUD.sharedHUD.hide(animated: false)
                self.displayError(error) {
                    self.reloadReport()
                }
            })
        }
    }

    // MARK: - Table View Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return collapsed ? 1 : reports.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if collapsed {
            return gridItems.count + 1
        } else {
            let report = reports[section]
            
            let numberOfRows = report.gridItems.count + 3
            
            return numberOfRows
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if (collapsed) {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("HeaderCell",
                    forIndexPath: indexPath) as! UITableViewCell
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("VarianceCell",
                    forIndexPath: indexPath) as! VarianceCell
                
                let item = gridItems[indexPath.row - 1]
                
                let unitName = item["unitName"] as! String
                let reportingTime = item["reportingTime"] as! NSTimeInterval
                let census = item["census"] as! Int
                let gridItem = item["gridItem"] as! GridItem
                
                cell.configure(unitName, reportingTime: reportingTime, gridItem: gridItem, census: census)
                    
                let longPressGesture = UILongPressGestureRecognizer(target: self, action: "personLongPress:")
                    cell.draggableIconImageView.addGestureRecognizer(longPressGesture)
                
                return cell
            }
        } else {
        
            let report = reports[indexPath.section]
            
            if (indexPath.row == 0) {
                let cell = tableView.dequeueReusableCellWithIdentifier("TitleCell",
                    forIndexPath: indexPath) as! UnitTitleCell
                
                cell.configure(report.unit.name, reportingTime: report.reportingTime)
                
                return cell
            } else if (indexPath.row == 1) {
                let cell = tableView.dequeueReusableCellWithIdentifier("HeaderCell",
                    forIndexPath: indexPath) as! UITableViewCell
                
                return cell
            } else if (indexPath.row == report.gridItems.count + 2) {
                let cell = tableView.dequeueReusableCellWithIdentifier("WHPPDCell",
                    forIndexPath: indexPath) as! WHPPDCell
                
                cell.configure(report.gridWHPPD, actualWHPPD: report.actualWHPPD)
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("VarianceCell",
                    forIndexPath: indexPath) as! VarianceCell
                
                let gridItem = report.gridItems[indexPath.row - 2]
                
                cell.configure(gridItem, census: report.census)
                
                let longPressGesture = UILongPressGestureRecognizer(target: self, action: "personLongPress:")
                cell.draggableIconImageView.addGestureRecognizer(longPressGesture)
                
                return cell
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func signOutPressed(sender: AnyObject) {
        UserManager.signOut()
        let loginVC : UIViewController! = assembly.loginViewControllerFromStoryboard() as! UIViewController
        self.presentViewController(loginVC, animated: true, completion: nil)
    }
}
