//
//  MultiplayerViewModel.swift
//  PirateWar (iOS)
//
//  Created by James Thang on 29/11/24.
//

import SwiftUI
import Combine
import GameKit

enum MultiplayerState: Equatable {
    case idle
    case matchmaking
    case waitingForPlayers
    case readyToStart
    case gameActive
    case error(String)
}

@MainActor
final class MultiplayerViewModel: ObservableObject {
    
    @Published var state: MultiplayerState = .idle
    @Published var connectedPlayers: [GKPlayer] = []
    @Published var counter: Int = 0

    private var isHost: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        GameKitManager.shared.$currentMatch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] match in
                guard let self = self else { return }
                if match != nil {
                    self.handleMatchStarted()
                } else {
                    self.connectedPlayers = []
                    self.state = .idle
                }
            }
            .store(in: &cancellables)

        GameKitManager.shared.$receivedData
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data, player in
                self?.handleReceivedData(data, from: player)
            }
            .store(in: &cancellables)

        GameKitManager.shared.$matchError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.state = .error(error.localizedDescription)
            }
            .store(in: &cancellables)

        GameKitManager.shared.$playerConnectionState
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] player, state in
                self?.handlePlayerConnectionState(player: player, state: state)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .matchmakingCancelled)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.state = .idle
            }
            .store(in: &cancellables)
    }

    func startMatchmaking(presentingViewController: UIViewController) {
        state = .matchmaking
        do {
            try GameKitManager.shared.findMatch(minPlayers: 2, maxPlayers: 2, viewController: presentingViewController)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func sendData(_ data: Data) {
        do {
            try GameKitManager.shared.sendData(data)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func disconnectMatch() {
        GameKitManager.shared.disconnectMatch()
        state = .idle
    }

    private func handleMatchStarted() {
        guard let match = GameKitManager.shared.currentMatch else { return }

        connectedPlayers = match.players
        let allPlayersIncludingLocal = match.players + [GKLocalPlayer.local]
        let sortedPlayers = allPlayersIncludingLocal.sorted { $0.gamePlayerID < $1.gamePlayerID }
        isHost = (sortedPlayers.first == GKLocalPlayer.local)
        state = .waitingForPlayers
        checkIfReadyToStart()
    }

    private func handleReceivedData(_ data: Data, from player: GKPlayer) {
        if let message = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let action = message["action"] as? String {
            switch action {
            case "startGame":
                state = .gameActive
            case "updateCounter":
                if let counterValue = message["counterValue"] as? Int {
                    counter = counterValue
                }
            default:
                break
            }
        }
    }

    private func handlePlayerConnectionState(player: GKPlayer, state: GKPlayerConnectionState) {
        switch state {
        case .connected:
            if !connectedPlayers.contains(where: { $0.gamePlayerID == player.gamePlayerID }) {
                connectedPlayers.append(player)
            }
        case .disconnected:
            connectedPlayers.removeAll { $0.gamePlayerID == player.gamePlayerID }
        default:
            break
        }
        // Update readiness status
        checkIfReadyToStart()
    }

    private func checkIfReadyToStart() {
        let totalPlayers = connectedPlayers.count + 1 // +1 for local player

        if totalPlayers == 2 {
            state = .readyToStart
            if isHost {
                notifyStartGame()
            }
        } else {
            if case .gameActive = state {
                state = .error("A player has disconnected.")
            } else {
                state = .waitingForPlayers
            }
        }
    }

    func notifyStartGame() {
        let message = ["action": "startGame"]
        if let data = try? JSONSerialization.data(withJSONObject: message, options: []) {
            sendData(data)
        }

        state = .gameActive
    }
    
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
    
}
