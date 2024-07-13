// The Swift Programming Language
// https://docs.swift.org/swift-book

import DebugTools
import SwiftUI

public enum PythonConsole {
    public static func initialize() {
        #if canImport(UIKit)
        DebugTools.shakePresentedConsole = {
            let consoleView = UIHostingController(rootView: PythonConsoleView())
            return ConsoleViewController(base: consoleView)
        }
        #endif
    }
}
