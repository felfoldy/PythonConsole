//
//  PythonStore.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-03.
//

import DebugTools
import PythonTools

extension PresentableLog {
    var id: String { String(describing: self) }
}

final class PythonStore: LogStore, OutputStream {
    var outputBuffer: [String] = []
    var errorBuffer: [String] = []
    
    func user(input: String) {
        logs.append(PythonInputLog(input: input))
    }
    
    func finalize() {
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
    
    func execution(time: UInt64) {
        if var inputLog = logs.last as? PythonInputLog {
            logs.removeLast()
            inputLog.executionTime = time
            logs.append(inputLog)
        }
    }
    
    func clear() {
        logs = []
    }
}
