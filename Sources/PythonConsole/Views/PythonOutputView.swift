//
//  PythonOutputView.swift
//  PythonConsole
//
//  Created by Tibor Felföldy on 2024-08-23.
//

import SwiftUI
import DebugTools

enum PythonOutputType {
    case out, err, eval
    
    var tint: Color {
        switch self {
        case .out: .cyan
        case .err: .red
        case .eval: .green
        }
    }
}

@Observable
class PythonOutputLog: SortableLog {
    let id = UUID().uuidString
    let date = Date()
    
    /// Type to color code and separate output logs.
    let type: PythonOutputType

    /// More than 10 lines of message will be truncated, unless this is true.
    var isExpanded = false
    
    /// Updated when the output buffer changes.
    var message: String
    
    init(message: String, type: PythonOutputType) {
        self.message = message
        self.type = type
    }
}

struct PythonOutputView: View {
    @State var log: PythonOutputLog
    
    var body: some View {
        LogContainerView(tint: log.type.tint) {
            Text(truncated)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(alignment: .topTrailing) {
            if lines.count > 10 {
                Button {
                    log.isExpanded.toggle()
                } label: {
                    Image(systemName:
                            expandImageName)
                }
                .padding(4)
                .contentTransition(.symbolEffect(.replace))
            }
        }
        .animation(.default, value: log.message)
        .animation(.default, value: log.isExpanded)
    }
    
    private var lines: [String] {
        log.message.components(separatedBy: .newlines)
    }
    
    private var truncated: String {
        let message = log.message
        
        if log.isExpanded {
            return message
        }

        if lines.count <= 10 {
            return message
        }
        
        return "...\n" + lines
            .suffix(10)
            .joined(separator: "\n")
    }
    
    private var expandImageName: String {
        if log.isExpanded {
            "rectangle.compress.vertical"
        } else {
            "rectangle.expand.vertical"
        }
    }
}
