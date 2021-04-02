//
//  MockMessage.swift
//  MudBot
//
//  Created by Amit  Chakradhari on 02/04/21.
//  Copyright © 2021 Amit  Chakradhari. All rights reserved.
//

import Foundation
import UIKit
import MessageKit

internal struct MockMessage: MessageType {
    
    var messageId: String
    var sender: SenderType {
        return user
    }
    var sentDate: Date
    var kind: MessageKind
    
    var user: MockUser
    
    private init(kind: MessageKind, user: MockUser, messageId: String, date: Date) {
        self.kind = kind
        self.user = user
        self.messageId = messageId
        self.sentDate = date
    }
    
    init(custom: Any?, user: MockUser, messageId: String, date: Date) {
        self.init(kind: .custom(custom), user: user, messageId: messageId, date: date)
    }
    
    init(text: String, user: MockUser, messageId: String, date: Date) {
        self.init(kind: .text(text), user: user, messageId: messageId, date: date)
    }
}


struct MockUser: SenderType, Equatable {
    var senderId: String
    var displayName: String
}
