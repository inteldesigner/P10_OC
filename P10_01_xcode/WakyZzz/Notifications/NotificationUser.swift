//
//  NotificationDelegate.swift
//  WakyZzz
//
//  Created by Eric Stein on 4/7/20.
//  Copyright © 2020 Olga Volkova OC. All rights reserved.
//

import UIKit
import UserNotifications
//
extension AppDelegate {
    // this block of code only runs when app is running in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // calling completion handler to specify how I want the system to alert the user
        defer { completionHandler([.alert, .sound]) }
        // update alarm to turn off enabled attribute if it was a one time alarm
        fetchStoredObjectAndUpdate(notification.request.identifier)
        // after updating the persisted object we need to loadAlarms to reflect changes in UI
        ((window!.rootViewController as? UINavigationController)?.topViewController as? AlarmsViewController)?.loadAlarmsFromCoreDataAndPopulateTableView()
    }
    
    // process the user's response to a delivered notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // calling the completionHandler block to let the system know that we are done processing the user's response. If we do not implement this method, our app never responds to custom actions.
        defer { completionHandler() }
        // The runtime state of the app.
        reactBasedOnTheRunTimeStateOfApp(requestID: response.notification.request.identifier)
        
        // Handling UINotificationActions to perform the task associated with the action.
        switch response.actionIdentifier {
        case ActionButtonsID.First_Snooze.rawValue:
            actionButtonPressed(timeInterval: 60,
                                subtitle: "Waky wakyZzz",
                                body: "Alarm set for \(response.notification.request.content.categoryIdentifier)",
                contentIdentifier: response.notification.request.identifier,
                sound: AlarmSoundNames.secondAlarmSound.rawValue,
                firstActionID: ActionButtonsID.Second_Snooze.rawValue,
                firstActionTitle: ActionButtonsTitle.SnoozeRepeat.rawValue,
                deleteActionID: ActionButtonsID.DeleteAlarmTask.rawValue,
                deleteActionTitle: ActionButtonsTitle.Delete.rawValue,
                time: response.notification.request.content.categoryIdentifier)
            break
            
        case ActionButtonsID.Second_Snooze.rawValue:
            actionButtonPressed(timeInterval: 60,
                                subtitle: "\(response.notification.request.content.categoryIdentifier)",
                body: "NOW You have got to complete a task: \n Either text a friend \n Or Send a family member a kind thought",
                contentIdentifier: response.notification.request.identifier,
                sound: AlarmSoundNames.frighteningSound.rawValue,
                firstActionID: ActionButtonsID.TextToAFriend.rawValue,
                firstActionTitle: ActionButtonsTitle.messageFriend.rawValue,
                secondActionID: ActionButtonsID.TextToFamily.rawValue,
                secondActionTitile: ActionButtonsTitle.messageFamily.rawValue,
                deleteActionID: ActionButtonsID.DoItLaterTask.rawValue,
                deleteActionTitle: ActionButtonsTitle.delayTask.rawValue,
                time: response.notification.request.content.categoryIdentifier)
            break
            
        case ActionButtonsID.TextToAFriend.rawValue:
            sendKindThought(to: ActionButtonsID.TextToAFriend.rawValue)
            break
            
        case ActionButtonsID.TextToFamily.rawValue:
            sendKindThought(to: ActionButtonsID.TextToFamily.rawValue)
            break
            
        case ActionButtonsID.DoItLaterTask.rawValue:
            actionButtonPressed(timeInterval: TimeInterval(Int.random(in: 7200...14400)),
                                subtitle: "Have you completed the task yet?",
                                body: "You promissed to complete a task for snoozing your alarm set for \(response.notification.request.content.categoryIdentifier).",
                contentIdentifier: response.notification.request.identifier,
                sound: AlarmSoundNames.frighteningSound.rawValue,
                firstActionID: ActionButtonsID.TaskAllCompleted.rawValue,
                firstActionTitle: ActionButtonsTitle.taskComplete.rawValue,
                secondActionID: ActionButtonsID.TextToAFriend.rawValue,
                secondActionTitile: ActionButtonsTitle.messageFriend.rawValue,
                thirdActionID: ActionButtonsID.TextToFamily.rawValue,
                thirdActionTitle: ActionButtonsTitle.messageFamily.rawValue,
                deleteActionID: ActionButtonsID.Delay.rawValue,
                deleteActionTitle: ActionButtonsTitle.delayTaskAgain.rawValue,
                time: response.notification.request.content.categoryIdentifier)
            break
            
        case ActionButtonsID.DeleteAlarmTask.rawValue:
            center.removePendingNotificationRequests(withIdentifiers: [response.notification.request.identifier])
            center.removeDeliveredNotifications(withIdentifiers: [response.notification.request.identifier])
            break
            
        default:
            break
        }
    }
    
    private func reactBasedOnTheRunTimeStateOfApp(requestID: String) {
        
        let state = UIApplication.shared.applicationState
        // when the app is running in the background.
        if state == .background {
            // update alarm to turn off enabled attribute if it was a one time alarm
            fetchStoredObjectAndUpdate(requestID)
            // after updating the persisted object we need to loadAlarms to reflect changes in UI
            ((window!.rootViewController as? UINavigationController)?.topViewController as? AlarmsViewController)?.loadAlarmsFromCoreDataAndPopulateTableView()

            // when the app is running in the foreground but is not receiving events. This might happen as a result of an interruption or because the app is transitioning to or from the background.
        } else if state == .inactive {
            // update alarm to turn off enabled attribute if it was a one time alarm
            fetchStoredObjectAndUpdate(requestID)
            ((window!.rootViewController as? UINavigationController)?.topViewController as? AlarmsViewController)?.loadAlarmsFromCoreDataAndPopulateTableView()
        }
    }
    
}
