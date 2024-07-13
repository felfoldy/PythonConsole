// The Swift Programming Language
// https://docs.swift.org/swift-book

import DebugTools
import SwiftUI

public enum PythonConsole {
    public static func initialize() {
        #if canImport(UIKit)
        DebugTools.shakePresentedConsole = {
            // TODO: Move to a PythonLogTools interface lib.
            PythonLogger.config()
            
            let store = PythonStore()
            
            // Attach logs from LogTools.
            DebugTools.initialize()
            if let logStore = DebugTools.sharedStore {
                store.attach(store: logStore)
            }
            
            let consoleView = PythonConsoleView(store: store)
            
            let hostingController = UIHostingController(rootView: consoleView)
            return ConsoleViewController(base: hostingController)
        }
        #endif
    }
}
