//
//  Executions.swift
//  WakyZzz
//
//  Created by Eric Stein on 4/6/20.
//  Copyright © 2020 Olga Volkova OC. All rights reserved.
//

import Foundation

enum ActionButtonsID: String {
    case
        First_Snooze,
        Second_Snooze,
        TextToAFriend,
        TextToFamily,
        DoItLaterTask,
        DeleteAlarmTask,
        TaskAllCompleted,
        Delay
}

enum ActionButtonsTitle: String {
    case
        Snooze,
        Delete,
        SnoozeRepeat = "Snooze Repeat",
        messageFriend = "message a friend",
        messageFamily = "message a family member",
        delayTask = "Do it later",
        taskComplete = "Task completed",
        delayTaskAgain = "Proscrastinator!"
}

enum AlarmSoundNames: String {
    case
        firstAlarmSound = "primarySound.mp3",
        secondAlarmSound = "secondSound.mp3",
        frighteningSound = "frighteningSound.mp3"
}
