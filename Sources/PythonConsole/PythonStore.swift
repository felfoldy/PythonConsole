//
//  PythonStore.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-03.
//

import LogTools
import DebugTools
import PythonTools
import Foundation

extension PresentableLog {
    var id: String { String(describing: self) }
}

final class PythonStore: LogStore, PythonTools.OutputStream {
    var outputBuffer: [String] = []
    var errorBuffer: [String] = []
    
    @Published var pythonLogs: [any PresentableLog] = []
    
    init() {
        super.init(logFilter: .none)

        if DebugTools.sharedStore == nil {
            #if canImport(LogTools)
            DebugTools.initialize()
            #endif
            PythonLogger.config()
        }

        if let store = DebugTools.sharedStore {
            logs = store.logs
            
            store.$logs.combineLatest($pythonLogs)
                .map(+)
                .map { logs in
                    logs
                        .compactMap { $0 as? (any SortableLog) }
                        .sorted { $0.date < $1.date }
                }
                .assign(to: &$logs)
        }
    }
    
    func user(id: UUID, input: String) {
        pythonLogs.append(PythonInputLog(id: id, input: input))
    }
    
    func finalize(codeId: UUID, executionTime: UInt64) {
        let inputLogs = logs.compactMap { $0 as? PythonInputLog }
        
        if let inputLog = inputLogs.last(where: { $0.id == codeId.uuidString }) {
            inputLog.executionTime = executionTime
        }
        
        let output = outputBuffer
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !output.isEmpty {
            pythonLogs.append(LogEntry(message: output, level: .info, location: "stdout"))
        }
        
        let errorMessage = errorBuffer
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !errorMessage.isEmpty {
            pythonLogs.append(LogEntry(message: errorMessage, level: .fault, location: "stderr"))
        }
        
        outputBuffer = []
        errorBuffer = []
    }
    
    func evaluation(result: String) {
        pythonLogs.append(LogEntry(message: result, level: .debug, location: "eval"))
    }
    
    func clear() {
        pythonLogs = []
        DebugTools.sharedStore?.logs = []
    }
}
