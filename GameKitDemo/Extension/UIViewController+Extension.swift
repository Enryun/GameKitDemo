//
//  UIViewController+Extension.swift
//  CommonSwiftUI
//
//  Created by James Thang on 24/03/2024.
//

import UIKit

extension UIViewController {
    /// Finds the top-most view controller from the current view controller's hierarchy.
    ///
    /// Navigates through presented, navigation, and tab bar controller hierarchies to identify the foremost view controller that is visible and interactive to the user. Useful for accurately determining where to present new view controllers or alerts from a nested structure.
    ///
    /// - Returns: The highest view controller in the hierarchy that can be interacted with by the user.
    public var topMostViewController : UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController ?? navigation
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController ?? tab
        }
        return self
    }
    
}
