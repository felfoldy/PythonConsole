//
//  PythonConsoleView.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-03.
//

import SwiftUI
import DebugTools
import PythonTools

public struct PythonConsoleView: View {
    @StateObject private var store = PythonStore(logFilter: .none)
    @StateObject private var inputHandler = InputHandler()
    @State private var isPopoverPresented = false
    @State private var isRunDisabled = false
    
    public init() {}
    
    public var body: some View {
        ConsoleView(store: store) { log in
            if let inputLog = log as? PythonInputLog {
                PythonInputView(log: inputLog)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                TextField(">>>", text: $inputHandler.input, axis: .vertical)
                    .lineLimit(1...10)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    #elseif os(macOS)
                    .onChange(of: inputHandler.completions) { _, newValue in
                        isPopoverPresented = !newValue.isEmpty
                    }
                    .popover(isPresented: $isPopoverPresented,
                             attachmentAnchor: .point(.topLeading)) {
                        VStack {
                            ForEach(inputHandler.completions, id: \.self) { completion in
                                Button {
                                    inputHandler.set(completion: completion)
                                } label: {
                                    let text = completion.replacingOccurrences(of: "\t", with: "tab")
                                    Text(text)
                                        .frame(minWidth: 200, alignment: .leading)
                                }
                            }
                        }
                        .padding(8)
                        .buttonStyle(.borderless)
                    }
                    #endif
                    .disableAutocorrection(true)
                    .onSubmit {
                        run()
                    }
                
                Button("Run") {
                    run()
                }
                .disabled(isRunDisabled)
            }
            .padding()
            .background(.thinMaterial)
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(inputHandler.completions, id: \.self) { completion in
                            let text = completion
                                .replacingOccurrences(of: "\t", with: "tab")
                            Button(text) {
                                inputHandler.set(completion: completion)
                            }
                            .buttonStyle(.bordered)
                            .tint(.primary)
                            
                            Divider()
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.automatic)
        .onAppear {
            Interpreter.output(to: store)
        }
    }
    
    func run() {
        if isRunDisabled { return }
        isRunDisabled = true
        let code = inputHandler.input
        
        store.user(input: code)
        let codeToRun = code
        inputHandler.input = ""
        
        Task {
            try? await Interpreter.run(codeToRun)
            isRunDisabled = false
        }
    }
}
