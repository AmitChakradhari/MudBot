//
//  ViewController.swift
//  MudBot
//
//  Created by Amit  Chakradhari on 01/04/21.
//  Copyright © 2021 Amit  Chakradhari. All rights reserved.
//

import UIKit
import MessageKit

struct Sender: SenderType {
    var senderId: String
    
    var displayName: String
}

struct Message: MessageType {
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
}

class ViewController: MessagesViewController {
    
    var messages = [MessageType]()
    let currentUser = Sender(senderId: "1000", displayName: "Amit")
    let otherUser = Sender(senderId: "1001", displayName: "Chatbot")
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.becomeFirstResponder()
        messagesCollectionView.dataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messages.append(Message(sender: currentUser,
                    messageId: "1",
                    sentDate: Date().addingTimeInterval(-846000),
                    kind: .text("Hi")))
        messages.append(Message(sender: otherUser,
                                messageId: "2",
                                sentDate: Date().addingTimeInterval(-746000),
                                kind: .text("Hi wassup")))
        messages.append(Message(sender: currentUser,
                                messageId: "3",
                                sentDate: Date().addingTimeInterval(-646000),
                                kind: .text("All good, Isn't the weather nice?")))
        messages.append(Message(sender: otherUser,
                                messageId: "4",
                                sentDate: Date().addingTimeInterval(-546000),
                                kind: .text("You're goddamn right!")))
        messages.append(Message(sender: currentUser,
                                messageId: "5",
                                sentDate: Date().addingTimeInterval(-446000),
                                kind: .text("You should add Always")))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.messagesCollectionView.reloadData()
        })
    }
}

extension ViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate {
    func currentSender() -> SenderType {
        currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 18
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 17
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
}
