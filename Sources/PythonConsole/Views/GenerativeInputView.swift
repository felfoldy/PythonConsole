//
//  GenerativeInputView.swift
//  PythonConsole
//
//  Created by Tibor Felföldy on 2024-07-13.
//

import DebugTools
import SwiftUI
import SpeechTools

extension SortableLog {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
class GenerativeInputLog: SortableLog {
    struct Usage {
        let prompt: Int
        let completion: Int
    }
    
    let id: String
    let date = Date.now
    let input: String
    var usage: Usage?
    
    init(id: UUID, input: String) {
        self.id = id.uuidString
        self.input = input
    }
}

struct GenerativeInputView: View {
    @State var log: GenerativeInputLog
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(log.input, systemImage: "sparkles")
            
            if let usage = log.usage {
                HStack {
                    Label("\(usage.prompt)", systemImage: "chevron.up")

                    Label("\(usage.completion)", systemImage: "chevron.down")
                }
                .foregroundStyle(.secondary)
                .font(.caption)
            }
        }
        .font(.system(size: 14, design: .rounded))
        .symbolEffect(.pulse, options: .repeating,
                      isActive: log.usage == nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .symbolRenderingMode(.multicolor)
        .animation(.default, value: log.usage == nil)
    }
}

#Preview {
    VStack {
        GenerativeInputView(log: GenerativeInputLog(id: UUID(), input: "This will be the input"))
        
        GenerativeInputView(log: {
            let usedLog = GenerativeInputLog(id: UUID(), input: "Finished generative input")
            usedLog.usage = .init(prompt: 12, completion: 35)
            return usedLog
        }())
    }
}
