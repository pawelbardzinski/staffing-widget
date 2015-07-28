//
//  CensusListTVC.swift
//  StaffingWidget
//
//  Created by Seth Hein on 6/23/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit
import SLExpandableTableView

protocol CensusListDelegate
{
    func recordSelected(record : CensusRecord)
}

class CensusListTVC: UITableViewController, UITableViewDataSource, UITableViewDelegate, SLExpandableTableViewDatasource, SLExpandableTableViewDelegate {
    
    // MARK: - Properties
    
    var delegate: CensusListDelegate!
    var assembly: ApplicationAssembly!
    var configurationManager:ConfigurationManager!    
    let censusClient: CensusClient = CensusClientParseImplementation()
    var pastRecords:Array<CensusRecord> = []
    var upcomingRecords:Array<CensusRecord> = []
    var previousSelectedCellIndex:NSIndexPath?
    var selectedCellIndex:NSIndexPath?
    
    override func viewDidLoad() {
            self.tableView.accessibilityLabel = "Census Records List"
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.selectRowAtIndexPath(self.selectedCellIndex, animated: false, scrollPosition: UITableViewScrollPosition.None)
    }
    
    func loadRecords() {
        var contentView = PKHUDProgressView()
        PKHUD.sharedHUD.contentView = contentView
        PKHUD.sharedHUD.show()
        
        censusClient.getLastDayRecords(UserManager.facilityId!, successHandler: { (records) -> () in
            PKHUD.sharedHUD.hide(animated: true)
            
            //success!
            let currentHour = StaffingUtils.currentHour()
            let currentDateString = StaffingUtils.recordDateFormatter().stringFromDate(NSDate())
            self.pastRecords = records.filter({$0.recordDateString != currentDateString || $0.recordTime < currentHour})
            self.upcomingRecords = records.filter({$0.recordDateString == currentDateString && $0.recordTime >= currentHour})
            self.tableView.reloadData()
        }) { (error) -> () in
            PKHUD.sharedHUD.hide(animated: false)
            // fail
            self.displayError(error)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if (section == 0)
        {
            return upcomingRecords.count
        } else {
            // the expandable table adds the expand cell at row 0
            return pastRecords.count + 1
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.section == 1 && indexPath.row == 0)
        {
            return 100.0
        } else {
            return 44.0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("CensusListCell", forIndexPath: indexPath) as! CensusListCell
        
        if (indexPath.section == 0)
        {
            let record = upcomingRecords[indexPath.row]
            cell.configureWithRecord(record)
        } else {
            // the expandable table adds the expand cell at row 0
            let record = pastRecords[indexPath.row - 1]
            cell.configureWithRecord(record)
        }
        
        if (indexPath == selectedCellIndex)
        {
            tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedCellIndex = indexPath
        if (previousSelectedCellIndex == nil)
        {
            previousSelectedCellIndex = indexPath
        }
        
        if (indexPath.section == 0)
        {
            let record = upcomingRecords[indexPath.row]
            delegate.recordSelected(record)
        } else {
            // the expandable table adds the expand cell at row 0
            let record = pastRecords[indexPath.row - 1]
            delegate.recordSelected(record)
        }
    }
    
    // MARK: - SLExpandableTableViewDatasource
    
    func tableView(tableView: SLExpandableTableView!, canExpandSection section: Int) -> Bool {
        if (section == 1)
        {
            return true
        }
        
        return false
    }
    
    func tableView(tableView: SLExpandableTableView!, needsToDownloadDataForExpandableSection section: Int) -> Bool {
        return false
    }
    
    func tableView(tableView: SLExpandableTableView!, expandingCellForSection section: Int) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier("CensusListHeaderCell") as! CensusListHeaderCell
        
        cell.titleLabel!.text = "Past Records"
        
        return cell
    }
    
    // MARK: - SLExpandableTableViewDelegate
    
    func tableView(tableView: SLExpandableTableView!, downloadDataForExpandableSection section: Int) {
        // nothing to see here
    }
}

extension CensusListTVC: CensusDelegate {
    func recordUpdated(record : CensusRecord)
    {
        if (previousSelectedCellIndex!.section == 0)
        {
            upcomingRecords[previousSelectedCellIndex!.row] = record
        } else {
            // the expandable table adds the expand cell at row 0            
            pastRecords[previousSelectedCellIndex!.row - 1] = record
        }
        
        self.tableView.reloadRowsAtIndexPaths([previousSelectedCellIndex!], withRowAnimation: UITableViewRowAnimation.Automatic)
        
        // if there is no selected cell (happens when confirming a record twice)
        // then select the cell
        if (tableView.indexPathForSelectedRow() == nil)
        {
            tableView.selectRowAtIndexPath(previousSelectedCellIndex, animated: false, scrollPosition: UITableViewScrollPosition.None)
        } else {
            previousSelectedCellIndex = tableView.indexPathForSelectedRow()
        }
    }
}
