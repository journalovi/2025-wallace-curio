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

extension SNLPTopicModel {
    /// Calculate topic diversity based on Jaccard distance between top keywords.
    /// - Parameters:
    ///   - topK: Number of top keywords to consider for each topic.
    public func topicDiversity(topK: Int) -> Double {
        precondition(topK > 0, "topK must be greater than 0")
        
        var topicKeywordSets: [[String]] = []

        // Extract top keywords for each topic
        for topic in topics where topic.label != "Unknown" {
            let sortedKeywords = topic.keywords.sorted { $0.value > $1.value }
            let topTopicKeywords = sortedKeywords.prefix(topK).map { $0.key }
            topicKeywordSets.append(Array(topTopicKeywords))
        }

        // Calculate pairwise Jaccard distances
        var totalDistance = 0.0
        var pairCount = 0

        for i in 0..<topicKeywordSets.count {
            for j in (i + 1)..<topicKeywordSets.count {
                let distance = jaccardDistance(
                    set1: Set(topicKeywordSets[i]),
                    set2: Set(topicKeywordSets[j])
                )
                
                totalDistance += distance
                pairCount += 1
            }
        }

        // Calculate average Jaccard distance if pairs exist
        let averageDistance = pairCount > 0 ? totalDistance / Double(pairCount) : 0.0
        
        return averageDistance
    }

    // MARK: Distance Metrics
    
    /// Calculate Jaccard distance between two sets.
    /// - Parameters:
    ///   - set1: First set.
    ///   - set2: Second set.
    /// - Returns: Jaccard distance between the two sets.
    private func jaccardDistance(set1: Set<String>, set2: Set<String>) -> Double {
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        return 1.0 - (Double(intersection) / Double(union))
    }
}
