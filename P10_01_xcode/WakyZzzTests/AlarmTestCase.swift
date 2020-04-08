//
//  AlarmTestCase.swift
//  WakyZzzTests
//
// Created by Eric Stein on 4/8/20.
//  Copyright © 2020 Olga Volkova OC. All rights reserved.
//

import XCTest
@testable import WakyZzz

class AlarmTestCase: XCTestCase {

    var alarm = Alarm()
    let NC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainNavigationController") as! UINavigationController
    var center = UNUserNotificationCenter.current()
    var appDelegate = UIApplication.shared.delegate as? AppDelegate

    // MARK: - Helping elements
    func removeAllStoredAlarms() {
        ManagingData.shared.refresh()
        guard let allStoredAlarms = ManagingData.shared.fetchedRC.fetchedObjects else { return }
        for alarm in allStoredAlarms {
            ManagingData.shared.context.delete(alarm)
        }
        ManagingData.shared.appDelegate.saveContext()
    }
    
    func removeAllPendingAndDeliveredNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    // MARK: - Tests
    func CreatingAlarm() {
        // 1.1 given
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .month, .year, .day, .second, .weekOfMonth], from: date as Date)
        
        print("Alarm setTime function")
        // 1.2 when
        alarm.setTime(date: date)
        // 1.3 then
        XCTAssertEqual(alarm.time, components.hour! * 3600 + components.minute! * 60)
        
        print("Alarm alarmDate computed variable")
        // 2.2 when
        let alarmDate = alarm.alarmDate
        // 2.3 then
        XCTAssertEqual(alarmDate, calendar.date(from: components))
        
        print("Alarm caption computed variable")
        // 3.2 when
        let caption = alarm.caption
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        // 3.3 then
        XCTAssertEqual(caption, formatter.string(from: alarmDate!))
        
        print("Alarm repeating computed variable")
        // 4.2 when
        for i in 0..<alarm.repeatDays.count {
            alarm.repeatDays[i] = true
        }
        // 4.3 then
        XCTAssertEqual(alarm.repeating, "Sun, Mon, Tue, Wed, Thu, Fri, Sat", "This should be a repeated alarm")
        // 5.2 when
        for i in 0..<alarm.repeatDays.count {
            alarm.repeatDays[i] = false
        }
        // 5.3 then
        XCTAssertEqual(alarm.repeating, "One time alarm", "This should be a one time alarm")

    }
    
    func PersitingAndFetchingAlarm() {
        let sut = NC.viewControllers[0] as! AlarmsViewController
        // 1.1 given
        alarm.dateID = appDelegate?.stringFrom(Date())
        print("Persisting and fetching alarm")
        // 1.2 when
        sut.addOrEdit(alarm)
        let storedAlarm = ManagingData.shared.fetchAlarm(with: alarm.dateID!)
        // 1.3 then
        XCTAssertNotNil(storedAlarm)
        
        ManagingData.shared.refresh()
        let allStoredAlarms = ManagingData.shared.fetchedRC.fetchedObjects
        // 2.3 then
        XCTAssertEqual(allStoredAlarms?.count, 1)
        // 3.3 then
        XCTAssertEqual(storedAlarm?.time, Int32(alarm.time))
        // 4.3 then
        XCTAssertEqual(storedAlarm?.creationDateID, alarm.dateID)
        
        XCTAssertEqual(storedAlarm?.enabled, true)
        
        let storedAlarmRepeatDays = [storedAlarm?.repeatSun, storedAlarm?.repeatMon, storedAlarm?.repeatTue, storedAlarm?.repeatWed, storedAlarm?.repeatThu, storedAlarm?.repeatFri, storedAlarm?.repeatSat]
        // 5.3 then
        XCTAssertEqual(storedAlarmRepeatDays, alarm.repeatDays)
        
    }
    
    func addingNotifications() {
        print("Adding notifications")
        // 1.2 when
        appDelegate?.manageSettingUpLocalNotificationFor(alarm)
        // 1.3 then
        center.getPendingNotificationRequests { (notifications) in
            XCTAssertEqual(notifications.count, 1)
            XCTAssertEqual(notifications.first?.identifier, self.alarm.dateID)
        }
        // 2.2 when
        appDelegate?.fetchStoredObjectAndUpdate(alarm.dateID!)
        // 2.3 then
        let storedAlarm = ManagingData.shared.fetchAlarm(with: alarm.dateID!)
        XCTAssertEqual(storedAlarm?.enabled, false)

    }
    
    func removeNotifications() {
        print("Removing notifications")
        // when
        center.removeAllPendingNotificationRequests()
        // then
        center.getPendingNotificationRequests { (notifications) in
            XCTAssertEqual(notifications.count, 0)
        }
                
    }
    
    func runTestInOrder() {
        removeAllStoredAlarms()
        removeAllPendingAndDeliveredNotifications()
        CreatingAlarm()
        PersitingAndFetchingAlarm()
        addingNotifications()
        removeNotifications()
        removeAllStoredAlarms()
        removeAllPendingAndDeliveredNotifications()
    }
    
}
