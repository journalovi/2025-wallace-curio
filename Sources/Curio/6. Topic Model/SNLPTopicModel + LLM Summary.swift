// Copyright (c) 2025 Jim Wallace
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import MLX
import MLXLLM
import MLXLMCommon
import Foundation


extension SNLPTopicModel {
    
    
    func summarize(_ topic: Topic,
                   numberOfDocuments: Int = 50,
                   summaryLength: Int = 40,
                   temperature: Float = 0.3,
                   topP: Float = 0.8
    ) async throws -> String {
        
        guard let resourcesURL = Bundle.module.resourceURL?.appendingPathComponent("Llama-3.2-1B-Instruct-4bit", isDirectory: true) else {
            fatalError("Failed to find LLM folder in test bundle.")
        }
        
        let modelConfiguration = ModelConfiguration(directory: resourcesURL)
        let modelContainer = try await LLMModelFactory.shared.loadContainer(configuration: modelConfiguration)
        
        
        // Choose 25 documents randomly to
        let sampleDocuments = topic.documents.map{ corpus.documents[$0].fullText }
                                             .shuffled()
                                             .prefix(numberOfDocuments)
                                             .joined(separator: "\n---\n")
                
        // 2. Prepare the user input
        let prompt = """
        Return exactly one sentence summarizing the overall topic of the following posts.
        Your answer must begin with "\(topic.label):", followed by a descriptor like "Questions about" or "Stories about" and end with a period. 
        It should be a single, substantive sentence that clearly captures the main theme of the discussion — avoiding generic or placeholder language.
        Use plain, concise academic language.
        Do not include any internal reasoning, lists, meta commentary, or explanations. 
        Do not reference specific details from individual posts.
        Below are the posts:
        \(sampleDocuments)
        """
        let userInput = UserInput(prompt: prompt)
        
        // 3. Perform text generation within the model's context
        let result = try await modelContainer.perform { context in
            
            // Prepare the LMInput using the processor
            let lmInput = try await context.processor.prepare(input: userInput)
            
            // Set generation parameters (e.g., default parameters)
            let generateParams = GenerateParameters(temperature: temperature, topP: topP)
            
            // Generate text using the MLXLMCommon utility
            return try MLXLMCommon.generate(input: lmInput, parameters: generateParams, context: context) { tokens in
                // Concatenate the tokens to form the generated text.
                let generatedText = tokens.map { $0.description }.joined()
                // If the text (after trimming whitespace) ends with a period, stop generation.
                if generatedText.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(".") {
                    return .stop
                }
                if tokens.count >= summaryLength {
                    return .stop
                }
                return .more
            }
        }
        
        // 4. Use the generated output
        return result.output.replacingOccurrences(of: "\n", with: " ")
        
    }
    
}
