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
    @ObservedObject var store: PythonStore
    @StateObject private var inputHandler = InputHandler()
    @State private var isPopoverPresented = false
    @State private var isRunDisabled = false
    @FocusState private var isTextFieldFocused: Bool
    
    public var body: some View {
        GeometryReader { geo in
            let isPresented = geo.size.height < 44
            
            ConsoleView(store: store) { log in
                if let inputLog = log as? PythonInputLog {
                    PythonInputView(log: inputLog)
                }
            }
            .opacity(isPresented ? 0 : 1)
            .fontDesign(.monospaced)
            .safeAreaInset(edge: .top) {
                if !isPresented {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(height: 16)
                }
            }
            .animation(.default, value: isPresented)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    TextField(">>>", text: $inputHandler.input, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...10)
                        .fontDesign(.monospaced)
                        .disableAutocorrection(true)
                        .onSubmit(run)
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
                    
                    Button {
                        run()
                    } label: {
                        if inputHandler.compiledCode != nil {
                            Image.python?.resizable()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "sparkles")
                                .symbolRenderingMode(.multicolor)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRunDisabled)
                    .animation(.default, value: inputHandler.compiledCode == nil)
                }
                .padding(8)
                
                #if os(iOS)
                if isTextFieldFocused {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(inputHandler.completions, id: \.self) { completion in
                                let text = completion
                                    .replacingOccurrences(of: "\t", with: "tab")
                                Button(text) {
                                    inputHandler.set(completion: completion)
                                }
                                .tint(.primary)
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
                #endif
            }
            .background(.thinMaterial)
            .animation(.default, value: inputHandler.completions.isEmpty)
        }
        .scrollDismissesKeyboard(.automatic)
        .onAppear {
            Interpreter.output(to: store)
        }
    }
    
    func run() {
        guard let compiledCode = inputHandler.compiledCode else {
            return
        }

        let code = inputHandler.input
        
        store.user(id: compiledCode.id, input: code)

        inputHandler.input = ""
        
        Task {
            try? await Interpreter.execute(compiledCode: compiledCode)
        }
    }
}
