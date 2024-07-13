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
    let date = Date.now
    let input: String
    
    init(input: String) {
        self.input = input
    }
}

struct GenerativeInputView: View {
    @State var log: GenerativeInputLog
    
    var body: some View {
        Text(log.input)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
            .overlay(alignment: .bottom) {
                Divider()
            }
    }
}

#Preview {
    GenerativeInputView(log: GenerativeInputLog(input: "This will be the input"))
}
