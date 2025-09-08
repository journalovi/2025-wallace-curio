// Copyright (c) 2024 Henry Tian, Jim Wallace
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

#if canImport(CoreML)
import Foundation
import CoreML
import Tokenizers
import Hub
@preconcurrency import MLX

//TODO: This code needs a re-write with an eye towards readabliity and clarity, and likely simplification

/// An encoder that uses a CoreML model to encode text.
@available(macOS 13.0, *)
public final class CoreMLEncoder: SNLPEncoder, MLFeatureProvider, @unchecked Sendable {
    /// The output feature to use from the model.
    public enum outputFeature: String {
        case embeddings = "embeddings"
        case pooler_output = "pooler_output"
    }
    
    public var dimensions: Int { Int(outputDimention) }
    public var zeroes: MLXArray { MLXArray.zeros([1, dimensions]) }

    private let configuration: LanguageModelConfigurationFromHub
    private var tokenizer: BertTokenizer?
    public var outputType: outputFeature = .embeddings
    
    
    private var model: MLModel
    private var input_ids: MLMultiArray
    private var attention_mask: MLMultiArray
    
    
    internal var inputDimention: Int = 512 // 512 is a dummy value, correct value is set by the macro below
    internal var outputDimention: Int = 384
    
    public var featureNames: Set<String> {
        get {
            return ["input_ids", "attention_mask"]
        }
    }
    
        
    public required init() {
        guard let modelURL = Bundle.module.url(forResource: "all-MiniLM-L6-v2", withExtension: "mlmodelc") else {
            fatalError("Failed to find all-MiniLM-L6-v2.mlmodelc in test bundle.")
        }
        
        do {
            // Expects a compiled all-MiniLM-L6-v2 model to be packaged with the library
            model = try MLModel(contentsOf: modelURL)
        } catch {
            fatalError()
        }
                        
        // TODO: Pull from model metadata? Save this in an enum?
        self.outputType = .embeddings
        self.inputDimention = 512
        self.outputDimention = 384
        
        // dummy initialization needed here to avoid compilation error
        guard let resourcesURL = Bundle.module.resourceURL?.appendingPathComponent("all-MiniLM-L6-v2", isDirectory: true) else {
            fatalError("Failed to find Resources folder in test bundle.")
        }
        self.configuration = LanguageModelConfigurationFromHub(modelFolder: resourcesURL)
        self.tokenizer = nil
        
        self.input_ids = try! MLMultiArray(shape: [inputDimention as NSNumber], dataType: .float32)
        self.attention_mask = try! MLMultiArray(shape: [inputDimention as NSNumber], dataType: .float32)
    }


    // TODO: Need to clarify whether we want this to accept compiled models or not... what's the right shape?
    /// Initializes the encoder with a CoreML model.
    /// - Parameters:
    ///   - modelURL: The URL of the CoreML model file.
    ///   - inputDimension: The input dimension of the model.
    ///   - outputDimension: The output dimension of the model.
    ///   - outputFeature: The output feature to use from the model.
    init(
        modelURL: URL,
        inputDimension: UInt,
        outputDimension: UInt,
        outputFeature: outputFeature
    ) {
        
        do {
            let compiledURL = try MLModel.compileModel(at: modelURL)
            model = try MLModel(contentsOf: compiledURL)
        } catch {
            fatalError()
        }
        
        // TODO: Pull from model metadata? Save this in an enum?
        self.outputType = outputFeature
        self.inputDimention = Int(inputDimension)
        self.outputDimention = Int(outputDimension)
        
        // dummy initialization needed here to avoid compilation error
        guard let resourcesURL = Bundle.module.resourceURL?.appendingPathComponent("all-MiniLM-L6-v2", isDirectory: true) else {
            fatalError("Failed to find Resources folder in test bundle.")
        }
        self.configuration = LanguageModelConfigurationFromHub(modelFolder: resourcesURL)
        self.tokenizer = nil
        
        self.input_ids = try! MLMultiArray(shape: [inputDimention as NSNumber], dataType: .float32)
        self.attention_mask = try! MLMultiArray(shape: [inputDimention as NSNumber], dataType: .float32)

    }
    
    
    /// Build the model inputs from the input tokens
    /// - Parameter inputTokens: The input tokens
    internal func buildModelInputs(from inputTokens: [Int]) -> (MLMultiArray, MLMultiArray) {
        // Ensure the inputIds and attentionMask are inputDimension elements long
        let paddedInputTokens = inputTokens + [Int](repeating: 0, count: max(0, inputDimention - inputTokens.count))
        let truncatedInputTokens = Array(paddedInputTokens.prefix(inputDimention))

        let inputIds = MLMultiArray.from(truncatedInputTokens, dims: 2)

        var attentionMaskValues = [Int](repeating: 0, count: inputDimention)
        for (index, token) in truncatedInputTokens.enumerated() {
            attentionMaskValues[index] = token == 0 ? 0 : 1
        }

        let attentionMask = MLMultiArray.from(attentionMaskValues, dims: 2)

        return (inputIds, attentionMask)
    }

    
    /// The value of the feature with the given name
    /// - Parameter featureName: The name of the feature
    /// - Returns: The value of the feature
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input_ids") {
            return MLFeatureValue(multiArray: input_ids)
        }
        if (featureName == "attention_mask") {
            return MLFeatureValue(multiArray: attention_mask)
        }
        return nil
    }
    
    /// Encodes a single token into its corresponding embedding vector.
    /// - Parameter sentence: The token to be encoded.
    /// - Returns: The embedding vector for the given token.
    public func encodeSentence<S>(_ sentence: String) async -> [S] where S: HasDType {
        return await encodeSentence(sentence).asArray(S.self)
    }
    
    /// Encodes a sentence into a single embedding vector.
    /// - Parameter sentence: The sentence to be encoded.
    /// - Returns: The embedding vector representing the given sentence as an `MLXArray`
    public func encodeSentence(_ sentence: String) async -> MLXArray {
        
        if self.tokenizer == nil {
            tokenizer = try! await BertTokenizer(tokenizerConfig: configuration.tokenizerConfig!, tokenizerData: configuration.tokenizerData, addedTokens: [:])
        }
        guard let tokenizer else {
            fatalError("FAILED TO INITIALIZE TOKENIZER")
        }
        
        let tokens = tokenizer.tokenize(text: sentence)
        let ids = tokenizer.convertTokensToIds( tokens ).compactMap { $0 }
        
        if tokens.isEmpty || ids.isEmpty {
            return zeroes
        }
        
        let (inputIds, attentionMask) = buildModelInputs(from: ids)
        
        input_ids = inputIds
        attention_mask = attentionMask
                
        let outFeatures: MLFeatureProvider? = try! await model.prediction(from: self, options: MLPredictionOptions())
        
        guard let embeddings = outFeatures?.featureValue(for: outputType.rawValue)?.multiArrayValue else {
            return zeroes
        }

        guard embeddings.dataType == .float else {
            return zeroes
        }
        
        // Calculate the total number of elements in the MLMultiArray.
        let dataSize = embeddings.count * MemoryLayout<Float>.size
        let pointer = embeddings.dataPointer.bindMemory(to: Float.self, capacity: embeddings.count)
        let rawBufferPointer = UnsafeRawBufferPointer(start: UnsafeRawPointer(pointer), count: dataSize)

        return MLXArray(rawBufferPointer, [1,embeddings.count], type: Float.self)
    }
}

#endif
