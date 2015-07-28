//
//  CensusViewController.swift
//  StaffingWidget
//
//  Created by Jim Rutherford on 2015-05-11.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

protocol CensusDelegate {
    func recordUpdated(record: CensusRecord)
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
    @IBOutlet weak var finalConfirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var noRecordView: UIView!


    // MARK: - Constraints
    @IBOutlet weak var staffingGridHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var confirmContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollViewBottom: NSLayoutConstraint!

    // MARK: - Constants
    let rowHeight: CGFloat = 50.0
    let animationDuration = 0.25

    // MARK: - Properties
    var assembly: ApplicationAssembly!
    var configurationManager: ConfigurationManager!
    var censusClient: CensusClient = CensusClientParseImplementation()

    var delayTimer: NSTimer?

    var record: CensusRecord!

    var delegate: CensusDelegate!
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
        
        view.bringSubviewToFront(noRecordView)

        let splitViewController = self.navigationController?.parentViewController as! UISplitViewController
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        navigationItem.leftBarButtonItem?.accessibilityLabel = "Show Records"

        let navVC = splitViewController.viewControllers[0] as! UINavigationController
        censusListTVC = navVC.topViewController as! CensusListTVC
        censusListTVC.delegate = self;
        delegate = censusListTVC

        // setup census
        censusControl.tintColor = UIColor.blackColor()
        censusControl.valueChangedCallback = {
            self.record.census = Int(self.censusControl.value)

            // update grid values here
            self.staffingTableView.reloadData()
        }
        censusControl.plusButton.accessibilityLabel = "Increase Census"
        censusControl.minusButton.accessibilityLabel = "Decrease Census"
        censusControl.valueField.accessibilityLabel = "Current Census"

        varianceReasonDropdown.selectedItemChangedCallback = {
            selectedItem in
            self.finalConfirmButton.enabled = true
        }

        self.automaticallyAdjustsScrollViewInsets = false
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        noRecordView.hidden = false

        if (UserManager.isLoggedIn) {
            censusListTVC.loadRecords()
        }

