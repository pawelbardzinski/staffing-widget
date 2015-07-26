//
//  DashboardViewController.swift
//  StaffingWidget
//
//  Created by Seth Hein on 7/2/15.
//  Copyright (c) 2015 ANH. All rights reserved.
//

import UIKit
import Charts

class DashboardViewController: UIViewController, ChartViewDelegate {

    var censusClient: CensusClient = CensusClientParseImplementation()
    var instanceTargets: [InstanceTargetItem] = []
    
    @IBOutlet weak var incidentActivity: UIActivityIndicatorView!
    @IBOutlet weak var incidentChart: HorizontalBarChartView!
    
    override func viewDidLoad() {

        // setup the incident chart
        incidentChart.delegate = self
        incidentChart.descriptionText = ""
        incidentChart.noDataText = ""
        incidentChart.noDataTextDescription = ""
        
        incidentChart.drawBarShadowEnabled = false
        incidentChart.drawValueAboveBarEnabled = true
        
        incidentChart.maxVisibleValueCount = 60
        incidentChart.pinchZoomEnabled = false
        incidentChart.drawGridBackgroundEnabled = false
        
        let xAxis = incidentChart.xAxis
        xAxis.labelPosition = .Bottom
        xAxis.labelFont = UIFont.systemFontOfSize(10.0)
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = true
        xAxis.gridLineWidth = 0.3
        
        let leftAxis = incidentChart.leftAxis
        leftAxis.labelFont = UIFont.systemFontOfSize(10.0)
        leftAxis.drawAxisLineEnabled = true
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridLineWidth = 0.3
        
        let rightAxis = incidentChart.rightAxis
        rightAxis.labelFont = UIFont.systemFontOfSize(10.0)
        rightAxis.drawAxisLineEnabled = true
        rightAxis.drawGridLinesEnabled = false
        
        incidentChart.legend.position = .BelowChartLeft
        incidentChart.legend.form = .Square
        incidentChart.legend.formSize = 8.0
        incidentChart.legend.font = UIFont.systemFontOfSize(11.0)
        incidentChart.legend.xEntrySpace = 4.0
        
        incidentChart.animate(yAxisDuration: 2.5)
    }
    
    override func viewWillAppear(animated: Bool) {
        incidentActivity.startAnimating()
        
        censusClient.getInstanceTargetReport(nil, successHandler: { (instanceTargetItems) -> () in
            // success!
            self.instanceTargets = instanceTargetItems
            self.setChartData(instanceTargetItems)
            }) { (error) -> () in
                // fail
                self.incidentActivity.stopAnimating()
        }
    }
    
    func setChartData(instanceTargets: [InstanceTargetItem]) {
        
        var staffTypes :[String] = []
        var xValsBelow :[BarChartDataEntry] = []
        var xValsAt :[BarChartDataEntry] = []
        var xValsAbove :[BarChartDataEntry] = []
        
        for instanceItem in instanceTargets
        {
            let index = staffTypes.count
            staffTypes.append(instanceItem.staffTypeName)
            xValsBelow.append(BarChartDataEntry(value: instanceItem.below, xIndex: index))
            xValsAt.append(BarChartDataEntry(value: instanceItem.at, xIndex: index))
            xValsAbove.append(BarChartDataEntry(value: instanceItem.above, xIndex: index))
        }
        
        let setBelow = BarChartDataSet(yVals: xValsBelow, label: "Below")
        setBelow.setColor(UIColor(red:0.95, green:0.23, blue:0.19, alpha:1))
        let setAt = BarChartDataSet(yVals: xValsAt, label: "At")
        setAt.setColor(UIColor(red:0.26, green:0.65, blue:0.28, alpha:1))
        let setAbove = BarChartDataSet(yVals: xValsAbove, label: "Above")
        setAbove.setColor(UIColor(red:0.11, green:0.55, blue:0.95, alpha:1))
        
        let chartData = BarChartData(xVals: staffTypes, dataSets: [setBelow, setAt, setAbove])
        chartData.groupSpace = 0.8
        chartData.setValueFont(UIFont.systemFontOfSize(10.0))
        
        incidentChart.data = chartData
        
        incidentActivity.stopAnimating()
    }
    
    // MARK: - ChartViewDelegate
    func chartValueSelected(chartView: Charts.ChartViewBase, entry: Charts.ChartDataEntry, dataSetIndex: Int, highlight: Charts.ChartHighlight)
    {
        println("Chart value selected")
    }
    
    func chartValueNothingSelected(chartView: Charts.ChartViewBase)
    {
        println("Chart value nothing selected")
    }

}
