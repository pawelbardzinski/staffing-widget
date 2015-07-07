//
//  CensusViewController.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-11.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

protocol CensusDelegate
{
    func reportUpdated(report : Report)
}

class CensusViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Containers
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var confirmContainer: UIView!
    
    @IBOutlet weak var finalizeView: UIView!
    // MARK: - Controls
    @IBOutlet weak var censusControl: StepControl!
    @IBOutlet weak var previousCensusLabel: UILabel!
    @IBOutlet weak var staffingTableView: UITableView!
    @IBOutlet weak var varianceReasonDropdown: Dropdown!
    @IBOutlet weak var varianceCommentsTextView: UITextView!

    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var noReportView: UIView!
    
    
    // MARK: - Constraints
    @IBOutlet weak var staffingGridHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var confirmContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollViewBottom: NSLayoutConstraint!
    
    // MARK: - Constants
    let rowHeight:CGFloat = 50.0
    let animationDuration = 0.25
    
    // MARK: - Properties
    var assembly : ApplicationAssembly!
    var configurationManager:ConfigurationManager!
    let reportClient: ReportClient = ReportClientParseImplementation()
    
    var delayTimer: NSTimer?

    var report: Report!
    
    var delegate : CensusDelegate!
    var censusListTVC: CensusListTVC!
    
    // MARK: - Initializers
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let splitViewController = self.navigationController?.parentViewController as! UISplitViewController
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        
        let navVC = splitViewController.viewControllers[0] as! UINavigationController
        censusListTVC = navVC.topViewController as! CensusListTVC
        censusListTVC.delegate = self;
        delegate = censusListTVC
        
        // setup census
        censusControl.tintColor = UIColor.blackColor()
        censusControl.valueChangedCallback = {
            self.report.census = Int(self.censusControl.value)
            
            // update grid values here
            self.staffingTableView.reloadData()
        }
        
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        noReportView.hidden = false
        
        if (UserManager.isLoggedIn) {
            censusListTVC.loadReports()
            self.censusControl.editable = UserManager.roleInfo?.inputActualCensus ?? false
        }
        
        if (UserManager.isLoggedIn && self.report != nil) {
            
            self.reloadReport()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        saveReport()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }

    // MARK: - Custom Methods
    
    func reloadReport() {
        
        if let facilityId = UserManager.facilityId
        {
            if (report != nil)
            {
        
                var contentView = PKHUDProgressView()
                PKHUD.sharedHUD.contentView = contentView
                PKHUD.sharedHUD.show()
                
                self.reportClient.getReport(report.unit.objectId, timestamp: ReportTimestamp(date: NSDate(), time: report.reportingTime),successHandler: {
                    (report) -> () in
                    PKHUD.sharedHUD.hide(animated: true)
                    
                    self.report = report
                    self.censusControl.maximumValue = Double(self.report.maxCensus)
                    self.censusControl.value = Double(self.report.census)
                    self.previousCensusLabel.text = String(self.report.previousCensus)
                    self.varianceReasonDropdown.selectedItem = report.reason
                    self.varianceCommentsTextView.text = report.comments
                    
                    self.adjustTableViewHeightAnimated(false)
                    
                    self.staffingTableView.reloadData()
            
                    self.noReportView.hidden = true
                    
                    self.varianceReasonDropdown.items = self.report.unit.varianceReasons
                    if self.varianceReasonDropdown.items.count == 0 {
                        self.varianceReasonDropdown.items = ["Other"]
                    }
                    self.varianceReasonDropdown.selectedIndex = find(self.varianceReasonDropdown.items,
                        self.report.reason) ?? -1
                    
                }) { (error) -> () in
                    PKHUD.sharedHUD.hide(animated: false)
                        
                    // Display the error and offer the option to try again
                    self.displayError(error) {
                            self.reloadReport()
                    }
                }
            }
        }
    }
    
    func visibleIndexOfStaffTypeName(staffTypeName: String) -> Int {
        let gridItem = self.report.visibleGridItems.filter({ $0.staffTypeName == staffTypeName }).first

        return gridItem != nil ? find(self.report.visibleGridItems, gridItem!) ?? -1 : -1
    }
    
    func indexOfStaffTypeName(staffTypeName: String) -> Int {
        let gridItem = self.report.gridItems.filter({ $0.staffTypeName == staffTypeName }).first

        return gridItem != nil ? find(self.report.gridItems, gridItem!) ?? -1 : -1
    }
    
    func saveReport(complete: (() -> ())? = nil) {
        
        if (report != nil)
        {
            var contentView = PKHUDProgressView()
            PKHUD.sharedHUD.contentView = contentView
            PKHUD.sharedHUD.show()
            
            reportClient.saveReport(self.report, successHandler: { (report: Report) -> () in
                PKHUD.sharedHUD.hide(animated: true)
                
                if (UserManager.isLoggedIn)
                {
                    self.report = report
                    self.delegate.reportUpdated(report)
                }
                
                complete?()
                
            }) { (error) -> () in
                PKHUD.sharedHUD.hide(animated: false)
                
                // Display the error with the option to try again
                self.displayError(error) {
                    self.saveReport(complete: complete)
                }
                
                self.resetFinalizeViewState()
            }
        } else {
            complete?()
        }
    }
    
    
    func delayFinalizeViewState() {
        delayTimer = NSTimer.scheduledTimerWithTimeInterval(3, target: self,
                selector: Selector("resetFinalizeViewState"), userInfo: nil, repeats: false)
    }
    
    func resetFinalizeViewState()
    {
        delayTimer?.invalidate()
        delayTimer = nil
        
        confirmContainerHeight.constant = 0
        
        confirmButton.enabled = true
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            
            self.buttonContainer.alpha = 1.0
            self.scrollView.layoutIfNeeded()
            
        })
    }
    
    // MARK: - Table View Methods
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("HeaderCell") as! UITableViewCell
        
        return headerCell.contentView
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let numberOfRows = self.report != nil ? self.report.visibleGridItems.count + 2 : 0
        
        return numberOfRows
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == self.report.visibleGridItems.count {
            let cell: AddStaffCell = tableView.dequeueReusableCellWithIdentifier("AddStaffCell", forIndexPath: indexPath) as! AddStaffCell
            
            cell.configureForStaffTypes(self.report.gridItems.filter({ $0.visible == false }).map {
                gridItem in gridItem.staffTypeName
            })
            
            cell.addGridItemCallback = { staffTypeName in
                self.report.gridItems[self.indexOfStaffTypeName(staffTypeName)].visible = true
                
                self.staffingTableView.beginUpdates()
                self.staffingTableView.insertRowsAtIndexPaths(
                        [NSIndexPath(forRow: self.visibleIndexOfStaffTypeName(staffTypeName), inSection: 0)],
                        withRowAnimation: UITableViewRowAnimation.Automatic)
                self.staffingTableView.reloadRowsAtIndexPaths(
                    [NSIndexPath(forRow: self.report.visibleGridItems.count - 1, inSection: 0)],
                    withRowAnimation: UITableViewRowAnimation.Automatic)
                self.staffingTableView.reloadRowsAtIndexPaths(
                    [NSIndexPath(forRow: self.report.visibleGridItems.count, inSection: 0)],
                    withRowAnimation: UITableViewRowAnimation.None)
                self.staffingTableView.endUpdates()
                
                self.adjustTableViewHeightAnimated(true)
            }
            
            return cell
        } else if indexPath.row == self.report.visibleGridItems.count + 1 {
            let cell: WHPPDCell = tableView.dequeueReusableCellWithIdentifier("WHPPDCell", forIndexPath: indexPath) as! WHPPDCell
            
            cell.configure(report.gridWHPPD, actualWHPPD: report.actualWHPPD)
            
            return cell
        } else {
            let cell: StaffCell = tableView.dequeueReusableCellWithIdentifier("StaffCell", forIndexPath: indexPath) as! StaffCell
            
            let gridItem: GridItem = self.report.visibleGridItems[indexPath.row]
            
            cell.configureForGridItem(gridItem, patientCount: Int(self.censusControl.value))
            
            cell.staffingChanged = {
                self.report.gridItems[self.indexOfStaffTypeName(gridItem.staffTypeName)].actualStaff = cell.actualStaff
                self.report.gridItems[self.indexOfStaffTypeName(gridItem.staffTypeName)].availableStaff = cell.availableStaff
                
                self.staffingTableView.beginUpdates()
                self.staffingTableView.reloadRowsAtIndexPaths(
                    [NSIndexPath(forRow: self.report.visibleGridItems.count + 1, inSection: 0)],
                    withRowAnimation: UITableViewRowAnimation.None)
                self.staffingTableView.endUpdates()
            }
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if (indexPath.row < report.visibleGridItems.count)
        {
            let gridItem = self.report.visibleGridItems[indexPath.row]
            
            if !gridItem.required {
                return true
            }
        }
        
        return false
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? // supercedes -
    {
        if (indexPath.row < report.visibleGridItems.count)
        {
            let gridItem = self.report.visibleGridItems[indexPath.row]
            
            if !gridItem.required {
                var deleteAction = UITableViewRowAction(style: .Default, title: "Delete") {
                    (action, indexPath) -> Void in
                    
                    self.report.gridItems[self.indexOfStaffTypeName(gridItem.staffTypeName)].visible = false
                    self.report.gridItems[self.indexOfStaffTypeName(gridItem.staffTypeName)].actualStaff = 0
                    self.report.gridItems[self.indexOfStaffTypeName(gridItem.staffTypeName)].availableStaff = 0
                    
                    self.staffingTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.staffingTableView.reloadRowsAtIndexPaths(
                        [NSIndexPath(forRow: self.report.visibleGridItems.count, inSection: 0)],
                        withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.staffingTableView.reloadRowsAtIndexPaths(
                        [NSIndexPath(forRow: self.report.visibleGridItems.count + 1, inSection: 0)],
                        withRowAnimation: UITableViewRowAnimation.None)
                    
                    self.adjustTableViewHeightAnimated(true)
                }
                
                return [ deleteAction ]
            }
        }
        
        return []
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    
    }
    
    func adjustTableViewHeightAnimated(animated:Bool)
    {
        // adjust the height of the UITableView so that we scroll properly
        // adding an extra two rows here to account for the header and add cell
        
        self.tableViewHeight.constant = CGFloat(self.report.visibleGridItems.count + 3) * self.rowHeight
        
        if animated
        {
            UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                self.scrollView.layoutIfNeeded()
            })
        }
        
    }
    
    // MARK: - Actions
    
    @IBAction func signOutPressed(sender: AnyObject) {
        report = nil
        UserManager.signOut()
        let loginVC : UIViewController! = assembly.loginViewControllerFromStoryboard() as! UIViewController
        self.presentViewController(loginVC, animated: true, completion: nil)
    }
    
    @IBAction func confirmButtonPressed(sender: AnyObject) {
        
        confirmContainerHeight.constant = 250.0
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            
            self.buttonContainer.alpha = 0.0
            self.scrollView.layoutIfNeeded()
            
        })

    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        
        confirmContainerHeight.constant = 0
        
        confirmButton.enabled = true
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            
            self.scrollView.layoutIfNeeded()
            
        })

    }
    
    @IBAction func cancelConfirmTapped(sender: AnyObject) {
        resetFinalizeViewState()
    }
    
    @IBAction func finalConfirmTapped(sender: AnyObject) {
        
        view.endEditing(true)
        
        report.reason = varianceReasonDropdown.selectedItem!
        report.comments = varianceCommentsTextView.text
        report.confirmed = true
        
        saveReport()
    }
    
}

extension CensusViewController: CensusListDelegate {
    func reportSelected(report: Report) {
        
        saveReport { () -> () in
            self.report = report
            self.reloadReport()
        }
    }
}
