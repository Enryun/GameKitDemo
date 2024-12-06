# Multiplayer Counter Demo with GameKit

![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)

https://github.com/user-attachments/assets/85a9807b-00bf-47da-bfe1-4e1269c08588

A simple SwiftUI multiplayer demo using GameKit, where two players can increment a counter, and the updated value is synchronized between devices in real-time.

## Table of Contents
1. [Introduction](#introduction)
2. [Features](#features)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Usage](#usage)
6. [ProjectStructure](#projectstructure)
7. [Author](#author)

## Introduction

This project demonstrates how to implement real-time multiplayer functionality in a SwiftUI app using `GameKit`. It provides a simple counter that two (or more) players can increment, and the counter value is synchronized between both players' devices. The project serves as a starting point for building more complex multiplayer games or apps.

## Features

- Real-time multiplayer using GameKit.
- Asynchronous programming with Swift's async/await.
- State management with @Published properties and ObservableObject.
- Clean and maintainable code with MVVM architecture.
- Automatic matchmaking with Game Center.
- Error handling and user feedback.
- Supports iOS 15.0 and above.

## Requirements

- Xcode 13.0 or later.
- Swift 5.9 or later.
- iOS 15.6 or later.
- Two devices or simulators signed into Game Center with different accounts.

## Installation

- Update the bundle identifier to a unique value associated with your Apple Developer account.
- Go to your project's Signing & Capabilities and set up the necessary capabilities:

<img width="1050" alt="GameKit2" src="https://github.com/user-attachments/assets/e21cc72a-ceef-4e97-8b34-3bed8783f416">

- Make sure to create the Project in AppstoreConnect and enable GameKit else it will not work in real devices:

<img width="1443" alt="GameKit3" src="https://github.com/user-attachments/assets/3bd35752-5589-4ffa-894b-0385dcd33f72">

## Usage

### Starting a Match
- Open the app on both devices or simulators.
- Initiate Matchmaking
- On each device, tap the Find Match button.
- The Game Center matchmaking UI will appear.
- Connect with Another Player

https://github.com/user-attachments/assets/85a9807b-00bf-47da-bfe1-4e1269c08588

- The matchmaking service will automatically connect the two devices.
- Once connected, the game will start automatically.
- On either device, tap the Increment Counter button.
- The updated counter value will appear on both devices.
- Repeat tapping the button on either device to continue incrementing.

Tap the End Game button to disconnect and return to the main menu.

## ProjectStructure

### Models
- `MultiplayerState`: Enum representing the different states of the multiplayer session.
- `AuthenticationError`: Enum for handling authentication-related errors.

### ViewModels
- `MultiplayerViewModel`: Manages the game logic, state transitions, and communication with GameKitManager.

```swift
@MainActor
final class MultiplayerViewModel: ObservableObject {

    @Published var state: MultiplayerState = .idle
    @Published var connectedPlayers: [GKPlayer] = []
    @Published var counter: Int = 0
    private var isHost: Bool = false

    // Initialization and subscriptions...

    func incrementCounter() {
        counter += 1
        sendCounterUpdate()
    }

    private func sendCounterUpdate() {
        let messageData = [
            "action": "updateCounter",
            "counterValue": counter
        ] as [String : Any]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: messageData, options: [])
            sendData(data)
        } catch {
            state = .error("Failed to send counter update: \(error.localizedDescription)")
        }
    }

    // Other methods...
}
```

### Views
`MultiplayerView`: The main SwiftUI view that updates based on the MultiplayerViewModel's state.

### Managers
`GameKitManager`: Handles all Game Center-related functionality, including authentication, matchmaking, and data transmission.

```swift
final class GameKitManager: NSObject, ObservableObject {

    static let shared = GameKitManager()
    
    // Authentication Properties
    @Published private(set) var isAuthenticated: Bool = GKLocalPlayer.local.isAuthenticated
    @Published var authenticationError: AuthenticationError?
    @Published var authenticationViewController: UIViewController?

    // Multiplayer Properties
    @Published var currentMatch: GKMatch?
    @Published var matchError: Error?
    @Published var receivedData: (data: Data, player: GKPlayer)?
    @Published var playerConnectionState: (player: GKPlayer, state: GKPlayerConnectionState)?

    func findMatch(minPlayers: Int, maxPlayers: Int, viewController: UIViewController) throws {
        guard isAuthenticated else {
            throw AuthenticationError.custom(message: "Local player is not authenticated. Please sign in to Game Center.")
        }
        
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        
        let mmvc = GKMatchmakerViewController(matchRequest: request)
        mmvc?.matchmakerDelegate = self
        
        if let mmvc {
            viewController.present(mmvc, animated: true)
        }
    }
    
    func sendData(_ data: Data, mode: GKMatch.SendDataMode = .reliable) throws {
        guard let match = currentMatch else {
            throw NSError(domain: "No active match", code: 0, userInfo: nil)
        }
        
        try match.sendData(toAllPlayers: data, with: mode)
    }
    
    func disconnectMatch() {
        currentMatch?.disconnect()
        currentMatch = nil
    }
    // Other methods...
}
```

## Author

James Thang, find me on [LinkedIn](https://www.linkedin.com/in/jamesthang/)

Learn more about SwiftUI, check out my book :books: on [Amazon](https://www.amazon.com/Ultimate-SwiftUI-Handbook-iOS-Developers-ebook/dp/B0CKBVY7V6/ref=tmm_kin_swatch_0?_encoding=UTF8&qid=1696776124&sr=8-1)
