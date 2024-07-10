//
//  PythonInputView.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-03.
//

import SwiftUI
import DebugTools
import Highlightr

extension Highlightr {
    static let standard: Highlightr? = {
        let highlightr = Highlightr()
        highlightr?.setTheme(to: "ocean")
        return highlightr
    }()
}

@Observable
class PythonInputLog: SortableLog {
    static func == (lhs: PythonInputLog, rhs: PythonInputLog) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    let date = Date.now
    let input: String
    var executionTime: UInt64?
    
    let attributedCode: AttributedString
    
    init(id: UUID, input: String) {
        self.id = id.uuidString
        self.input = input
        
        attributedCode = {
            if let highlightr = Highlightr.standard,
               let highlighted = highlightr.highlight(input, as: "python") {
                return AttributedString(highlighted)
            }
            return AttributedString(input)
        }()
    }
    
    var duration: String? {
        guard let executionTime else { return nil }
        return Duration.nanoseconds(executionTime)
            .formatted(.units(allowed: [.milliseconds, .seconds],
                              fractionalPart: .show(length: 2, rounded: .up)))
    }
}

struct PythonInputView: View {
    @State var log: PythonInputLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text(">>>")
                        .foregroundStyle(.secondary)
                    
                    Text(log.attributedCode)
                }
                .fontDesign(.monospaced)
                
                if let duration = log.duration {
                    Label(duration, systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(4)
            
            Divider()
        }
    }
}
