//
//  AppDelegateNotificationExtension.swift
//  WakyZzz
//
//  Created by Eric Stein on 4/7/20.
//  Copyright © 2020 Olga Volkova OC. All rights reserved.
//

import UIKit
import UserNotifications

extension AppDelegate {
    // helper method to create alarm creation ID
    func stringFrom(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMddyyyyhhmmss"
        return formatter.string(from: date)
    }
    
    func manageSettingUpLocalNotificationFor(_ alarm: Alarm) {
        let date = alarm.alarmDate
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date!)
        let minute = calendar.component(.minute, from: date!)
        // getting the week number to set up a one time alarm
        let weekDay = calendar.component(.weekday, from: date!)
        
        if alarm.repeating == "One time alarm" {
            schedualeLocalNotification(time: alarm.caption, hour: hour, minute: minute, weekDay: weekDay, body: alarm.caption, contentIdentifier: alarm.dateID!)
        } else {
            for weekDay in 1...alarm.repeatDays.count {
                if alarm.repeatDays[weekDay-1] == true {
                    schedualeLocalNotification(time: alarm.caption, hour: hour, minute: minute, weekDay: weekDay, body: alarm.caption, contentIdentifier: alarm.dateID! + "\(weekDay)")
                }
            }
        }
    }
    
    func schedualeLocalNotification(time: String, hour: Int, minute: Int, weekDay: Int, body: String, contentIdentifier: String) {
        let identifier = contentIdentifier
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "WakyZzz"
        content.subtitle = "This is the alarm you set to wake up and act"
        content.body = body
        let categoryIdentifier = time
        // The system uses the category identifier to look up our app's registered categories and their associated actions. It then uses that information to add the action buttons to the notification interface.
        content.categoryIdentifier = categoryIdentifier
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: AlarmSoundNames.firstAlarmSound.rawValue))
        // create rquest
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.weekday = weekDay
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
        
        // Define the custom actions.
        let snoozeAction = UNNotificationAction(identifier: ActionButtonsID.First_Snooze.rawValue, title: ActionButtonsTitle.Snooze.rawValue, options: [])
        let deleteAction = UNNotificationAction(identifier: ActionButtonsID.DeleteAlarmTask.rawValue, title: ActionButtonsTitle.Delete.rawValue, options: .destructive)
        // Define the notification type.
        let category = UNNotificationCategory(identifier: categoryIdentifier, actions: [snoozeAction, deleteAction], intentIdentifiers: [])
        // Register the notification type.
        center.setNotificationCategories([category])
    }
    
    func removePendingNotificationFor(alarmID: String) {
        center.getPendingNotificationRequests { requests in
            for request in requests {
                // using contains here because repeated alarms in multiple days differs by the number of the week in the notification request identifier, it doesn't have to match exactly so we can get hold of the repeated alarm
                if request.identifier.contains(alarmID) {
                    self.center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
                    // and also remove its delivered notifications
                    self.center.removeDeliveredNotifications(withIdentifiers: [request.identifier])
                }
            }
        }
    }
    // This method to update alarm to turn off enabled attribute if it was a one time alarm
    func fetchStoredObjectAndUpdate(_ alarmCreationID: String) {
        if let alarm = ManagingData.shared.fetchAlarm(with: alarmCreationID) {
            let repeatDays = [alarm.repeatSun, alarm.repeatMon, alarm.repeatTue, alarm.repeatWed, alarm.repeatThu, alarm.repeatFri, alarm.repeatSat]
            if repeatDays.filter({$0 == true}).count == 0 {
                alarm.enabled = false
                ManagingData.shared.appDelegate.saveContext()
            }
        }
    }
    
    func actionButtonPressed(timeInterval: TimeInterval, subtitle: String, body: String, contentIdentifier: String, sound: String, firstActionID: String, firstActionTitle: String, secondActionID: String? = nil, secondActionTitile: String? = nil, thirdActionID: String? = nil, thirdActionTitle: String? = nil, deleteActionID: String, deleteActionTitle: String, time: String) {
        //creating the notification content
        let content = UNMutableNotificationContent()
        let categoryIdentifier = time
        
        //adding title, subtitle, body
        content.title = "WakyZzz"
        content.subtitle = subtitle
        content.body = body
        content.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: sound))
        content.categoryIdentifier = categoryIdentifier
        
        let identifier = contentIdentifier
        // The time/repeat trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        //getting the notification request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
        
        var catagoryArray: [UNNotificationAction] = []
        let firstAction = UNNotificationAction(identifier: firstActionID, title: firstActionTitle, options: [])
        catagoryArray.append(firstAction)
        if secondActionID != nil {
            let secondAction = UNNotificationAction(identifier: secondActionID!, title: secondActionTitile!, options: [])
            catagoryArray.append(secondAction)
        }
        if thirdActionID != nil {
            let thirdAction = UNNotificationAction(identifier: thirdActionID!, title: thirdActionTitle!, options: [])
            catagoryArray.append(thirdAction)
        }
        
        let deleteAction = UNNotificationAction(identifier: deleteActionID, title: deleteActionTitle, options: [.destructive])
        catagoryArray.append(deleteAction)
        
        let category = UNNotificationCategory(identifier: categoryIdentifier,
                                              actions: catagoryArray,
                                              intentIdentifiers: [],
                                              options: [])
        center.setNotificationCategories([category])
    }
    
    func sendKindThought(to: String) {
        var smsBody = ""
        
        switch to {
        case ActionButtonsID.TextToAFriend.rawValue:
            smsBody = Messages.sendingTexts.randomElement()!
        case ActionButtonsID.TextToFamily.rawValue:
            smsBody = Messages.sendingPositiveToughts.randomElement()!
        default:
            break
        }
        // open sms app on the iphone and fill it with predetermined example of kind thoughts
        let sms: String = "sms:?&body=\(smsBody)"
        let strURL: String = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        UIApplication.shared.open(URL.init(string: strURL)!, options: [:], completionHandler: nil)
    }
    
}
