//
//  Notification.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 11.11.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import UserNotifications
func showLocalNotification(identifier:String, title:String,body:String){
    notificationCenter.getNotificationSettings { (settings) in
        if settings.authorizationStatus != .authorized {
            print("Notifications not allowed")
            return
        }
    }
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01,
                                                    repeats: false)
    let identifier = identifier
    let request = UNNotificationRequest(identifier: identifier,
                                        content: content, trigger: trigger)
    notificationCenter.add(request, withCompletionHandler: { (error) in
        if error != nil {
            print(error)
            // Something went wrong
        }
    })
}
