//
//  HomeView.swift
//  GameKitDemo
//
//  Created by James Thang on 5/12/24.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink {
                    MultiplayerView()
                } label: {
                    Text("Multiplayer Demo")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.blue, in: .rect(cornerRadius: 12))
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
