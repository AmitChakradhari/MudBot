//
//  ChatViewController.swift
//  MudBot
//
//  Created by Amit  Chakradhari on 02/04/21.
//  Copyright © 2021 Amit  Chakradhari. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import CoreData

class ChatViewController: MessagesViewController, MessagesDataSource {
    
    // MARK: - Public properties
        
    lazy var messageList: [MessageType] = []
    
    var savedMessages: [SavedMessage] = []
    var pendingMessages: [PendingMessage] = []
    
    let selfId = "10000"
    let otherUserId = "63906"
    
    var currentUser: Sender! = nil
    var otherUser: Sender! = nil
        
    var managedObjectContext: NSManagedObjectContext!
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        return control
    }()
    
    // MARK: - Private properties
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMessageCollectionView()
        configureMessageInputBar()
        title = "Chatbot"
        
        currentUser = Sender(senderId: selfId, displayName: "Amit Chakradhari")
        otherUser = Sender(senderId: otherUserId, displayName: "Cyber Ty")
        
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        loadDataFromStore()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        MockSocket.shared.connect(with: [SampleData.shared.nathan, SampleData.shared.wu])
//            .onNewMessage { [weak self] message in
//                self?.insertMessage(message)
//        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func loadMoreMessages() {
//        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {
//            SampleData.shared.getMessages(count: 5) { messages in
//                DispatchQueue.main.async {
//                    self.messageList.insert(contentsOf: messages, at: 0)
//                    self.messagesCollectionView.reloadDataAndKeepOffset()
//                    self.refreshControl.endRefreshing()
//                }
//            }
//        }
    }
    
    func configureMessageCollectionView() {
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        showMessageTimestampOnSwipeLeft = true // default false
        
        messagesCollectionView.refreshControl = refreshControl
    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = .black
        messageInputBar.sendButton.setTitleColor(
            UIColor.blue.withAlphaComponent(0.3),
            for: .highlighted
        )
    }
    
    // MARK: - Helpers
    
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
    
    // MARK: - MessagesDataSource
    
    func currentSender() -> SenderType {
        return currentUser
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: "Read", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
}

// MARK: - MessageCellDelegate

extension ChatViewController: MessageCellDelegate, MessageLabelDelegate {
}

// MARK: - MessageInputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }
    
    func processInputBar(_ inputBar: InputBarAccessoryView) {
        
        let components = inputBar.inputTextView.components
        
        guard components.count > 0, let messageString = components.first as? String else { return }
        
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        // Send button activity animation
        inputBar.sendButton.startAnimating()
        inputBar.inputTextView.placeholder = "Sending..."
        // Resign first responder for iPad split view
        inputBar.inputTextView.resignFirstResponder()
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            DispatchQueue.main.async { [weak self] in
                inputBar.sendButton.stopAnimating()
                inputBar.inputTextView.placeholder = "Aa"
                self?.saveMessageToStore(message: messageString, senderId: Int32(self!.selfId) ?? 0)
                self?.insertMessages(sender: self!.currentUser, messageString: messageString)
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
            
            NetworkWorker.sendMessage(message: messageString) { messageResponse in
                guard let messageResponse = messageResponse else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.saveMessageToStore(message: messageResponse.message.message, senderId: Int32(self!.otherUserId) ?? 0)
                    self?.insertMessages(sender: self!.otherUser, messageString: messageResponse.message.message)
                    self?.messagesCollectionView.scrollToLastItem(animated: true)
                }
            }
        }
    }
    
    private func insertMessages(sender: SenderType, messageString: String) {
        let message = Message(sender: sender, messageId: UUID().uuidString, sentDate: Date(), kind: .text(messageString))
        insertMessage(message)
    }
}

extension ChatViewController {
    
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
}
