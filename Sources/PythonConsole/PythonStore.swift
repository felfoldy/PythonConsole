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
    public var outputBuffer: [String] = [] {
        didSet { outputUpdated() }
    }

    public var errorBuffer: [String] = [] {
        didSet { errorUpdated() }
    }
    
    /// Logs added from `PythonStore`. All logs are combined with `attachedStore`.
    @Published
    var innerLogs: [any PresentableLog] = []
    
    private var attachedStore: LogStore?
    var generativeAgent: GenerativeAgent?
    
    private var logSubscription: AnyCancellable?
    
    public init() {
        super.init(logFilter: .none)
        
        logSubscription = $innerLogs
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
            .combineLatest($innerLogs)
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
    func logOutput(message: String, type: PythonOutputType) {
        if let last = innerLogs.last as? PythonOutputLog, last.type == type {
            last.message = message
        } else {
            innerLogs.append(PythonOutputLog(message: message, type: type))
        }
    }

    func outputUpdated() {
        let message = output
        if message.isEmpty { return }
        
        Task { @MainActor in
            logOutput(message: message, type: .out)
        }
    }
    
    func errorUpdated() {
        let message = errorMessage
        if message.isEmpty { return }
        
        Task { @MainActor in
            logOutput(message: message, type: .err)
        }
    }
    
    func user(id: UUID, input: String) {
        innerLogs.append(PythonInputLog(id: id, input: input))
    }
    
    public func finalize(codeId: UUID, executionTime: UInt64) {
        // Update execution time.
        let inputLogs = innerLogs.compactMap { $0 as? PythonInputLog }
        
        if let inputLog = inputLogs.last(where: { $0.id == codeId.uuidString }) {
            inputLog.executionTime = executionTime
        }
        
        // Clear buffers.
        outputBuffer = []
        errorBuffer = []
    }
    
    public func evaluation(result: String) {
        let message = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task { @MainActor in
            innerLogs.append(PythonOutputLog(
                message: message,
                type: .eval)
            )
        }
    }
    
    public func clear() {
        Task { @MainActor in
            innerLogs = []
            attachedStore?.logs = []
        }
    }
}
