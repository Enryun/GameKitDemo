//
//  HomeViewModel.swift
//  GameKitDemo
//
//  Created by James Thang on 5/12/24.
//

import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    
    @Published private(set) var isAuthenticated = false
    @Published var showAuthenticationView = false
    @Published private(set) var authenticationViewController: UIViewController?
    @Published private(set) var authenticationError: AuthenticationError?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupGameKitAuthenticatationObserver()
    }
    
    private func setupGameKitAuthenticatationObserver() {
        GameKitManager.shared.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        GameKitManager.shared.$authenticationError
            .receive(on: DispatchQueue.main)
            .assign(to: \.authenticationError, on: self)
            .store(in: &cancellables)
        
        GameKitManager.shared.$authenticationViewController
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewController in
                guard let self = self else { return }
                if let _ = viewController {
                    self.showAuthenticationView = true
                } else {
                    self.showAuthenticationView = false
                }
            }
            .store(in: &cancellables)
    }
    
}




