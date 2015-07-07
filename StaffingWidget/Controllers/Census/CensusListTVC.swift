//
//  CensusListTVC.swift
//  StaffingWidget
//
//  Created by Seth Hein on 6/23/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit

protocol CensusListDelegate
{
    func reportSelected(report : Report)
}

class CensusListTVC: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    
    var delegate: CensusListDelegate!
    var assembly: ApplicationAssembly!
    var configurationManager:ConfigurationManager!    
    let reportClient: ReportClient = ReportClientParseImplementation()
    var pastReports:Array<Report> = []
    var upcomingReports:Array<Report> = []
    var previousSelectedCellIndex:NSIndexPath?
    var selectedCellIndex:NSIndexPath?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.selectRowAtIndexPath(self.selectedCellIndex, animated: false, scrollPosition: UITableViewScrollPosition.None)
    }
    
    func loadReports() {
        var contentView = PKHUDProgressView()
        PKHUD.sharedHUD.contentView = contentView
        PKHUD.sharedHUD.show()
        
        reportClient.getLastDayReports(UserManager.facilityId!, successHandler: { (reports) -> () in
            PKHUD.sharedHUD.hide(animated: true)
            
            //success!
            let currentHour = StaffingUtils.currentHour()
            let currentDateString = StaffingUtils.reportDateFormatter().stringFromDate(NSDate())
            self.pastReports = reports.filter({$0.reportingDateString != currentDateString || $0.reportingTime < currentHour})
            self.upcomingReports = reports.filter({$0.reportingDateString == currentDateString && $0.reportingTime >= currentHour})
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
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0)
        {
            return ""
        } else {
            return "Past Reports"
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if (section == 0)
        {
            return upcomingReports.count
        } else {
            return pastReports.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("CensusListCell", forIndexPath: indexPath) as! CensusListCell
        
        if (indexPath.section == 0)
        {
            let report = upcomingReports[indexPath.row]
            cell.configureWithReport(report)
        } else {
            let report = pastReports[indexPath.row]
            cell.configureWithReport(report)
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
            let report = upcomingReports[indexPath.row]
            delegate.reportSelected(report)
        } else {
            let report = pastReports[indexPath.row]
            delegate.reportSelected(report)
        }
    }
}

extension CensusListTVC: CensusDelegate {
    func reportUpdated(report : Report)
    {
        if (previousSelectedCellIndex!.section == 0)
        {
            upcomingReports[previousSelectedCellIndex!.row] = report
        } else {
            pastReports[previousSelectedCellIndex!.row] = report
        }
        
        self.tableView.reloadRowsAtIndexPaths([previousSelectedCellIndex!], withRowAnimation: UITableViewRowAnimation.Automatic)
        
        // if there is no selected cell (happens when confirming a report twice)
        // then select the cell
        if (tableView.indexPathForSelectedRow() == nil)
        {
            tableView.selectRowAtIndexPath(previousSelectedCellIndex, animated: false, scrollPosition: UITableViewScrollPosition.None)
        } else {
            previousSelectedCellIndex = tableView.indexPathForSelectedRow()
        }
    }
}