// Copyright (c) 2024 Jean Nordmann, Jim Wallace
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

/// # OpenAIEncoder
///
/// An asynchronous encoder that uses the OpenAI API for encoding sentences and tokens.
///
/// This actor conforms to the `SNLPEncoder` protocol and allows efficient asynchronous requests to the OpenAI API to generate text embeddings.
///
/// ## Overview
/// The `OpenAIEncoder` provides functionality to encode sentences or tokens using a specified OpenAI model. It manages rate limiting and retries to handle API errors, and allows multiple tokens to be encoded in parallel using `withTaskGroup` for improved efficiency.
///
/// ## Properties
/// - `secret_key`: The secret API token retrieved from the process environment.
/// - `dimensions`: The number of dimensions in the embedding, set to `1536`.
/// - `MODEL`: The OpenAI model name used for embeddings, currently set to "text-embedding-3-small".
/// - `openAI`: An instance of `OpenAI` initialized with the API token.
/// - `maxRetryCount`: Maximum number of retry attempts in case of rate limits or other failures.
/// - `retryWaitPeriod`: Wait period between retries, set to 20 seconds.
///
/// ## Methods
///
/// ### `init()`
/// Initializes the `OpenAIEncoder` actor with the specified model and API token.
/// - Note: This initializer will crash the application if the `OPEN_AI_SECRET_KEY` is not found in the process environment.
///
/// ### `encodeSentence(_:)`
/// Encodes a single sentence using the OpenAI model.
/// - Parameter sentence: A `String` representing the sentence to be encoded.
/// - Returns: An `MLXArray` representing the embedding of the sentence.
/// - Note: The function uses retry logic to handle rate limiting and ensures a fixed retry count before failing.
///
/// ### `encodeTokensInParallel(_:)`
/// Encodes multiple tokens in parallel to maximize throughput.
/// - Parameter tokens: An array of `String` tokens to be encoded.
/// - Returns: An array of `MLXArray` representing the embeddings of the tokens.
/// - Note: Errors are handled individually for each token, and a zeroed array is returned in case of an error.
///
/// ### `reduce(_:)`
/// This is a placeholder for future implementation to reduce encoded embeddings using an `SNLPReducer`.
///
/// ## Usage
///
/// Create an instance of `OpenAIEncoder` to use its encoding capabilities:
/// ```swift
/// let encoder = OpenAIEncoder()
/// let embedding = await encoder.encodeSentence("Example sentence.")
/// ```
///
/// ## Future Improvements
/// - Add support for multiple OpenAI models by introducing an enumeration for available models.
/// - Implement better rate limiting and retry strategies to manage high API usage effectively.

import Foundation
@preconcurrency import OpenAI
@preconcurrency import MLX

// The OpenAIEncoderAsync is an asynchronous encoder that uses the OpenAI API.
actor OpenAIEncoder: SNLPEncoder {

    let secret_key = ProcessInfo.processInfo.environment["OPEN_AI_SECRET_KEY"] ?? nil
        
    let dimensions: Int

    let MODEL: String
    let openAI: OpenAI

    // Rate limiting variables
    let maxRetryCount = 3
    let retryWaitPeriod: UInt64 = 20_000_000_000
    
    // TODO: We should work on a way to pull in different models from Open AI, likely an enum or struct to handle different choices
    // TODO: Currently, text-embedding-3-small compares well to other models for MTEB scores... so maybe not a rush
    init() {
        dimensions = 1536
        MODEL = "text-embedding-3-small"
        
        guard let secret_key = secret_key else {
            fatalError("Unable to fetch OPEN_AI_SECRET_KEY from ProcessInfo.")
        }
        
        openAI = OpenAI(apiToken: secret_key)
    }

    // TODO: We need some basic rate limiting here
    // TODO: OR, some awareness of when we've exceeded the limit, and need to re-submit the request after waiting a bit
    func encodeSentence(_ sentence: String) async  -> [Float] {
        var retryCount = 0
        while true {
            do {
                let query = EmbeddingsQuery(model: MODEL, input: sentence)
                let result = try await openAI.embeddings(query: query)
                return result.data[0].embedding.map { Float($0) }
            } catch {
                retryCount += 1
                if retryCount >= maxRetryCount {
                    //print("Max retry count reached.")
                    return zeroes
                }
                try! await Task.sleep(nanoseconds: retryWaitPeriod) // Wait until we try again
            }
        }
    }

    // Asynchronous function to fetch the encoding for Multiple tokens in parrallel.
    func encodeTokensInParallel(_ tokens: [String]) async -> [[Float]] {

        let results =  await withTaskGroup(of: [Float].self) { group in
            for token in tokens {
                group.addTask {
                    do {
                        let query = EmbeddingsQuery(model: self.MODEL, input: token)
                        let result = try await self.openAI.embeddings(query: query)
                        return result.data[0].embedding.map { Float($0) }
                    } catch {
                        //print("Error: \(error)")
                        return self.zeroes
                    }
                }
            }
            var encodingsTab: [[Float]] = []
            for await result in group {
                encodingsTab.append(result)
            }
            return encodingsTab
        }
        return results

    }
    
    func reduce(_ reducer: some SNLPReducer) async {
    }
    
}
