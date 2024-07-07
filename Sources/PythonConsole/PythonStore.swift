//
//  PythonStore.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-03.
//

import DebugTools
import PythonTools
import Foundation

extension PresentableLog {
    var id: String { String(describing: self) }
}

final class PythonStore: LogStore, PythonTools.OutputStream {
    var outputBuffer: [String] = []
    var errorBuffer: [String] = []
    
    func user(id: UUID, input: String) {
        logs.append(PythonInputLog(id: id, input: input))
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
            logs.append(LogEntry(message: output, level: .info, location: "stdout"))
        }
        
        let errorMessage = errorBuffer
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !errorMessage.isEmpty {
            logs.append(LogEntry(message: errorMessage, level: .fault, location: "stderr"))
        }
        
        outputBuffer = []
        errorBuffer = []
    }
    
    func evaluation(result: String) {
        logs.append(LogEntry(message: result, level: .debug, location: "eval"))
    }
    
    func clear() {
        logs = []
    }
}
