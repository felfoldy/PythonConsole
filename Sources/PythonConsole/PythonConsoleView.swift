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
    @StateObject private var inputProcessor = InputProcessor()
    @State private var isPopoverPresented = false
    @State private var isRunDisabled = false
    @FocusState private var isTextFieldFocused: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    public init() {
        store = PythonConsole.store
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isPresented = geo.size.height < 44
            
            ConsoleView(store: store) { log in
                if let inputLog = log as? PythonInputLog {
                    PythonInputView(log: inputLog)
                }
                
                if let outputLog = log as? PythonOutputLog {
                    PythonOutputView(log: outputLog)
                }
                
                if let gptInputLog = log as? GenerativeInputLog {
                    GenerativeInputView(log: gptInputLog)
                }
            }
            .textSelection(.enabled)
            .opacity(isPresented ? 0 : 1)
            .fontDesign(.monospaced)
            #if !os(macOS)
            .safeAreaInset(edge: .top) {
                if !isPresented {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(height: 16)
                }
            }
            #endif
            .animation(.default, value: isPresented)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    TextField(">>>", text: $inputProcessor.input, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...10)
                        .fontDesign(.monospaced)
                        .disableAutocorrection(true)
                        .onSubmit(run)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                        #elseif os(macOS)
                        .onChange(of: inputProcessor.completions) { _, newValue in
                            isPopoverPresented = !newValue.isEmpty
                        }
                        .popover(isPresented: $isPopoverPresented,
                                 attachmentAnchor: .point(.topLeading)) {
                            VStack {
                                ForEach(inputProcessor.completions, id: \.self) { completion in
                                    Button {
                                        inputProcessor.set(completion: completion)
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
                        if inputProcessor.compiledCode != nil {
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
                    .animation(.default, value: inputProcessor.compiledCode == nil)
                }
                .padding(8)
                
                #if os(iOS)
                if isTextFieldFocused {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(inputProcessor.completions, id: \.self) { completion in
                                let text = completion
                                    .replacingOccurrences(of: "\t", with: "tab")

                                if inputProcessor.isPrimary(completion) {
                                    Button(text) {
                                        let code = CompilableCode(source: completion)
                                        store.user(id: code.id, input: completion)
                                        
                                        Task {
                                            let byteCode = try await ByteCodeCompiler.fileCompiler
                                                .compile(code: code)
                                            
                                            try await Interpreter.execute(compiledCode: byteCode)

                                            dismiss()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                } else {
                                    Button(text) {
                                        inputProcessor.set(completion: completion)
                                    }
                                    .tint(.primary)
                                    .buttonStyle(.bordered)
                                }
                                
                                
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
                #endif
            }
            .background(.thinMaterial)
            .animation(.default, value: inputProcessor.completions.isEmpty)
        }
        .scrollDismissesKeyboard(.automatic)
        .onAppear {
            Interpreter.output(to: store)
        }
    }
    
    func run() {
        guard let compiledCode = inputProcessor.compiledCode else {
            runGPT()
            return
        }

        let code = inputProcessor.input
        
        store.user(id: compiledCode.id, input: code)
        inputProcessor.input = ""
        
        Task {
            try? await Interpreter.execute(compiledCode: compiledCode)
        }
    }
    
    func runGPT() {
        guard let agent = store.generativeAgent else {
            return
        }
        
        let processor = GenerativeProcessor(
            store: store,
            agent: agent,
            prompt: inputProcessor.input
        )
        
        inputProcessor.input = ""
        
        Task {
            await processor.process()
        }
    }
}
