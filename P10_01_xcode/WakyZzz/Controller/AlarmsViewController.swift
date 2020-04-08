//
//  AlarmsViewController.swift
//  WakyZzz
//
//  Created by Olga Volkova on 2018-05-30.
//  Copyright © 2018 Olga Volkova OC. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class AlarmsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AlarmCellDelegate, SettingAlarmViewControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    private var alarms = [Alarm]()
    private var editingIndexPath: IndexPath?
    private var appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    @IBAction func addButtonPress(_ sender: Any) {
        presentAlarmViewController(alarm: nil)
    }

    // MARK: - Configuration
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
    }
    
    func config() {
        tableView.delegate = self
        tableView.dataSource = self
        ManagingData.shared.refresh()
        loadAlarmsFromCoreDataAndPopulateTableView()
//        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }
    // Populate initial two alarms
    private func populateAlarms() {
        
        let firstInitialAlarm = AlertRing(entity: AlertRing.entity(), insertInto: ManagingData.shared.context)
        // Weekdays 5am
        firstInitialAlarm.time = 5 * 3600
        firstInitialAlarm.repeatMon = true
        firstInitialAlarm.repeatTue = true
        firstInitialAlarm.repeatWed = true
        firstInitialAlarm.repeatThu = true
        firstInitialAlarm.repeatFri = true
        firstInitialAlarm.repeatSat = false
        firstInitialAlarm.repeatSun = false
        firstInitialAlarm.enabled   = true
        // CreationDate is used as an alarm identifier
        firstInitialAlarm.creationDateID = (appDelegate?.stringFrom(Date()))!
        ManagingData.shared.appDelegate.saveContext()
        
        let secondInitialAlarm = AlertRing(entity: AlertRing.entity(), insertInto: ManagingData.shared.context)
        // Weekend 9am
        secondInitialAlarm.time = 9 * 3600
        secondInitialAlarm.enabled = false
        secondInitialAlarm.repeatMon = false
        secondInitialAlarm.repeatTue = false
        secondInitialAlarm.repeatWed = false
        secondInitialAlarm.repeatThu = false
        secondInitialAlarm.repeatFri = false
        secondInitialAlarm.repeatSun = true
        secondInitialAlarm.repeatSat = true
        // + 1 to make sure each initial alarm has a unique identifier, since both of them are created at the same time.
        secondInitialAlarm.creationDateID = (appDelegate?.stringFrom(Date()))! + "1"
        ManagingData.shared.appDelegate.saveContext()
        ManagingData.shared.refresh()
    }
    
    // MARK: - TabelView datasource and delegate method
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmCell", for: indexPath) as! AlarmTableViewCell
        cell.delegate = self
        if let alarm = alarm(at: indexPath) {
            cell.populate(caption: alarm.caption, subcaption: alarm.repeating, enabled: alarm.enabled)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.deleteAlarm(at: indexPath)
        }
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
            self.editAlarm(at: indexPath)
        }
        return [delete, edit]
    }
    
    // MARK: - Alarm creation, editing and deletion functionality
    private func alarm(at indexPath: IndexPath) -> Alarm? {
        return indexPath.row < alarms.count ? alarms[indexPath.row] : nil
    }
    
    private func deleteAlarm(at indexPath: IndexPath) {
        appDelegate?.removePendingNotificationFor(alarmID: (alarm(at: indexPath)?.dateID!)!)
        
        if let alarm = ManagingData.shared.fetchedRC?.object(at: indexPath) {
            ManagingData.shared.context.delete(alarm)
            ManagingData.shared.appDelegate.saveContext()
        }
        tableView.beginUpdates()
        alarms.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
    
    private func editAlarm(at indexPath: IndexPath) {
        editingIndexPath = indexPath
        presentAlarmViewController(alarm: alarm(at: indexPath))
    }
    
    func moveAlarm(from originalIndextPath: IndexPath, to targetIndexPath: IndexPath) {
        let alarm = alarms.remove(at: originalIndextPath.row)
        alarms.insert(alarm, at: targetIndexPath.row)
        tableView.reloadData()
    }
    
    func alarmCell(_ cell: AlarmTableViewCell, enabledChanged enabled: Bool) {
        if let indexPath = tableView.indexPath(for: cell) {
            if let alarm = alarm(at: indexPath) {
                alarm.enabled = enabled
                alarm.enabled ? appDelegate?.manageSettingUpLocalNotificationFor(alarm) : appDelegate?.removePendingNotificationFor(alarmID: alarm.dateID!)

                addOrEdit(alarm, at: indexPath)
            }
        }
    }
    
    private func presentAlarmViewController(alarm: Alarm?) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let popupViewController = storyboard.instantiateViewController(withIdentifier: "DetailNavigationController") as! UINavigationController
        let settingAlarmViewController = popupViewController.viewControllers[0] as! SettingAlarmViewController
        settingAlarmViewController.alarm = alarm
        settingAlarmViewController.delegate = self
        present(popupViewController, animated: true, completion: nil)
    }
    
    func alarmViewControllerDone(alarm: Alarm) {
        // if it was editing existent alarm
        if let editingIndexPath = editingIndexPath {
            appDelegate?.manageSettingUpLocalNotificationFor(alarm)
            addOrEdit(alarm, at: editingIndexPath)
            loadAlarmsFromCoreDataAndPopulateTableView()
        }
        // if it was adding new alarm
        else {
            alarm.dateID = appDelegate?.stringFrom(Date())
            appDelegate?.manageSettingUpLocalNotificationFor(alarm)
            addOrEdit(alarm)
            loadAlarmsFromCoreDataAndPopulateTableView()
        }
        editingIndexPath = nil
    }
    
    func alarmViewControllerCancel() {
        editingIndexPath = nil
    }
    
    // MARK: - CoreData functionality
    func addOrEdit(_ alarm: Alarm, at indexPath: IndexPath? = nil) {
            // if it was editing existent alarm
            if indexPath != nil {
                if let alarmToEdit = ManagingData.shared.fetchedRC?.object(at: indexPath!) {
                    alarmToEdit.time = Int32(alarm.time)
                    alarmToEdit.repeatSun = alarm.repeatDays[0]
                    alarmToEdit.repeatMon = alarm.repeatDays[1]
                    alarmToEdit.repeatTue = alarm.repeatDays[2]
                    alarmToEdit.repeatWed = alarm.repeatDays[3]
                    alarmToEdit.repeatThu = alarm.repeatDays[4]
                    alarmToEdit.repeatFri = alarm.repeatDays[5]
                    alarmToEdit.repeatSat = alarm.repeatDays[6]
                    alarmToEdit.enabled   = alarm.enabled
                    // CreationDate is used as an alarm identifier
                    ManagingData.shared.appDelegate.saveContext()
                }
                // if it was adding new alarm
            } else {
                let newAlarm = AlertRing(entity: AlertRing.entity(), insertInto: ManagingData.shared.context)
                newAlarm.time = Int32(alarm.time)
                newAlarm.repeatSun = alarm.repeatDays[0]
                newAlarm.repeatMon = alarm.repeatDays[1]
                newAlarm.repeatTue = alarm.repeatDays[2]
                newAlarm.repeatWed = alarm.repeatDays[3]
                newAlarm.repeatThu = alarm.repeatDays[4]
                newAlarm.repeatFri = alarm.repeatDays[5]
                newAlarm.repeatSat = alarm.repeatDays[6]
                newAlarm.enabled   = alarm.enabled
                // CreationDate is used as an alarm identifier for setting up unique notification
                newAlarm.creationDateID = alarm.dateID!
                
                ManagingData.shared.appDelegate.saveContext()
            }
        }
    
    func loadAlarmsFromCoreDataAndPopulateTableView() {
        alarms.removeAll()
        ManagingData.shared.refresh()
        
        // If app opens for the first time populate with two standard alarms
        if ManagingData.shared.fetchedRC.fetchedObjects == [] {
            populateAlarms()
        }
        
        guard let savedAlarms = ManagingData.shared.fetchedRC.fetchedObjects else {return}
        
        for i in savedAlarms {
            let alarm = Alarm()
            alarm.time = Int(i.time)
            alarm.enabled = i.enabled
            alarm.repeatDays = [i.repeatSun, i.repeatMon, i.repeatTue, i.repeatWed, i.repeatThu, i.repeatFri, i.repeatSat]
            alarm.dateID = i.creationDateID
            alarms.append(alarm)
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        // to set up notifications for the first two initial standard alarms
        if ManagingData.shared.fetchedRC.fetchedObjects?.count == 2 {
            for i in alarms {
                appDelegate?.manageSettingUpLocalNotificationFor(i)
            }
        }
    }

}

