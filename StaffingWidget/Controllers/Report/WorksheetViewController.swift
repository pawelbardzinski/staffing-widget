//
//  WorksheetViewController.swift
//  StaffingWidget
//
//  Created by Seth Hein on 5/27/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

enum WorksheetState {
    case Normal
    case Collapsed(staffTypeName:String)
    case EditingFloatPool
}

enum WorksheetTableSection {
    case Record(censusRecord:CensusRecord)
    case FloatPool(editing:Bool)
    case StaffingChanges
    case Collapsed(staffTypeName:String)
}

enum DragTarget {
    case Record(staffTypeName:String, unit:Unit, indexPath:NSIndexPath)
    case FlexOff
    case None
}

enum DragSource {
    case Record(staffTypeName:String, unit:Unit, indexPath:NSIndexPath)
    case FloatPool(staffTypeName:String, indexPath:NSIndexPath)
    case Extras
    case None
}

class WorksheetViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets and UI views

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var flexOffView: UIView!
    @IBOutlet weak var callExtraView: UIView!

    var resetButton: UIBarButtonItem!
    var saveButton: UIBarButtonItem!

    // MARK: - Dragging

    var dragSource: DragSource = .None

    var draggablePersonImageView: UIImageView!
    var offsetX: CGFloat!
    var offsetY: CGFloat!

    var previousIndexPath: NSIndexPath!

    // MARK: - Properties

    var worksheet: Worksheet!
    var recordId: String?

    var assembly: ApplicationAssembly!
    let censusClient: CensusClient = CensusClientParseImplementation()

    // MARK: - State management

    var worksheetState: WorksheetState = .Normal {
        didSet {
            self.tableView.reloadData()
        }
    }

    func tableSection(section: Int) -> WorksheetTableSection {
        switch worksheetState {
        case .Normal:
            if section == self.numberOfSectionsInTableView(tableView) - 1 {
                return .StaffingChanges
            } else if section == self.numberOfSectionsInTableView(tableView) - 2 {
                return .FloatPool(editing: false)
            } else {
                return .Record(censusRecord: self.worksheet.records[section])
            }
        case .Collapsed(let staffTypeName):
            if section == 0 {
                return .Collapsed(staffTypeName: staffTypeName)
            } else {
                return .StaffingChanges
            }
        case .EditingFloatPool:
            return .FloatPool(editing: true)
        }
    }

    var gridItems: [[String:Any]] {
        switch worksheetState {
        case .Collapsed(let staffTypeName):
            return worksheet.records.flatMap({
                (record) in

                return record.gridItems.filter({
                    $0.staffTypeName == staffTypeName
                }).map({
                    return [
                            "record": record,
                            "gridItem": $0
                    ]
                })
            })
        default:
            return []
        }
    }

    var floatItem: FloatPoolItem? {
        switch worksheetState {
        case .Collapsed(let staffTypeName):
            let matches = worksheet.floatPool.filter({ $0.staffTypeName == staffTypeName })

            if matches.count == 1 {
                return matches[0]
            } else {
                return nil
            }
        default:
            return nil
        }
    }

    var changes: [StaffChange] {
        switch worksheetState {
        case .Collapsed(let staffTypeName):
            return worksheet.changes.filter {
                $0.staffTypeName == staffTypeName
            }
        default:
            return worksheet.changes
        }
    }

    var nextStaffTypeName: String? {
        return staffTypeWithOffset(1)
    }

    var previousStaffTypeName: String? {
        return staffTypeWithOffset(-1)
    }

    func staffTypeWithOffset(offset: Int) -> String? {
        switch worksheetState {
        case .Collapsed(let staffTypeName):
            var index = find(worksheet.staffTypeNames, staffTypeName)
            var offsetIndex = index != nil ? index! + offset : -1

            if offsetIndex >= 0 && offsetIndex < worksheet.staffTypeNames.count {
                return worksheet.staffTypeNames[offsetIndex]
            } else {
                return nil
            }
        default:
            return nil
        }
    }

    // MARK: - View management

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        view.bringSubviewToFront(flexOffView)

        resetButton = UIBarButtonItem(title: "Reset", style: .Plain, target: self, action: "resetPressed:")
        saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "savePressed:")

        self.navigationItem.leftBarButtonItems = [resetButton, saveButton]

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: "personLongPress:")
        callExtraView.addGestureRecognizer(longPressGesture)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if recordId != nil {
            self.navigationItem.title = "Variance Record"
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
            reloadRecord()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        if worksheet != nil {
            saveWorksheet()
        }
    }

    // MARK: - Dragging

    func doubleTap(tap: UITapGestureRecognizer) {
        if tap.state == .Ended {
            let point = tap.locationInView(tap.view)
            let indexPath = self.tableView.indexPathForRowAtPoint(point)

            let cell = indexPath != nil ? tableView.cellForRowAtIndexPath(indexPath!) : nil
            let varianceCell = cell as? VarianceCell
            let floatCell = cell as? FloatPoolCell

            if varianceCell != nil || floatCell != nil {
                switch worksheetState {
                case .Collapsed(let staffTypeName):
                    worksheetState = .Normal
                case .Normal:
                    if varianceCell != nil {
                        worksheetState = .Collapsed(staffTypeName: varianceCell!.gridItem.staffTypeName)
                    } else {
                        worksheetState = .Collapsed(staffTypeName: floatCell!.floatPoolItem.staffTypeName)
                    }
                default:
                    break
                }
            }
        }
    }

    func personLongPress(gesture: UILongPressGestureRecognizer) {
        let state = gesture.state
        let location = gesture.locationInView(self.tableView)

        let flexOffLocation = gesture.locationInView(flexOffView)
        let inFlexOffView = flexOffView.bounds.contains(flexOffLocation)

        let callExtraLocation = gesture.locationInView(callExtraView)
        let inCallExtraView = callExtraView.bounds.contains(callExtraLocation)

        let indexPathForCell = inFlexOffView || inCallExtraView ? nil : self.tableView.indexPathForRowAtPoint(location)
        let cell = indexPathForCell != nil ? tableView.cellForRowAtIndexPath(indexPathForCell!) : nil

        switch state {
        case .Began:

            if (draggablePersonImageView == nil) {
                draggablePersonImageView = UIImageView(image: UIImage(named: "person"))
                self.view.addSubview(draggablePersonImageView)
                self.view.bringSubviewToFront(draggablePersonImageView)
            }

            var center: CGPoint!

            if cell != nil {
                if cell!.isKindOfClass(VarianceCell) {
                    let varianceCell = cell as! VarianceCell

                    if !varianceCell.canDragFromCell {
                        dragSource = .None
                        return
                    }

                    let centerInCell = varianceCell.draggableIconImageView.center
                    center = varianceCell.draggableIconImageView.superview!.convertPoint(centerInCell, toView: view)

                    dragSource = .Record(staffTypeName: varianceCell.gridItem.staffTypeName,
                            unit: varianceCell.record.unit,
                            indexPath: NSIndexPath(forRow: indexPathForCell!.row, inSection: indexPathForCell!.section))
                } else if cell!.isKindOfClass(FloatPoolCell) {
                    let floatCell = cell as! FloatPoolCell

                    if !floatCell.canDragFromCell {
                        dragSource = .None
                        return
                    }

                    let centerInCell = floatCell.draggableIconImageView.center
                    center = floatCell.draggableIconImageView.superview!.convertPoint(centerInCell, toView: view)

                    dragSource = .FloatPool(staffTypeName: floatCell.floatPoolItem.staffTypeName,
                            indexPath: NSIndexPath(forRow: indexPathForCell!.row, inSection: indexPathForCell!.section))
                }
            } else if inCallExtraView {
                if (draggablePersonImageView == nil) {
                    draggablePersonImageView = UIImageView(image: UIImage(named: "person"))
                    self.view.addSubview(draggablePersonImageView)
                    self.view.bringSubviewToFront(draggablePersonImageView)
                }

                center = callExtraView.convertPoint(callExtraLocation, toView: view)

                dragSource = .Extras
            }

            draggablePersonImageView.alpha = 0
            draggablePersonImageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            draggablePersonImageView.center = center

            offsetX = location.x - draggablePersonImageView.frame.origin.x
            offsetY = location.y - draggablePersonImageView.frame.origin.y

            UIView.animateWithDuration(0.5, animations: {
                () -> Void in

                switch self.dragSource {
                case .Extras:
                    self.callExtraView.backgroundColor = StaffingColors.CallInExtra(highlighted: true).color()
                default:
                    self.callExtraView.backgroundColor = StaffingColors.CallInExtra(highlighted: false).color()
                }

                if cell != nil && cell!.isKindOfClass(VarianceCell) {
                    let varianceCell = cell as! VarianceCell
                    varianceCell.draggableIconImageView.alpha = 0.0
                }

                self.draggablePersonImageView.alpha = 0.6
                self.draggablePersonImageView.transform = CGAffineTransformMakeScale(1.05, 1.05)

            })


        case .Changed:

            draggablePersonImageView.frame = CGRectMake(location.x - offsetX, location.y - offsetY,
                    draggablePersonImageView.frame.size.width, draggablePersonImageView.frame.size.height)

            var highlightCell = false
            var previousCell: UITableViewCell?

            switch dragSource {
            case .Record(let staffTypeName, let unit, let startingIndexPath):
                if cell != nil && cell!.isKindOfClass(VarianceCell) {
                    let varianceCell = cell as! VarianceCell

                    highlightCell = varianceCell.canDragToCell(staffTypeName: staffTypeName, fromUnit: unit)
                }
            case .FloatPool(let staffTypeName, let startingIndexPath):
                if cell != nil && cell!.isKindOfClass(VarianceCell) {
                    let varianceCell = cell as! VarianceCell

                    highlightCell = varianceCell.canDragToCell(staffTypeName: staffTypeName)
                }
            case .Extras:
                highlightCell = cell?.isKindOfClass(VarianceCell) ?? false
            default:
                highlightCell = false
            }

            if previousIndexPath != nil && indexPathForCell != previousIndexPath {
                previousCell = tableView.cellForRowAtIndexPath(previousIndexPath!)
            }

            previousIndexPath = highlightCell ? indexPathForCell : nil

            UIView.animateWithDuration(0.5, animations: {
                if highlightCell {
                    cell?.contentView.backgroundColor = StaffingColors.CompleteRecord.color().colorWithAlphaComponent(0.2)
                } else {
                    cell?.contentView.backgroundColor = UIColor.whiteColor()
                }
                previousCell?.contentView.backgroundColor = UIColor.whiteColor()
                self.flexOffView.backgroundColor = StaffingColors.FlexOff(highlighted: inFlexOffView).color()
            })

        default:

            var dragTarget = DragTarget.None
            var targetPersonCenter: CGPoint?
            var sourcePersonCenter: CGPoint?

            if cell != nil && cell!.isKindOfClass(VarianceCell) {
                let varianceCell = cell as! VarianceCell

                targetPersonCenter = varianceCell.draggableIconImageView.superview!.convertPoint(varianceCell.draggableIconImageView.center, toView: self.view)
                dragTarget = .Record(staffTypeName: varianceCell.gridItem.staffTypeName, unit: varianceCell.record.unit, indexPath: indexPathForCell!)
            } else if inFlexOffView {
                dragTarget = .FlexOff
            }

            switch (dragSource, dragTarget) {
            case (.Record(let staffTypeName, let fromUnit, let startingIndexPath),
                  .Record(let targetStaffTypeName, let toUnit, let endingIndexPath))
                 where staffTypeName == targetStaffTypeName && toUnit != fromUnit:
                worksheet.moveStaff(staffTypeName, fromUnit: fromUnit, toUnit: toUnit)
                tableView.reloadData()
            case (.Record(let staffTypeName, let fromUnit, let startingIndexPath),
                  .FlexOff):
                worksheet.flexOff(staffTypeName, fromUnit: fromUnit)
                tableView.reloadData()
            case (.FloatPool(let staffTypeName, let startingIndexPath),
                  .Record(let targetStaffTypeName, let toUnit, let endingIndexPath))
                 where staffTypeName == targetStaffTypeName:
                worksheet.floatIn(staffTypeName, toUnit: toUnit)
                tableView.reloadData()
            case (.Extras,
                  .Record(let targetStaffTypeName, let toUnit, let endingIndexPath)):
                worksheet.callInExtra(targetStaffTypeName, toUnit: toUnit)
                tableView.reloadData()
            default:
                dragTarget = .None
            }

            switch dragSource {
            case .Record(let staffTypeName, let fromUnit, let startingIndexPath):
                var startingCell = tableView.cellForRowAtIndexPath(startingIndexPath) as! VarianceCell
                startingCell.draggableIconImageView.alpha = 0
                sourcePersonCenter = startingCell.draggableIconImageView.superview!.convertPoint(startingCell.draggableIconImageView.center, toView: self.view)
            case .FloatPool(let staffTypeName, let startingIndexPath):
                // TODO: Calculate center for the float pool cell
                break
            case .Extras:
                sourcePersonCenter = callExtraView.superview!.convertPoint(callExtraView.center, toView: self.view)
            case .None:
                break
            }

            UIView.animateWithDuration(0.5, animations: {
                () -> Void in

                switch dragTarget {
                case .Record:
                    self.draggablePersonImageView.center = targetPersonCenter!

                    switch self.dragSource {
                    case .Record(let staffTypeName, let fromUnit, let startingIndexPath):
                        let startingCell = self.tableView.cellForRowAtIndexPath(startingIndexPath) as! VarianceCell
                        startingCell.draggableIconImageView.alpha = 1.0
                    default:
                        break
                    }
                case .FlexOff:
                    self.draggablePersonImageView.alpha = 0.0

                    switch self.dragSource {
                    case .Record(let staffTypeName, let fromUnit, let startingIndexPath):
                        let startingCell = self.tableView.cellForRowAtIndexPath(startingIndexPath) as! VarianceCell
                        startingCell.draggableIconImageView.alpha = 1.0
                    default:
                        break
                    }
                case .None:
                    if (sourcePersonCenter != nil) {
                        self.draggablePersonImageView.center = sourcePersonCenter!
                    } else {
                        self.draggablePersonImageView.alpha = 0.0

                        switch self.dragSource {
                        case .Record(let staffTypeName, let fromUnit, let startingIndexPath):
                            let startingCell = self.tableView.cellForRowAtIndexPath(startingIndexPath) as! VarianceCell
                            startingCell.draggableIconImageView.alpha = 1.0
                        default:
                            break
                        }
                    }
                }

                self.callExtraView.backgroundColor = StaffingColors.CallInExtra(highlighted: false).color()
                self.flexOffView.backgroundColor = StaffingColors.FlexOff(highlighted: false).color()
                cell?.contentView.backgroundColor = UIColor.whiteColor()
            }, completion: {
                (finished) in

                UIView.animateWithDuration(0.5, animations: {
                    self.draggablePersonImageView.alpha = 0.0
                })

                switch self.dragSource {
                case .Record(let staffTypeName, let fromUnit, let startingIndexPath):
                    let startingCell = self.tableView.cellForRowAtIndexPath(startingIndexPath) as! VarianceCell
                    startingCell.draggableIconImageView.alpha = 1.0
                default:
                    break
                }
            })
        }
    }

    // MARK: - Worksheet/census record management/reloading

    func reloadRecord() {
        var contentView = PKHUDProgressView()
        PKHUD.sharedHUD.contentView = contentView
        PKHUD.sharedHUD.show()

        if recordId != nil {
            censusClient.getRecord(recordId!, successHandler: {
                (record) -> () in
                PKHUD.sharedHUD.hide(animated: true)
                self.worksheet.records = [record]
                self.tableView.reloadData()
            }, failureHandler: {
                (error) -> () in
                PKHUD.sharedHUD.hide(animated: false)
                self.displayError(error) {
                    self.reloadRecord()
                }
            })
        } else {
            censusClient.getCurrentWorksheet(UserManager.facilityId!, successHandler: {
                (worksheet) -> () in
                PKHUD.sharedHUD.hide(animated: true)
                self.worksheet = worksheet
                self.resetButton.enabled = self.worksheet.resettable
                self.tableView.reloadData()
            }, failureHandler: {
                (error) -> () in
                PKHUD.sharedHUD.hide(animated: false)
                self.displayError(error) {
                    self.reloadRecord()
                }
            })
        }
    }

    func saveWorksheet() {
        var contentView = PKHUDProgressView()
        PKHUD.sharedHUD.contentView = contentView
        PKHUD.sharedHUD.show()

        censusClient.saveWorksheet(self.worksheet, successHandler: {
            (worksheet) -> () in
            PKHUD.sharedHUD.hide(animated: true)
            self.worksheet = worksheet
        }, failureHandler: {
            (error) -> () in
            PKHUD.sharedHUD.hide(animated: false)
            self.displayError(error) {
                self.saveWorksheet()
            }
        })
    }

    // MARK: - Table View Methods

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableSection(section) {
        case .StaffingChanges:
            return "Staffing changes"
        default:
            return nil
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        switch worksheetState {
        case .Normal:
            // census records, float pool, and staffing changes
            return self.worksheet != nil ? self.worksheet.records.count + 2 : 0
        case .Collapsed:
            // Collapsed: grid items + staffing changes
            return 2
        case .EditingFloatPool:
            return 1
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableSection(section) {
        case .Record(let censusRecord):
            // Grid Items + Unit title, header, WHPPD
            return censusRecord.gridItems.count + 3
        case .FloatPool(let editing):
            // Float pool items + title
            return worksheet.floatPool.count + 1
        case .StaffingChanges:
            // Staffing changes or none placeholder
            return max(self.changes.count, 1)
        case .Collapsed:
            // Grid Items + header, float item, and prev/next
            return gridItems.count + 2 + (floatItem != nil ? 1 : 0)
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = indexPath.row
        let rowCount = tableView.numberOfRowsInSection(indexPath.section)
        let lastRow = rowCount - 1

        switch tableSection(indexPath.section) {
        case .Record(let censusRecord):
            let gridItemIndex = row - 2

            if row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("TitleCell",
                        forIndexPath: indexPath) as! UnitTitleCell

                cell.configure(censusRecord.unit.name, recordTime: censusRecord.recordTime)

                return cell
            } else if row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier("HeaderCell",
                        forIndexPath: indexPath) as! UITableViewCell

                return cell
            } else if row == lastRow {
                let cell = tableView.dequeueReusableCellWithIdentifier("WHPPDCell",
                        forIndexPath: indexPath) as! WHPPDCell

                cell.configure(censusRecord.gridWHPPD, availableWHPPD: censusRecord.availableWHPPD)

                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("VarianceCell",
                        forIndexPath: indexPath) as! VarianceCell

                cell.configure(censusRecord, gridItem: censusRecord.gridItems[gridItemIndex],
                        collapsed: false)

                let longPressGesture = UILongPressGestureRecognizer(target: self, action: "personLongPress:")
                cell.draggableIconImageView.addGestureRecognizer(longPressGesture)

                return cell
            }
        case .Collapsed(let staffTypeName):
            let gridItemIndex = row - 1
            let floatItemRow = floatItem != nil ? lastRow - 1 : -1

            if row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("HeaderCell",
                        forIndexPath: indexPath) as! UITableViewCell

                return cell
            } else if row == floatItemRow {
                let cell = tableView.dequeueReusableCellWithIdentifier("FloatPoolCell",
                        forIndexPath: indexPath) as! FloatPoolCell

                cell.configure(floatItem!, collapsed: true, editing: false)

                let longPressGesture = UILongPressGestureRecognizer(target: self, action: "personLongPress:")
                cell.draggableIconImageView.addGestureRecognizer(longPressGesture)

                return cell
            } else if row == lastRow {
                let cell = tableView.dequeueReusableCellWithIdentifier("StaffTypeSwitcherCell",
                        forIndexPath: indexPath) as! StaffTypeSwitcherCell

                cell.configure(previousStaffTypeName, nextStaffTypeName: nextStaffTypeName, staffTypeNameChanged: {
                    (newStaffTypeName) in

                    self.worksheetState = .Collapsed(staffTypeName: newStaffTypeName)
                })

                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("VarianceCell",
                        forIndexPath: indexPath) as! VarianceCell

                let item = gridItems[gridItemIndex]

                let record = item["record"] as! CensusRecord
                let gridItem = item["gridItem"] as! GridItem

                cell.configure(record, gridItem: gridItem, collapsed: true)

                let longPressGesture = UILongPressGestureRecognizer(target: self, action: "personLongPress:")
                cell.draggableIconImageView.addGestureRecognizer(longPressGesture)

                return cell
            }
        case .StaffingChanges:
            let cell = tableView.dequeueReusableCellWithIdentifier("StaffChangeCell",
                    forIndexPath: indexPath) as! StaffChangeCell

            if changes.count > 0 {
                let change = changes[row]
                let gridItem = worksheet.gridItemForChange(change)

                cell.configure(gridItem, change: change, removeChange: {
                    (change) in

                    self.worksheet.addChange(change)
                    self.tableView.reloadData()
                })
            } else {
                switch worksheetState {
                case .Normal:
                    cell.configureWithNoChanges()
                case .Collapsed(let staffTypeName):
                    cell.configureWithNoSelectedChanges(staffTypeName)
                default:
                    log.error("There shouldn't be a staffing changes section when the float pool is editing!")
                }
            }

            return cell
        case .FloatPool(let editing):
            let floatIndex = row - 1

            if row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("TitleCell",
                        forIndexPath: indexPath) as! UnitTitleCell

                cell.configureForFloatPool(editing, editTapped: {
                    switch self.worksheetState {
                        case .EditingFloatPool:
                            self.worksheetState = .Normal
                        default:
                            self.worksheetState = .EditingFloatPool
                    }
                })

                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("FloatPoolCell",
                        forIndexPath: indexPath) as! FloatPoolCell

                cell.configure(worksheet.floatPool[floatIndex], collapsed: false, editing: editing)
                cell.staffingChanged = {
                    self.worksheet.floatPool[floatIndex].availableStaff = cell.availableStaff
                }

                let longPressGesture = UILongPressGestureRecognizer(target: self, action: "personLongPress:")
                cell.draggableIconImageView.addGestureRecognizer(longPressGesture)

                return cell
            }
        }
    }

    // MARK: - Actions

    @IBAction func signOutPressed(sender: AnyObject) {
        UserManager.signOut()
        let loginVC: UIViewController! = assembly.loginViewControllerFromStoryboard() as! UIViewController
        self.presentViewController(loginVC, animated: true, completion: nil)
    }

    @IBAction func resetPressed(sender: AnyObject) {
        worksheet.reset()
        tableView.reloadData()
    }

    @IBAction func savePressed(sender: AnyObject) {
        saveWorksheet()
    }
}