        if (UserManager.isLoggedIn && self.record != nil) {

            self.reloadRecord()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        saveRecord()
    }

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }

    // MARK: - Custom Methods

    func reloadRecord() {

        if let facilityId = UserManager.facilityId {
            if (record != nil) {

                var contentView = PKHUDProgressView()
                PKHUD.sharedHUD.contentView = contentView
                PKHUD.sharedHUD.show()

                self.censusClient.getRecord(record.unit.objectId, timestamp: RecordTimestamp(date: NSDate(), time: record.recordTime), successHandler: {
                    (record) -> () in
                    PKHUD.sharedHUD.hide(animated: true)

                    self.record = record
                    self.censusControl.maximumValue = Double(self.record.maxCensus)
                    self.censusControl.value = Double(self.record.census)
                    self.previousCensusLabel.text = String(self.record.previousCensus)
                    self.varianceCommentsTextView.text = record.comments

                    self.adjustTableViewHeightAnimated(false)

                    self.staffingTableView.reloadData()

                    self.noRecordView.hidden = true

                    self.varianceReasonDropdown.items = self.record.unit.varianceReasons
                    if self.varianceReasonDropdown.items.count == 0 {
                        self.varianceReasonDropdown.items = ["Other"]
                    }
                    self.varianceReasonDropdown.selectedItem = record.reason
                    self.finalConfirmButton.enabled = self.varianceReasonDropdown.selectedItem != nil
                    
                    self.updateControls()

                }) {
                    (error) -> () in
                    PKHUD.sharedHUD.hide(animated: false)

                    // Display the error and offer the option to try again
                    self.displayError(error) {
                        self.reloadRecord()
                    }
                }
            }
        }
    }

    func visibleIndexOfStaffTypeName(staffTypeName: String) -> Int {
        let gridItem = self.record.visibleGridItems.filter({ $0.staffTypeName == staffTypeName }).first

        return gridItem != nil ? find(self.record.visibleGridItems, gridItem!) ?? -1 : -1
    }

    func indexOfStaffTypeName(staffTypeName: String) -> Int {
        let gridItem = self.record.gridItems.filter({ $0.staffTypeName == staffTypeName }).first

        return gridItem != nil ? find(self.record.gridItems, gridItem!) ?? -1 : -1
    }

    func saveRecord(complete: (() -> ())? = nil) {

        if (record != nil) {
            var contentView = PKHUDProgressView()
            PKHUD.sharedHUD.contentView = contentView
            PKHUD.sharedHUD.show()

            censusClient.saveRecord(self.record, successHandler: {
                (record: CensusRecord) -> () in
                PKHUD.sharedHUD.hide(animated: true)

                if (UserManager.isLoggedIn) {
                    self.record = record
                    self.updateControls()
                    self.staffingTableView.reloadData()
                    self.delegate.recordUpdated(record)
                }

                complete?()

                self.resetFinalizeViewState()

            }) {
                (error) -> () in
                PKHUD.sharedHUD.hide(animated: false)

                // Display the error with the option to try again
                self.displayError(error) {
                    self.saveRecord(complete: complete)
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

    func resetFinalizeViewState() {
        delayTimer?.invalidate()
        delayTimer = nil

        confirmContainerHeight.constant = 0

        confirmButton.enabled = true
        
        staffingTableView.reloadData()

        UIView.animateWithDuration(animationDuration, animations: {
            self.buttonContainer.alpha = 1.0
            
            self.adjustTableViewHeightAnimated(false)
        })
    }

    // MARK: - Table View Methods

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell: CensusHeaderCell = tableView.dequeueReusableCellWithIdentifier("HeaderCell") as! CensusHeaderCell

        headerCell.configure(self.record != nil ? self.record.status : .Unknown)

        return headerCell.contentView
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let numberOfRows = self.record != nil ? self.record.visibleGridItems.count +
                self.record.changeDescriptions.count + 2 : 0

        return numberOfRows
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == self.record.visibleGridItems.count {
            let cell: AddStaffCell = tableView.dequeueReusableCellWithIdentifier("AddStaffCell", forIndexPath: indexPath) as! AddStaffCell

            cell.configureForStaffTypes(self.record.gridItems.filter({ $0.visible == false }).map {
                gridItem in gridItem.staffTypeName
            })

            cell.addGridItemCallback = {
                staffTypeName in
                self.record.gridItems[self.indexOfStaffTypeName(staffTypeName)].visible = true

                self.staffingTableView.beginUpdates()
                self.staffingTableView.insertRowsAtIndexPaths(
                [NSIndexPath(forRow: self.visibleIndexOfStaffTypeName(staffTypeName), inSection: 0)],
                        withRowAnimation: UITableViewRowAnimation.Automatic)
                self.staffingTableView.reloadRowsAtIndexPaths(
                [NSIndexPath(forRow: self.record.visibleGridItems.count - 1, inSection: 0)],
                        withRowAnimation: UITableViewRowAnimation.Automatic)
                self.staffingTableView.reloadRowsAtIndexPaths(
                [NSIndexPath(forRow: self.record.visibleGridItems.count, inSection: 0)],
                        withRowAnimation: UITableViewRowAnimation.None)
                self.staffingTableView.endUpdates()

                self.adjustTableViewHeightAnimated(true)
            }

            return cell
        } else if indexPath.row == self.record.visibleGridItems.count + 1 {
            let cell: WHPPDCell = tableView.dequeueReusableCellWithIdentifier("WHPPDCell", forIndexPath: indexPath) as! WHPPDCell

            cell.configure(record.gridWHPPD, availableWHPPD: record.availableWHPPD)

            return cell
        } else if indexPath.row >= self.record.visibleGridItems.count + 2 {
            let cell = tableView.dequeueReusableCellWithIdentifier("StaffChangeCell", forIndexPath: indexPath) as! UITableViewCell

            let change = self.record.changeDescriptions[indexPath.row - self.record.visibleGridItems.count - 2]

            cell.textLabel!.text = change

            return cell
        } else {
            let cell: StaffCell = tableView.dequeueReusableCellWithIdentifier("StaffCell", forIndexPath: indexPath) as! StaffCell

            let gridItem: GridItem = self.record.visibleGridItems[indexPath.row]

            cell.configureForGridItem(gridItem, patientCount: Int(self.censusControl.value), isLocked: self.record.isLocked)

            cell.staffingChanged = {
                self.record.gridItems[self.indexOfStaffTypeName(gridItem.staffTypeName)].availableStaff = cell.availableStaff
                self.record.gridItems[self.indexOfStaffTypeName(gridItem.staffTypeName)].requestedStaff = cell.requestedStaff

                self.staffingTableView.beginUpdates()
                self.staffingTableView.reloadRowsAtIndexPaths(
                [NSIndexPath(forRow: self.record.visibleGridItems.count + 1, inSection: 0)],
                        withRowAnimation: UITableViewRowAnimation.None)
                self.staffingTableView.endUpdates()
            }

            return cell
        }
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if (indexPath.row < record.visibleGridItems.count) {
            let gridItem = self.record.visibleGridItems[indexPath.row]

            if !gridItem.required {
                return true
            }
        }

        return false
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]?  {
        if (indexPath.row < record.visibleGridItems.count) {
            let gridItem = self.record.visibleGridItems[indexPath.row]

            if !gridItem.required {
                var deleteAction = UITableViewRowAction(style: .Default, title: "Delete") {
                    (action, indexPath) -> Void in

                    self.record.gridItems[self.indexOfStaffTypeName(gridItem.staffTypeName)].visible = false
                    self.record.gridItems[self.indexOfStaffTypeName(gridItem.staffTypeName)].availableStaff = 0
                    self.record.gridItems[self.indexOfStaffTypeName(gridItem.staffTypeName)].requestedStaff = 0

                    self.staffingTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.staffingTableView.reloadRowsAtIndexPaths(
                    [NSIndexPath(forRow: self.record.visibleGridItems.count, inSection: 0)],
                            withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.staffingTableView.reloadRowsAtIndexPaths(
                    [NSIndexPath(forRow: self.record.visibleGridItems.count + 1, inSection: 0)],
                            withRowAnimation: UITableViewRowAnimation.None)

                    self.adjustTableViewHeightAnimated(true)
                }

                return [deleteAction]
            }
        }

        return []
    }

    func adjustTableViewHeightAnimated(animated: Bool) {
        // adjust the height of the UITableView so that we scroll properly
        // adding an extra two rows here to account for the header and add cell

        self.tableViewHeight.constant = CGFloat(self.record.visibleGridItems.count +
                self.record.changeDescriptions.count + 3) * self.rowHeight

        if animated {
            UIView.animateWithDuration(animationDuration, animations: {
                () -> Void in
                self.scrollView.layoutIfNeeded()
            })
        }

    }

    // MARK: - Actions

    @IBAction func signOutPressed(sender: AnyObject) {
        record = nil
        UserManager.signOut()
        let loginVC: UIViewController! = assembly.loginViewControllerFromStoryboard() as! UIViewController
        self.presentViewController(loginVC, animated: true, completion: nil)
    }

    @IBAction func confirmButtonPressed(sender: AnyObject) {
        let showConfirmationInput = record.status == .Adjusted

        if showConfirmationInput {
            confirmContainerHeight.constant = 250.0
            finalConfirmButton.enabled = varianceReasonDropdown.selectedItem != nil

            updateControls()

            UIView.animateWithDuration(animationDuration, animations: {
                () -> Void in

                self.buttonContainer.alpha = 0.0
                self.scrollView.layoutIfNeeded()

            })
        } else {
            record.status = .Saved

            saveRecord()
        }
    }

    @IBAction func cancelButtonTapped(sender: AnyObject) {

        confirmContainerHeight.constant = 0

        confirmButton.enabled = true

        UIView.animateWithDuration(animationDuration, animations: {
            self.scrollView.layoutIfNeeded()
        })
    }

    @IBAction func cancelConfirmTapped(sender: AnyObject) {
        resetFinalizeViewState()
    }

    @IBAction func finalConfirmTapped(sender: AnyObject) {

        view.endEditing(true)

        record.reason = varianceReasonDropdown.selectedItem!
        record.comments = varianceCommentsTextView.text

        switch record.status {
        case .New:
            record.status = .Saved
        case .Saved:
            log.error("A record cannot be confirmed until it has been adjusted in the worksheet!")
        case .Adjusted:
            record.status = .Confirmed
        case .Confirmed:
            // TODO: If past 30min after the record time, throw an error
            record.status = .Adjusted
        default:
            log.error("Unreognized record status: " + self.record.status.rawValue)
        }

        saveRecord()
    }

    func updateControls() {
        var title: String!
        let enabled = record.canEdit

        switch record.status {
        case .New:
            title = "Save"
        case .Saved:
            title = "Save"
        case .Adjusted:
            title = "Confirm"
        case .Confirmed:
            title = "Unconfirm"
        default:
            log.error("Unreognized record status: " + self.record.status.rawValue)
        }

        confirmButton.setTitle(title, forState: .Normal)
        confirmButton.enabled = enabled
        finalConfirmButton.setTitle(title, forState: .Normal)

        self.censusControl.editable = (UserManager.roleInfo?.inputActualCensus ?? false) && !self.record.isLocked
    }
}

extension CensusViewController: CensusListDelegate {
    func recordSelected(record: CensusRecord) {

        saveRecord {
            () -> () in
            self.record = record
            self.reloadRecord()
        }
    }
}
