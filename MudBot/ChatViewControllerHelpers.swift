//
//  ChatViewControllerHelpers.swift
//  MudBot
//
//  Created by Amit  Chakradhari on 03/04/21.
//  Copyright © 2021 Amit  Chakradhari. All rights reserved.
//
import Foundation
import MessageKit
import CoreData

extension ChatViewController {
    // MARK: - Helpers
    
    func insertMessages(sender: SenderType, messageString: String) {
        let message = Message(sender: sender, messageId: UUID().uuidString, sentDate: Date(), kind: .text(messageString))
        insertMessage(message)
    }
    
    func insertMessage(_ message: MessageType) {
        messageList.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messageList.count - 1])
            if messageList.count >= 2 {
                messagesCollectionView.reloadSections([messageList.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        })
    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !messageList.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messageList.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    func loadDataFromStore(){
        let presentRequest: NSFetchRequest<SavedMessage> = SavedMessage.fetchRequest()
        do {
            savedMessages = try  managedObjectContext.fetch(presentRequest)
            loadSavedMessages(savedMessages: savedMessages)
            // filter messages based on date and insert them
        }catch{
            print("error retriving from core data: \(error.localizedDescription)")
        }
    }
    
    func saveMessageToStore(message: String, senderId: Int32) {
        let newMessage = SavedMessage(context: managedObjectContext)
        newMessage.message = message
        newMessage.senderId = senderId
        newMessage.sentDate = Date()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.saveContext()
    }
    
    func savePendingMessageToStore(message: String, senderId: Int32) {
        let newMessage = PendingMessage(context: managedObjectContext)
        newMessage.message = message
        newMessage.senderId = senderId
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.saveContext()
    }
    
    func loadSavedMessages(savedMessages: [SavedMessage]) {
        self.messageList = savedMessages.map { savedMessage in
            let user: Sender = [currentUser, otherUser].filter { user in
                return user?.senderId == String(savedMessage.senderId)
            }.first!
            return Message(sender: user,
                           messageId: UUID().uuidString,
                           sentDate: savedMessage.sentDate ?? Date(),
                           kind: .text(savedMessage.message ?? ""))
        }
        self.messagesCollectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            self.messagesCollectionView.scrollToLastItem()
        })
    }
    
    func sendPendingMessages() {
        let presentRequest: NSFetchRequest<PendingMessage> = PendingMessage.fetchRequest()
        do {
            pendingMessages = try  managedObjectContext.fetch(presentRequest)
            if pendingMessages.count > 0 {
                // send messages one by one and delete that message from pending messages
                sendPendingMessage(message: pendingMessages[0])
            }
        } catch {
            print("error retriving pending messages from core data: \(error.localizedDescription)")
        }
    }
    
    func sendPendingMessage(message: PendingMessage) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            NetworkWorker.sendMessage(message: message.message ?? "") { messageResponse in
                guard let messageResponse = messageResponse else { return }
                DispatchQueue.main.async { [weak self] in
                    
                    //remove message from coredata
                    self?.managedObjectContext.delete(message)
                    
                    self?.saveMessageToStore(message: messageResponse.message.message, senderId: Int32(self!.otherUserId) ?? 0)
                    self?.insertMessages(sender: self!.otherUser, messageString: messageResponse.message.message)
                    self?.messagesCollectionView.scrollToLastItem(animated: true)
                    self?.sendPendingMessages()
                }
            }
        }
    }
}
