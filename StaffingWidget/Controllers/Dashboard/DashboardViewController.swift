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
    var unitHoursItems: [UnitHoursItem] = []
    
    @IBOutlet weak var incidentActivity: UIActivityIndicatorView!
    @IBOutlet weak var incidentChart: HorizontalBarChartView!
    @IBOutlet weak var unitHoursChart: HorizontalBarChartView!
    @IBOutlet weak var unitHoursActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {

        setupChart(incidentChart)
        setupChart(unitHoursChart)
    }
    
    override func viewWillAppear(animated: Bool) {
        incidentActivity.startAnimating()
        
        censusClient.getInstanceTargetByStaffTypeReport(nil, successHandler: { (instanceTargetItems) -> () in
            // success!
            self.instanceTargets = instanceTargetItems
            self.setInstanceChartData(instanceTargetItems)
            }) { (error) -> () in
                // fail
                self.incidentActivity.stopAnimating()
        }
        
        unitHoursActivity.startAnimating()
        
        censusClient.getPersonHoursReport(nil, successHandler: { (unitHoursItems) -> () in
            // success!
            self.unitHoursItems = unitHoursItems
            self.setPersonHoursChartData(unitHoursItems)
            
        }) { (error) -> () in
            // fail
            self.unitHoursActivity.stopAnimating()
        }
    }
    
    // MARK: - Custom Methods
    
    func setPersonHoursChartData(unitHoursItems: [UnitHoursItem]) {
        
        var unitNames :[String] = []
        var xValsGuideline :[BarChartDataEntry] = []
        var xValsActual :[BarChartDataEntry] = []
        
        for unitHoursItem in unitHoursItems
        {
            let index = unitNames.count
            unitNames.append(unitHoursItem.unitName)
            xValsGuideline.append(BarChartDataEntry(value: unitHoursItem.guidelinePersonHours, xIndex: index))
            xValsActual.append(BarChartDataEntry(value: unitHoursItem.actualPersonHours, xIndex: index))
        }
        
        let setGuideline = BarChartDataSet(yVals: xValsGuideline, label: "Guideline")
        setGuideline.setColor(UIColor(red:0.95, green:0.23, blue:0.19, alpha:1))
        let setActual = BarChartDataSet(yVals: xValsActual, label: "Actual")
        setActual.setColor(UIColor(red:0.26, green:0.65, blue:0.28, alpha:1))
        
        let chartData = BarChartData(xVals: unitNames, dataSets: [setGuideline, setActual])
        chartData.groupSpace = 0.8
        chartData.setValueFont(UIFont.systemFontOfSize(10.0))
        
        unitHoursChart.data = chartData
        
        unitHoursActivity.stopAnimating()
    }
    
    func setInstanceChartData(instanceTargets: [InstanceTargetItem]) {
        
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
    
    func setupChart(chart: BarChartView)
    {
        // setup the incident chart
        chart.delegate = self
        chart.descriptionText = ""
        chart.noDataText = ""
        chart.noDataTextDescription = ""
        
        chart.drawBarShadowEnabled = false
        chart.drawValueAboveBarEnabled = true
        
        chart.maxVisibleValueCount = 60
        chart.pinchZoomEnabled = false
        chart.drawGridBackgroundEnabled = false
        
        let xAxis = chart.xAxis
        xAxis.labelPosition = .Bottom
        xAxis.labelFont = UIFont.systemFontOfSize(10.0)
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = true
        xAxis.gridLineWidth = 0.3
        
        let leftAxis = chart.leftAxis
        leftAxis.labelFont = UIFont.systemFontOfSize(10.0)
        leftAxis.drawAxisLineEnabled = true
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridLineWidth = 0.3
        
        let rightAxis = chart.rightAxis
        rightAxis.labelFont = UIFont.systemFontOfSize(10.0)
        rightAxis.drawAxisLineEnabled = true
        rightAxis.drawGridLinesEnabled = false
        
        chart.legend.position = .BelowChartLeft
        chart.legend.form = .Square
        chart.legend.formSize = 8.0
        chart.legend.font = UIFont.systemFontOfSize(11.0)
        chart.legend.xEntrySpace = 4.0
        
        chart.animate(yAxisDuration: 2.5)
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
