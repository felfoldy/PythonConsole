// The Swift Programming Language
// https://docs.swift.org/swift-book

import DebugTools
import SwiftUI

public enum PythonConsole {
    public static func initialize() {
        #if canImport(UIKit)
        DebugTools.shakePresentedConsole = {
            let consoleView = UIHostingController(rootView: PythonConsoleView())
            
            if let sheet = consoleView.sheetPresentationController {
                sheet.detents = [.custom(resolver: { _ in 44 }), .medium(), .large()]
                sheet.largestUndimmedDetentIdentifier = .medium
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersEdgeAttachedInCompactHeight = true
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
                sheet.prefersGrabberVisible = true
            }
            
            return consoleView
        }
        #endif
    }
}
