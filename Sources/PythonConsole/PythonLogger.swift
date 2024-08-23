//
//  PythonLogger.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-09.
//

import LogTools
import PythonTools
import PythonKit
import Python

let log = Logger(subsystem: "com.felfoldy.PythonConsole", category: "Console")

struct PythonLogger {
    static func config() {
        Task {
            do {
                try await Interpreter.load(bundle: .module) {
                    let logger = Python.import("logtools")
                    let main = Python.import("__main__")
                    main.log = logger.Logger()
                    
                    logger.Logger._log_out = PythonFunction { objs in
                        let _ = objs[0]
                        let logLevel = objs[1]
                        let message = String(objs[2])!
                        let file = String(objs[3])
                        let function = String(objs[4])
                        let line = Int(objs[5])
                        
                        let levels: [LogLevel] = [
                            .debug,
                            .info,
                            .default,
                            .error,
                            .fault
                        ]
                        
                        let level = levels[Int(logLevel.value)!]
                        
                        log.log(level: level,
                                message,
                                file: file ?? "",
                                function: function ?? "",
                                line: line ?? 0)
                        
                        return Python.None
                    }
                    .pythonObject
                }
            } catch {
                log.fault(error.localizedDescription)
            }
        }
    }
}
