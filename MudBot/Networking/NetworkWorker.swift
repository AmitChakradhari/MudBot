//
//  NetworkWorker.swift
//  MudBot
//
//  Created by Amit  Chakradhari on 02/04/21.
//  Copyright © 2021 Amit  Chakradhari. All rights reserved.
//

import Foundation
import Alamofire

class NetworkWorker: NSObject {
    class func sendMessage(message: String, completion: @escaping (MessageResponse?) -> ()) {
        AF.request(ApiRouter.sendMessage(message))
            .validate(statusCode: 200..<300)
            .responseData { response in
            switch response.result {
            case .success:
                if let responseData = response.data {
                    do {
                        let messageData = try JSONDecoder().decode(MessageResponse.self, from: responseData)
                        print(messageData)
                        completion(messageData)
                    }
                    catch {
                        print("error decoding \(error.localizedDescription)")
                        completion(nil)
                    }
                }
            case let .failure(error):
                print(error)
                completion(nil)
            }
        }
    }
}

fileprivate enum ApiRouter: URLRequestConvertible {
    
    case sendMessage(String)
    
    var baseUrl: String {
        switch self {
        case .sendMessage:
            return "https://www.personalityforge.com"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .sendMessage:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .sendMessage:
            return "/api/chat/"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .sendMessage(let message):
            return [
                "apiKey": "6nt5d1nJHkqbkphe",
                "message": message,
                "chatBotID": 63906,
                "externalID": "nobody"
            ]
        }
    }
    
    public func asURLRequest() throws -> URLRequest {
        let url = try baseUrl.asURL()
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.timeoutInterval = TimeInterval(10 * 1000)
        return try URLEncoding.default.encode(request, with: parameters)
    }
}
