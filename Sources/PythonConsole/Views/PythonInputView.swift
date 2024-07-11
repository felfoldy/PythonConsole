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
    struct LineComponent: Identifiable {
        let id: Int
        let indentation: Int
        let highlighted: AttributedString
    }
    
    static func == (lhs: PythonInputLog, rhs: PythonInputLog) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    let date = Date.now
    let input: String
    var executionTime: UInt64?

    let components: [LineComponent]

    init(id: UUID, input: String) {
        self.id = id.uuidString
        self.input = input
        
        components = {
            let code = input.replacingOccurrences(of: "\t", with: "    ")
            
            guard let highlightr = Highlightr.standard,
                  let highlighted = highlightr.highlight(code, as: "python") else {
                return [LineComponent(id: 1, indentation: 0, highlighted: AttributedString(input))]
            }
            
            let components = highlighted
                .components(separatedBy: "\n")
            
            return components.enumerated()
                .map { offset, row in
                    let components = row.components(separatedBy: "    ")
                    
                    return LineComponent(
                        id: offset + 1,
                        indentation: components.count - 1,
                        highlighted: AttributedString(components.last ?? NSAttributedString(""))
                    )
                }
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
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(log.components) { component in
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text({
                                if component.id == 1 {
                                    ">>>"
                                } else {
                                    component.id
                                        .formatted(.number.precision(
                                            .integerAndFractionLength(
                                                integer: 3,
                                                fraction: 0
                                            )
                                        ))
                                }
                            }())
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            
                            HStack(spacing: 0) {
                                ForEach(0 ..< component.indentation, id: \.self) { _ in
                                    Text("   ")
                                        .font(.system(size: 14))
                                        .overlay(alignment: .trailing) {
                                            Divider()
                                        }
                                }
                                
                                Text(component.highlighted)
                            }
                        }
                    }
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

private extension NSAttributedString {
    func components(separatedBy separator: String) -> [NSAttributedString] {
        var result = [NSAttributedString]()
        let separatedStrings = string.components(separatedBy: separator)
        var range = NSRange(location: 0, length: 0)
        for string in separatedStrings {
            range.length = string.utf16.count
            let attributedString = attributedSubstring(from: range)
            result.append(attributedString)
            range.location += range.length + separator.utf16.count
        }
        return result
    }
}

#Preview {
    ScrollView {
        PythonInputView(log: PythonInputLog(id: UUID(), input: """
    class SomeClass:
        def some_very_long_function_name_what_must_be_broken(count: int) -> str:
            for i in range(count):
                print(f"row {i+1}")
            
            return "yeah"
    """))
    }
}
