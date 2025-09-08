// Copyright (c) 2024 Jim Wallace
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

import Foundation
import Accelerate
import Tokenizers
@preconcurrency import Hub
@preconcurrency import MLX

/// A context-free encoder that provides vector representations for words and sentences using pre-computed embeddings.
/// This encoder uses pre-computed GloVe embeddings to convert tokens or sentences into numerical representations.
/// It is part of the NLP system that implements the `SNLPEncoder` protocol, facilitating text embedding and encoding operations.
/// `ContextFreeEncoder` is a structure that implements the `SNLPEncoder` protocol.
/// It provides functionality to encode tokens and sentences into vector representations using pre-computed word embeddings.
struct M2VEncoder: SNLPEncoder, @unchecked Sendable {
    
    /// A dictionary that maps tokens to their corresponding embedding vectors.
    internal let embeddings: [[Float]]
    internal let metadata: [String: Any]
    
    /// The number of tokens in the dictionary.
    var count: Int { embeddings.count }
    
    /// The dimensionality of the embeddings used.
    var dimensions: Int
    
    
    internal var configuration: LanguageModelConfigurationFromHub
    internal var tokenizer: BertTokenizer
    
    
    /// Default initializer that sets up the encoder with the M2V_base_output embeddings.
    init() async {
        // dummy initialization needed here to avoid compilation error
        guard let resourcesURL = Bundle.module.resourceURL?.appendingPathComponent("potion-base-32m", isDirectory: true) else {
            fatalError("Failed to find potion-base-8m folder in test bundle.")
        }
        await self.init(modelURL: resourcesURL)
    }
    
    
    init(modelURL: URL) async {
        
        self.configuration = LanguageModelConfigurationFromHub(modelFolder: modelURL)
        self.tokenizer = try! await BertTokenizer(tokenizerConfig: configuration.tokenizerConfig!, tokenizerData: configuration.tokenizerData, addedTokens: [:])
        
        dimensions = try! await configuration.modelConfig.dictionary["hidden_dim"] as! Int
        
        // Load embeddings data from model file
        let embeddingsURL = modelURL.appending(component: "model.safetensors")
        
        let (safetensors, metadata) = try! MLX.loadArraysAndMetadata(url: embeddingsURL.absoluteURL)
        let safetensorData = safetensors["embeddings"]!.asArray(Float.self)
        
        // Convert the embeddings to [[Float]]
        let rows = safetensors["embeddings"]!.shape[0]
        let columns = safetensors["embeddings"]!.shape[1]
        self.embeddings = (0..<rows).map { rowIndex in
            Array(safetensorData[rowIndex * columns..<(rowIndex + 1) * columns])
        }
        
        // Save our meta data
        self.metadata = metadata
    }
        
        

    /// Asynchronously encodes a single token into its corresponding embedding vector.
    /// - Parameter token: The token to be encoded.
    /// - Returns: The embedding vector for the given token, or zeroes if not found.
    @inlinable
    func encodeToken(_ token: String) async -> [Float] {
        return embeddings[tokenizer.convertTokenToId(token) ?? 0]
    }
    
    /// Asynchronously encodes a sentence into a single embedding vector by summing up the vectors of each token.
    /// - Parameter sentence: The sentence to be encoded.
    /// - Returns: The embedding vector representing the given sentence.
    @inlinable
    func encodeSentence(_ sentence: String) async -> [Float] {
        // Initialize result with zeroes
        var result = [Float](repeating: 0.0, count: dimensions)
        
        // Tokenize and convert tokens to IDs
        let ids = tokenizer.convertTokensToIds(tokenizer.tokenize(text: sentence)).compactMap { $0 }
        
        // Perform vector addition for each embedding corresponding to token IDs
        for id in ids {
            let embedding = embeddings[id]
            vDSP_vadd(result, 1, embedding, 1, &result, 1, vDSP_Length(dimensions))
        }
        
        // Divide by the number of tokens to get the average if there are any tokens
        if ids.count > 0 {
            var count = Float(ids.count)
            vDSP_vsdiv(result, 1, &count, &result, 1, vDSP_Length(dimensions))
        }
        
        return result
    }
}
