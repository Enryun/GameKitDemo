//
//  MultiplayerView.swift
//  PirateWar
//
//  Created by James Thang on 29/11/24.
//

import SwiftUI

struct MultiplayerView: View {
    
    @StateObject private var multiplayerViewModel = MultiplayerViewModel()
    
    var body: some View {
        VStack {
            switch multiplayerViewModel.state {
            case .idle:
                IdleView
            case .matchmaking:
                MatchMakingView
            case .waitingForPlayers:
                WaitingForPlayersView
            case .readyToStart:
                ReadyToStartView
            case .gameActive:
                GameActiveView
            case .error(let message):
                ErrorView(message: message)
            }
        }
    }
    
    private var IdleView: some View {
        VStack {
            Text("No active match")
                .font(.headline)
            
            Button("Find Match") {
                multiplayerViewModel.startMatchmaking(presentingViewController: UIApplication.rootViewController)
            }
        }
        .padding()
    }
    
    private var MatchMakingView: some View {
        VStack {
            Text("Finding a match...")
                .font(.headline)
            
            ProgressView()
        }
    }
    
    private var WaitingForPlayersView: some View {
        VStack {
            Text("Waiting for another player to connect...")
                .font(.headline)
            
            List {
                Text("You (Local Player)")
                ForEach(multiplayerViewModel.connectedPlayers, id: \.gamePlayerID) { player in
                    Text(player.displayName)
                }
            }
            
            Button("Cancel") {
                multiplayerViewModel.disconnectMatch()
            }
            .padding()
        }
    }
    
    private var ReadyToStartView: some View {
        Text("Game is starting!")
            .font(.headline)
    }
    
    private var GameActiveView: some View {
        VStack(spacing: 20) {
            Text("Game in progress")
                .font(.headline)
            
            Text("Counter: \(multiplayerViewModel.counter)")
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                multiplayerViewModel.incrementCounter()
            }) {
                Text("Increment Counter")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button("End Game") {
                // Implement logic to end the game
                multiplayerViewModel.disconnectMatch()
            }
            .padding()
        }
        .padding()
    }
    
    @ViewBuilder
    private func ErrorView(message: String) -> some View {
        VStack {
            Text("Error: \(message)")
                .foregroundColor(.red)
                .padding()
            
            Button("Back to Home") {
                multiplayerViewModel.disconnectMatch()
            }
            .padding()
        }
    }
    
}
