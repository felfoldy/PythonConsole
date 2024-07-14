//
//  GenerativeInputView.swift
//  PythonConsole
//
//  Created by Tibor Felföldy on 2024-07-13.
//

import DebugTools
import SwiftUI

extension SortableLog {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
class GenerativeInputLog: SortableLog {
    let id: String
    let date = Date.now
    let input: String
    var isRunning = true
    
    init(id: UUID, input: String) {
        self.id = id.uuidString
        self.input = input
    }
}

struct GenerativeInputView: View {
    @State var log: GenerativeInputLog
    
    var body: some View {
        Label(log.input, systemImage: "sparkles")
            .font(.system(size: 14, design: .rounded))
            .symbolEffect(.pulse, options: .repeating,
                          isActive: log.isRunning)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
            .overlay(alignment: .bottom) {
                Divider()
            }
            .symbolRenderingMode(.multicolor)
            .animation(.default, value: log.isRunning)
    }
}

#Preview {
    GenerativeInputView(log: GenerativeInputLog(id: UUID(), input: "This will be the input"))
}
