//
//  GenerativeProcessor.swift
//
//
//  Created by Tibor Felföldy on 2024-07-13.
//

import Foundation
import SpeechTools
import DebugTools
import RegexBuilder
import PythonTools

/// Processes a given prompt using a generative agent, logs the input, and handles the agent's response.
/// It supports detecting and executing embedded Python code in the agent's response.
struct GenerativeProcessor {
    let store: PythonStore
    let agent: GenerativeAgent
    let prompt: String
    
    func process() async {
        let inputLog = GenerativeInputLog(id: UUID(), input: prompt)

        await MainActor.run {
            store.innerLogs.append(inputLog)
            agent.history = consoleHistory
        }
        
        do {
            let message = try await agent.generateResponse()

            if let lastUsage = await agent.usage.last {
                inputLog.usage = .init(prompt: lastUsage.promptTokens, completion: lastUsage.completionTokens)
            }

            try await handleResponse(text: message.text)
        } catch {
            log.fault(error.localizedDescription)
        }
    }
    
    @MainActor
    private var consoleHistory: [ChatMessage] {
        store.innerLogs.compactMap { log in
            if let pythonInput = log as? PythonInputLog {
                return ChatMessage(.user, ">>> \(pythonInput.input)")
            }
            
            if let entry = log as? LogEntry {
                return ChatMessage(.user, entry.composedMessage)
            }
            
            if let generativeInput = log as? GenerativeInputLog {
                return ChatMessage(.user, generativeInput.input)
            }
            
            return nil
        }
    }

    private func handleResponse(text: String) async throws {
        let regex = Regex {
            Capture {
                ZeroOrMore(.any)
            }
            
            ZeroOrMore(.newlineSequence)
            
            "```python"
            One(.newlineSequence)
            Capture {
                OneOrMore(.any)
            }
            One(.newlineSequence)
            "```"
        }
        
        if let match = text.firstMatch(of: regex) {
            let (_, content, python) = match.output

            let response = String(content)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !response.isEmpty {
                await add(response: response)
            }

            let script = String(python)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            try await run(python: script)
        } else {
            await add(response: text)
        }
    }
    
    @MainActor
    private func add(response text: String) {
        store.innerLogs.append(
            LogEntry(message: text,
                     level: .notice,
                     location: "GPT")
        )
    }
    
    private func run(python: String) async throws {
        let code = CompilableCode(source: python, filename: "<gptin>")
        
        await MainActor.run {
            store.user(id: code.id, input: python)
        }
        
        let byteCode = try await ByteCodeCompiler.fileCompiler
            .compile(code: code)

        try await Interpreter.execute(compiledCode: byteCode)
    }
}
