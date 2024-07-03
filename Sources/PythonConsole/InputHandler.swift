//
//  InputHandler.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-03.
//

import PythonTools
import Foundation
import Combine

final class InputHandler: ObservableObject {
    @Published var input = ""
    @Published var completions: [String] = []
    
    init() {
        $input.map(\.lastComponent)
            .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap(maxPublishers: .max(1)) { input in
                Future { promise in
                    Task {
                        let results = (try? await Interpreter.completions(code: input)) ?? []
                        
                        let filtered = results.filter { !$0.isEmpty }

                        print(filtered)
                        promise(.success(filtered))
                    }
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: &$completions)
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
