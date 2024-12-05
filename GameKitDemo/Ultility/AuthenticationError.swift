//
//  AuthenticationError.swift
//  GameKitDemo
//
//  Created by James Thang on 5/12/24.
//

import UIKit

enum AuthenticationError: LocalizedError {
    
    case requiresPresentation(UIViewController)
    case unknown
    case custom(message: String)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .requiresPresentation:
            return "Authentication is required. Please sign in to Game Center."
        case .unknown:
            return "An unknown error occurred during authentication."
        case .custom(let message):
            return message
        case .cancelled:
            return "Authentication was cancelled."
        }
    }
    
}
