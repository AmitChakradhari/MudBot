//
//  Utility.swift
//  MudBot
//
//  Created by Amit  Chakradhari on 02/04/21.
//  Copyright © 2021 Amit  Chakradhari. All rights reserved.
//

import Foundation
import MessageKit

final internal class Utility {
    
    static let shared = Utility()
    
    var now = Date()
    
    func dateAddingRandomTime() -> Date {
        let randomNumber = Int(arc4random_uniform(UInt32(10)))
        if randomNumber % 2 == 0 {
            let date = Calendar.current.date(byAdding: .hour, value: randomNumber, to: now)!
            now = date
            return date
        } else {
            let randomMinute = Int(arc4random_uniform(UInt32(59)))
            let date = Calendar.current.date(byAdding: .minute, value: randomMinute, to: now)!
            now = date
            return date
        }
    }
    
    //    func getMessages(count: Int, completion: ([MessageType]) -> Void) {
    //        var messages: [MessageType] = []
    //        // Disable Custom Messages
    //        UserDefaults.standard.set(false, forKey: "Custom Messages")
    //        for _ in 0..<count {
    //            let uniqueID = UUID().uuidString
    //            let user = senders[0]
    //            let date = dateAddingRandomTime()
    //            let message = MockMessage(text: "randomSentence", user: user, messageId: uniqueID, date: date)
    //            messages.append(message)
    //        }
    //        completion(messages)
    //    }
    
    func getAvatarFor(sender: SenderType) -> Avatar {
        let firstName = sender.displayName.components(separatedBy: " ").first
        let lastName = sender.displayName.components(separatedBy: " ").last
        let initials = "\(firstName?.first ?? "A")\(lastName?.first ?? "A")"
        switch sender.senderId {
        default:
            return Avatar(image: nil, initials: initials)
        }
    }

}

