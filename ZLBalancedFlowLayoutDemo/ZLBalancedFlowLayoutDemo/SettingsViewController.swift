//
//  SettingsViewController.swift
//  ZLBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 1/1/15.
//  Copyright (c) 2015 Zhixuan Lai. All rights reserved.
//

import UIKit

class SettingsViewController : UITableViewController {
    
    weak var demoViewController: ViewController?

    class func presentInViewController(_ viewController: ViewController) {
        let settingsViewController = SettingsViewController(style: .grouped)
        settingsViewController.demoViewController = viewController
        viewController.present(UINavigationController(rootViewController: settingsViewController), animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,  target: self, action: #selector(SettingsViewController.doneButtonAction(_:)))
    }
    
    var rowHeightLabel: UILabel?
    var numSectionsLabel: UILabel?
    var numRepetitionLabel: UILabel?

    // MARK: - Action
    func doneButtonAction(_ sender:UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func directionSwitchAction(_ sender:UISwitch) {
        demoViewController?.direction = sender.isOn ? .vertical : .horizontal
    }
    
    func rowHeightSliderAction(_ sender:UISlider) {
        demoViewController?.rowHeight = CGFloat(50 + sender.value * 100)
        rowHeightLabel?.text = "\(demoViewController!.rowHeight)"
    }

    func rowHeightSwitchAction(_ sender:UISwitch) {
        demoViewController?.enforcesRowHeight = sender.isOn
    }

    func numSectionsSliderAction(_ sender:UISlider) {
        demoViewController?.numSections = Int(1 + sender.value * 19)
        numSectionsLabel?.text = "\(demoViewController!.numSections)"
    }

    func numRepetitionsSliderAction(_ sender:UISlider) {
        demoViewController?.numRepetitions = Int(1 + sender.value * 19)
        numRepetitionLabel?.text = "\(demoViewController!.numRepetitions)"
    }

    
    // MARK: - Cells
    enum SettingsTableViewControllerSection: Int {
        case direction, rowHeight, dataSource, count
        
        enum DirectionRow: Int {
            case direction, count
        }
        
        enum RowHeightRow: Int {
            case rowHeight, enforcesRowHeight, count
        }
        
        enum DataSourceRow: Int {
            case numSections, numRepetitions, count
        }
        
        static let sectionTitles = [direction: "Scroll Direction", rowHeight: "Row Height", dataSource: ""]
        static let sectionCount = [direction: DirectionRow.count.rawValue, rowHeight: RowHeightRow.count.rawValue, dataSource: DataSourceRow.count.rawValue, ];
        
        func sectionHeaderTitle() -> String {
            if let sectionTitle = SettingsTableViewControllerSection.sectionTitles[self] {
                return sectionTitle
            } else {
                return "Section"
            }
        }
        
        func sectionRowCount() -> Int {
            if let sectionCount = SettingsTableViewControllerSection.sectionCount[self] {
                return sectionCount
            } else {
                return 0
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsTableViewControllerSection.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsTableViewControllerSection(rawValue:section)!.sectionRowCount()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SettingsTableViewControllerSection(rawValue:section)!.sectionHeaderTitle()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = String(format: "s%li-r%li", (indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as UITableViewCell? ?? UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        
        cell.selectionStyle = .none
        switch SettingsTableViewControllerSection(rawValue:(indexPath as NSIndexPath).section)! {
        case .direction:
            switch SettingsTableViewControllerSection.DirectionRow(rawValue: (indexPath as NSIndexPath).row)! {
            case .direction:
                let directionSwith = UISwitch()
                directionSwith.addTarget(self, action: #selector(SettingsViewController.directionSwitchAction(_:)), for: .valueChanged)
                if let demoViewController = demoViewController {
                    directionSwith.isOn = demoViewController.direction == .vertical
                }
                cell.accessoryView = directionSwith
                cell.textLabel!.text = "Vertical"
            default:
                cell.textLabel!.text = "Direction"
            }
        case .rowHeight:
            switch SettingsTableViewControllerSection.RowHeightRow(rawValue: (indexPath as NSIndexPath).row)! {
            case .rowHeight:
                let slider = UISlider()
                slider.addTarget(self, action: #selector(SettingsViewController.rowHeightSliderAction(_:)), for: .valueChanged)
                if let demoViewController = demoViewController {
                    slider.value = Float((demoViewController.rowHeight-50)/100)
                    cell.detailTextLabel!.text = "\(demoViewController.rowHeight)"
                }
                cell.accessoryView = slider
                cell.textLabel!.text = "Height"
                rowHeightLabel = cell.detailTextLabel
            case .enforcesRowHeight:
                let enforceSwith = UISwitch()
                enforceSwith.addTarget(self, action: #selector(SettingsViewController.rowHeightSwitchAction(_:)), for: .valueChanged)
                if let demoViewController = demoViewController {
                    enforceSwith.isOn = demoViewController.enforcesRowHeight
                }
                cell.accessoryView = enforceSwith
                cell.textLabel!.text = "Enforces Row Height"
            default:
                cell.textLabel!.text = "RowHeight"
            }
        case .dataSource:
            switch SettingsTableViewControllerSection.DataSourceRow(rawValue: (indexPath as NSIndexPath).row)! {
            case .numSections:
                let slider = UISlider()
                slider.addTarget(self, action: #selector(SettingsViewController.numSectionsSliderAction(_:)), for: .valueChanged)
                if let demoViewController = demoViewController {
                    slider.value = Float(demoViewController.numSections-1)/19.0
                    cell.detailTextLabel!.text = "\(demoViewController.numSections)"
                }
                cell.accessoryView = slider
                cell.textLabel!.text = "# Sections"
                numSectionsLabel = cell.detailTextLabel
            case .numRepetitions:
                let slider = UISlider()
                slider.addTarget(self, action: #selector(SettingsViewController.numRepetitionsSliderAction(_:)), for: .valueChanged)
                if let demoViewController = demoViewController {
                    slider.value = Float(demoViewController.numRepetitions-1)/19.0
                    cell.detailTextLabel!.text = "\(demoViewController.numRepetitions)"
                }
                cell.accessoryView = slider
                cell.textLabel!.text = "# Repetitions"
                numRepetitionLabel = cell.detailTextLabel
            default:
                cell.textLabel!.text = "DataSource"
            }
        default:
            cell.textLabel!.text = "N/A"
        }
        
        
        return cell
    }
    
}
