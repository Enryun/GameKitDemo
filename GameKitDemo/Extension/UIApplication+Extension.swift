//
//  UIApplication+Extension.swift
//  CommonSwiftUI
//
//  Created by James Thang on 24/03/2024.
//

import Foundation
import UIKit

extension UIApplication {
    /// Retrieves the top-most view controller from the main application window.
    ///
    /// This class variable assesses the application's window hierarchy, starting from the root view controller of the last key window among connected scenes. It recursively traverses presented view controllers, navigation controllers, and tab bar controllers to find the top-most view controller that is currently visible to the user.
    ///
    /// - Returns: The currently visible and top-most `UIViewController`, if one exists.
    public static var topMostViewController : UIViewController? {
        let window = UIApplication
            .shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last
        return window?.rootViewController?.topMostViewController
    }
    
    /// Retrieves the application's root view controller.
    ///
    /// Attempts to find the root view controller of the primary window by accessing the first connected `UIWindowScene`. If no `UIWindowScene` or root view controller can be found, returns a new instance of `UIViewController`. This ensures a non-nil return value, though it may be an empty view controller if the app's window hierarchy is not properly configured.
    ///
    /// - Returns: The app's root `UIViewController`, or a new `UIViewController` instance if none is found.
    public static var rootViewController: UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }
        
        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }
        
        return root
    }
    
}
