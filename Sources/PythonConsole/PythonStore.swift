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

extension PresentableLog {
    var id: String { String(describing: self) }
}

@MainActor
public final class PythonStore: LogStore, PythonTools.OutputStream {
    public var outputBuffer: [String] = []
    public var errorBuffer: [String] = []
    
    /// Logs added from `PythonStore`. All logs are combined with `attachedStore`.
    @Published
    var innerLogs: [any PresentableLog] = []
    
    private var attachedStore: LogStore?
    var generativeAgent: GenerativeAgent?
    
    private var logSubscription: AnyCancellable?
    
    public init() {
        super.init(logFilter: .none)
        
        logSubscription = $innerLogs.assign(to: \.logs, on: self)
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
            }
            .assign(to: \.logs, on: self)
    }
    
    func user(id: UUID, input: String) {
        innerLogs.append(PythonInputLog(id: id, input: input))
    }
    
    public func finalize(codeId: UUID, executionTime: UInt64) {
        let inputLogs = innerLogs.compactMap { $0 as? PythonInputLog }
        
        if let inputLog = inputLogs.last(where: { $0.id == codeId.uuidString }) {
            inputLog.executionTime = executionTime
        }
        
        let output = outputBuffer
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !output.isEmpty {
            Task { @MainActor in
                innerLogs.append(LogEntry(message: output, level: .info, location: "stdout"))
            }
        }
        
        let errorMessage = errorBuffer
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !errorMessage.isEmpty {
            Task { @MainActor in
                innerLogs.append(LogEntry(message: errorMessage, level: .fault, location: "stderr"))
            }
        }
        
        outputBuffer = []
        errorBuffer = []
    }
    
    public func evaluation(result: String) {
        Task { @MainActor in
            innerLogs.append(LogEntry(message: result, level: .debug, location: "eval"))
        }
    }
    
    public func clear() {
        Task { @MainActor in
            innerLogs = []
            attachedStore?.logs = []
        }
    }
}
