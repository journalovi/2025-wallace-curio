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

import MLX

extension SNLPTopicModel {
    /// Calculates the coherence score for the topic model.
    /// - Parameters:
    ///   - topK: The number of top keywords to consider for each topic.
    /// - Returns: The coherence score for the topic model.
    public func cosineSimilarityCoherence(topK: Int) async -> Double {
        precondition(topK > 1, "topK must be greater than 1")

        var topicCoherences: [Double] = []
        
        // Iterate through all topics
        for topic in topics where topic.label != "Unknown" {
            
            let metric = CosineSimilarity()
            var similarities: [Double] = []
            
            // Extract top keywords for the topic
            let sortedKeywords = topic.keywords.sorted { $0.value > $1.value }
            let topTopicKeywords = sortedKeywords.prefix(topK).map { $0.key }

            // Calculate coherence for all word pairs in the top keywords
            for i in 0..<(topTopicKeywords.count - 1) {
                for j in (i + 1)..<topTopicKeywords.count {
                    
                    let embeddingA = await corpus.documentEncoder.encodeSentence(topTopicKeywords[i])
                    let embeddingB = await corpus.documentEncoder.encodeSentence(topTopicKeywords[j])
                    
                    similarities.append( Double(metric.distance(between: MLXArray(embeddingA), MLXArray(embeddingB))) )
                    
                }
            }
            
            let topicCoherence = similarities.isEmpty ? 0.0 : similarities.reduce(0.0, +) / Double(similarities.count)
            topicCoherences.append(topicCoherence)
        }
        
        // Return the average coherence score
        return topicCoherences.isEmpty ? 0.0 : topicCoherences.reduce(0.0, +) / Double(topicCoherences.count)
    }
}

