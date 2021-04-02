//
//  Model.swift
//  MudBot
//
//  Created by Amit  Chakradhari on 02/04/21.
//  Copyright © 2021 Amit  Chakradhari. All rights reserved.
//

import Foundation

struct MessageResponse: Codable {
    let success: Int
    let errorMessage: String
    let message: MessageModel
}

struct MessageModel: Codable {
    let chatBotName: String
    let chatBotID: Int
    let message: String
}
