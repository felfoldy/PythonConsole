//
//  PythonInputView.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-03.
//

import SwiftUI
import DebugTools

struct PythonInputLog: PresentableLog {
    let input: String
    var executionTime: UInt64?
    
    var duration: String? {
        guard let executionTime else { return nil }
        return Duration.nanoseconds(executionTime)
            .formatted(.units(allowed: [.milliseconds, .seconds],
                              fractionalPart: .show(length: 2, rounded: .up)))
    }
}

struct PythonInputView: View {
    let log: PythonInputLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text(">>>")
                        .foregroundStyle(.secondary)
                    
                    Text(log.input)
                }
                
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
