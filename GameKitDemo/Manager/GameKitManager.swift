//
//  GameLeaderBoardManager.swift
//  SudokuAR
//
//  Created by James Thang on 25/10/24.
//

import GameKit
import Combine

final class GameKitManager: NSObject, ObservableObject {

    // Singleton instance
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

    private var cancellables = Set<AnyCancellable>()

    // Private initializer to prevent instantiation from other classes
    private override init() {
        super.init()
        setupAuthenticationHandler()
        setupAuthenticatationStatusObserver()
    }
    
    private func setupAuthenticationHandler() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            if let error {
                self.authenticationError = AuthenticationError.custom(message: error.localizedDescription)
            } else if let viewController {
                // Need to present view controller
                self.authenticationViewController = viewController
                // You may need to notify the view model or set a flag here
            } else if localPlayer.isAuthenticated {
                self.isAuthenticated = true
                self.authenticationError = nil
                self.authenticationViewController = nil
            } else {
                self.isAuthenticated = false
                self.authenticationError = AuthenticationError.unknown
            }
        }
    }
    
    private func setupAuthenticatationStatusObserver() {
        NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
            .store(in: &cancellables)
    }
    
}

//MARK: - Leader Board

extension GameKitManager {
    
    // MARK: - Score Reporting
    
    /// Reports the player's score to Game Center.
    /// - Parameters:
    ///   - score: The score to report.
    ///   - leaderboardID: The identifier of the leaderboard.
    func reportScore(score: Int, leaderboardID: String) async throws {
        try await GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        )
    }
    
    // MARK: - Display Leaderboard
    
    /// Presents the Game Center leaderboard interface.
    /// - Parameters:
    ///   - leaderboardID: The identifier of the leaderboard.
    ///   - viewController: The view controller used to present the Game Center view controller.
    func presentLeaderboard(leaderboardID: String, in viewController: UIViewController) {
        let gcViewController = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        gcViewController.gameCenterDelegate = self
        viewController.present(gcViewController, animated: true)
    }

}

// MARK: - GKGameCenterControllerDelegate

extension GameKitManager: GKGameCenterControllerDelegate {
    
    /// Dismisses the Game Center view controller when done.
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
    
}

// MARK: - GKMatchmakerViewControllerDelegate

extension GameKitManager: GKMatchmakerViewControllerDelegate {
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .matchmakingCancelled, object: nil)
        }
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true)
        self.matchError = error
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        viewController.dismiss(animated: true)
        self.currentMatch = match
        match.delegate = self
    }
    
}

//MARK: - GKMatchDelegate

extension GameKitManager: GKMatchDelegate {

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        self.receivedData = (data, player)
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        self.playerConnectionState = (player, state)
    }

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        if let error {
            self.matchError = error
        }
    }

}

//MARK: - Multiplayer

extension GameKitManager {
    
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
    
}
