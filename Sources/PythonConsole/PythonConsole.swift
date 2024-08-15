// The Swift Programming Language
// https://docs.swift.org/swift-book

import DebugTools
import SpeechTools
import SwiftUI

@MainActor
public enum PythonConsole {
    public static var store = PythonStore()
    
    public static func initialize() {
        #if canImport(UIKit)
        DebugTools.shakePresentedConsole = {
            // TODO: Move to a PythonLogTools interface lib.
            PythonLogger.config()
            
            // Attach LogTools logs.
            if DebugTools.sharedStore == nil {
                DebugTools.initialize()
            }

            if let logStore = DebugTools.sharedStore {
                store.attach(store: logStore)
            }

            let consoleView = PythonConsoleView(store: store)
            
            let hostingController = UIHostingController(rootView: consoleView)
            return ConsoleViewController(base: hostingController)
        }
        #endif
    }
    
    public static func set(generativeAgent: GenerativeAgent) {
        store.generativeAgent = generativeAgent
    }
    
    public static func set(gpt model: GPTModel) {
        let agent = GenerativeAgent(
            model: model,
            instructions: """
            Help the user write in a python 3.11 interpreter.
            
            Always end your response with one single python code block what will be executed.
            
            For example:
            User: print something
            Assistant:
            ```python
            print("something")
            ```
            """
        )

        agent.isLoggingEnabled = false
        
        set(generativeAgent: agent)
    }
}
