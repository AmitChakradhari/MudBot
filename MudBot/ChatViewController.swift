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
import Network

class ChatViewController: MessagesViewController, MessagesDataSource {
    
    // MARK: - Public properties
        
    let queue = DispatchQueue(label: "NetworkMonitor")
    
    lazy var messageList: [MessageType] = []
    
    var savedMessages: [SavedMessage] = []
    var pendingMessages: [PendingMessage] = []
    
    let selfId = "10000"
    let otherUserId = "63906"
    
    var currentUser: Sender! = nil
    var otherUser: Sender! = nil
    
    var isConnectedToInternet: Bool = false {
        didSet {
            if isConnectedToInternet {
                sendPendingMessages()
            }
        }
    }
        
    var managedObjectContext: NSManagedObjectContext!
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
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
        
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.isConnectedToInternet = true
            } else {
                self.isConnectedToInternet = false
            }
        }
        monitor.start(queue: queue)
        
        configureMessageCollectionView()
        configureMessageInputBar()
        title = "Chatbot"
        
        currentUser = Sender(senderId: selfId, displayName: "Amit Chakradhari")
        otherUser = Sender(senderId: otherUserId, displayName: "Cyber Ty")
        
        loadDataFromStore()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
                guard let self = self else {return}
                inputBar.sendButton.stopAnimating()
                inputBar.inputTextView.placeholder = "Aa"
                if !self.isConnectedToInternet {
                    self.savePendingMessageToStore(message: messageString, senderId: Int32(self.selfId) ?? 0)
                }
                self.saveMessageToStore(message: messageString, senderId: Int32(self.selfId) ?? 0)
                self.insertMessages(sender: self.currentUser, messageString: messageString)
                self.messagesCollectionView.scrollToLastItem(animated: true)
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
}
