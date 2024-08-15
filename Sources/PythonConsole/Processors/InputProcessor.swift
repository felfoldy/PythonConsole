//
//  InputProcessor.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-03.
//

import PythonTools
import Foundation
import Combine

/// Handles user input, providing code completions, and compiling code.
final class InputProcessor: ObservableObject {
    @Published var input = ""
    @Published var completions: [String] = []
    @Published var compiledCode: CompiledByteCode?
    
    init() {
        let code = $input
            .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
            .removeDuplicates()
            .share()
        
        code
            .map(\.lastComponent)
            .flatMap(maxPublishers: .max(1)) { input in
                Future { promise in
                    Task {
                        let results = (try? await Interpreter.completions(code: input)) ?? []
                        
                        let filtered = results.filter { !$0.isEmpty }

                        promise(.success(filtered))
                    }
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: &$completions)
        
        let compiler = ByteCodeCompiler.evaluationCompiler
            .fallback(to: .fileCompiler)
        
        code.flatMap { source in
            Future { promise in
                Task {
                    let code = CompilableCode(source: source)
                    let compiledCode = try? await compiler.compile(code: code)
                    
                    promise(.success(compiledCode))
                }
            }
        }
        .receive(on: RunLoop.main)
        .assign(to: &$compiledCode)
    }
    
    func set(completion: String) {
        let lastComponent = input.lastComponent
        
        if completion.starts(with: lastComponent) {
            input = input.dropLast(lastComponent.count) + completion
        }
    }
}

extension String {
    var lastComponent: String {
        let set = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(["("]))
        return components(separatedBy: set).last ?? ""
    }
}
