//
//  PythonStore.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-03.
//

import LogTools
import DebugTools
import PythonTools
import SpeechTools
import Foundation
import Combine

public final class PythonStore: LogStore, PythonTools.OutputStream {
    nonisolated(unsafe) public var outputBuffer: [String] = [] {
        didSet { outputUpdated() }
    }

    nonisolated(unsafe) public var errorBuffer: [String] = [] {
        didSet { errorUpdated() }
    }
    
    /// Logs added from `PythonStore`. All logs are combined with `attachedStore`.
    @Published
    var pythonLogs: [any PresentableLog] = []
    
    private var attachedStore: LogStore?
    var generativeAgent: GenerativeAgent?
    
    private var logSubscription: AnyCancellable?
    
    public init() {
        super.init(logFilter: .none)
        
        logSubscription = $pythonLogs
            .map { $0.suffix(200) }
            .assign(to: \.logs, on: self)
    }
    
    public func attach(store: LogStore) {
        guard attachedStore == nil else { return }

        attachedStore = store
        
        if logs.isEmpty {
            logs = store.logs
        }

        logSubscription = store.$logs
            .combineLatest($pythonLogs)
            .map(+)
            .map { logs in
                logs
                    .compactMap { $0 as? (any SortableLog) }
                    .sorted { $0.date < $1.date }
                    .suffix(200)
            }
            .assign(to: \.logs, on: self)
    }
    
    @MainActor
    private func logOutput(message: String, type: PythonOutputType) {
        if let last = pythonLogs.last as? PythonOutputLog, last.type == type {
            last.messageSubject.send(message)
        } else {
            pythonLogs.append(PythonOutputLog(message: message, type: type))
        }
    }

    nonisolated func outputUpdated() {
        let message = output
        if message.isEmpty { return }
        
        Task { @MainActor in
            logOutput(message: message, type: .out)
        }
    }
    
    nonisolated func errorUpdated() {
        let message = errorMessage
        if message.isEmpty { return }
        
        Task { @MainActor in
            logOutput(message: message, type: .err)
        }
    }
    
    func user(id: UUID, input: String) {
        pythonLogs.append(PythonInputLog(id: id, input: input))
    }
    
    nonisolated public func finalize(codeId: UUID, executionTime: UInt64) {
        // Update execution time.
        Task { @MainActor in
            let inputLogs = pythonLogs.compactMap { $0 as? PythonInputLog }
            
            if let inputLog = inputLogs.last(where: { $0.id == codeId.uuidString }) {
                inputLog.executionTime = executionTime
            }
        }
        
        // Clear buffers.
        outputBuffer = []
        errorBuffer = []
    }
    
    nonisolated public func evaluation(result: String) {
        let message = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task { @MainActor in
            let log = PythonOutputLog(message: message, type: .eval)
            pythonLogs.append(log)
        }
    }
    
    nonisolated public func clear() {
        Task { @MainActor in
            pythonLogs = []
            attachedStore?.logs = []
        }
    }
}
