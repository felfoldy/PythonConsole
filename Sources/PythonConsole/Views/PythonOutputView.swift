//
//  PythonOutputView.swift
//  PythonConsole
//
//  Created by Tibor Felföldy on 2024-08-23.
//

import SwiftUI
import DebugTools
import Combine

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

class PythonOutputLog: SortableLog, ObservableObject {
    let id = UUID().uuidString
    let date = Date()
    
    /// Type to color code and separate output logs.
    let type: PythonOutputType

    /// More than 10 lines of message will be truncated, unless this is true.
    @Published var isExpanded = false

    /// Updated when the output buffer changes.
    @Published private(set) var message: String
    
    var messageSubject: CurrentValueSubject<String, Never>
    
    init(message: String, type: PythonOutputType) {
        self.message = message
        self.type = type
        messageSubject = CurrentValueSubject(message)
        
        messageSubject
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
            .assign(to: &$message)
    }
}

struct PythonOutputView: View {
    @StateObject var log: PythonOutputLog
    
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
