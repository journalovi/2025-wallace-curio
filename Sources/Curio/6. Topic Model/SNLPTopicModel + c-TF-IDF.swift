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

extension SNLPTopicModel {
    
    /**
     Generates a list of keywords for each topic in the model using the c-TF-IDF method.
     
     - Parameter numberOfKeywords: An optional parameter to specify the maximum number of keywords to generate for each topic. Defaults to 10.
     
     The function first calculates term frequencies (TF) for each topic, then computes inverse document frequency (IDF) across all topics, and finally calculates c-TF-IDF scores. The resulting keywords are sorted, and only the specified number of keywords is retained for each topic.
     */
    mutating func generateKeywords(numberOfKeywords: Int? = 10) async {
 
        var cTFs: [[String: Double]] = []
        var idf: [String: Double] = [:]
        
        // Calculate cTFs
        for topic in topics {
            cTFs.append(calculateTF(topic.documents))
        }
        
        // Calculate IDF
        idf = calculateIDF(cTFs)
        
        // Calculate our c-TF-IDFs for each topic
        for (idx, _ ) in topics.enumerated() {
            topics[idx].keywords = calcualatecCTFIDF(tf: cTFs[idx], idf: idf)
        }
        
        // If numberOfKeywords is provided cut things off, we don't need a huge number of keywords
        if let numberOfKeywords = numberOfKeywords {
            for (idx, _ ) in topics.enumerated() {
                let tmp = topics[idx].keywords.sorted { $0.value > $1.value }
                    .prefix(numberOfKeywords)
                topics[idx].keywords = Dictionary(uniqueKeysWithValues: tmp.map { ($0.key, $0.value) } )
            }
        }
 
    }
    
    /**
     Calculates the term frequency (TF) for a given set of documents.
     
     - Parameter documents: An array of document identifiers for which to calculate term frequency.
     - Returns: A dictionary mapping each term to its normalized frequency.
     
     This function computes the raw frequency of terms, applies sublinear scaling to reduce the effect of very frequent terms, and normalizes by the maximum term frequency to emphasize unique terms.
     */
    internal func calculateTF(_ documents: [Int]) -> [String : Double] {
        var termFrequency = [String: Double]()
        var totalTerms = 0
        
        for docId in documents {
            let keywords = SNLPTokenization.applyTextProcessingWithLemmatizationAndPOS( (corpus.documents[_offset: docId]).fullText, tokenFilters: NLTKStopwordSet, nGramRange: 1...1 )
            for word in keywords {
                termFrequency[word, default: 0] += 1.0
                totalTerms += 1
            }
        }
        
        // Apply sublinear TF scaling to dampen the impact of very frequent terms
        for (term, frequency) in termFrequency {
            termFrequency[term] = 1 + log(frequency)
        }
        
        // Normalize by maximum term frequency in the document
        // This helps to emphasize terms that are more unique within the document
        let maxTermFrequency = termFrequency.values.max() ?? 1.0
        for (term, frequency) in termFrequency {
            termFrequency[term] = frequency / maxTermFrequency
        }
        
        return termFrequency
    }
    
    /**
     Calculates the inverse document frequency (IDF) across all topics.
     
     - Parameter classTermFrequencies: An array of dictionaries representing term frequencies for each topic.
     - Returns: A dictionary mapping each term to its inverse document frequency.
     
     This function counts how many topics each term appears in and calculates the IDF value with smoothing to prevent division by zero and extreme values.
     */
    internal func calculateIDF(_ classTermFrequencies: [[String : Double]]) -> [String : Double] {
        var inverseDocumentFrequency = [String: Double]()
        let numberOfClasses = Double(classTermFrequencies.count)
        
        // Step 1: Count the number of topics each term appears in
        // This helps determine how widespread a term is across different topics
        var termInTopicCount = [String: Int]()
        for topicTerms in classTermFrequencies {
            for term in topicTerms.keys {
                termInTopicCount[term, default: 0] += 1
            }
        }
        
        // Step 2: Calculate IDF based on topic occurrences, adding smoothing
        // Smoothing prevents division by zero and extreme values for terms that appear in every topic
        for (term, topicCount) in termInTopicCount {
            inverseDocumentFrequency[term] = log(1 + ((numberOfClasses + 1) / (Double(topicCount) + 1)))
        }
        
        return inverseDocumentFrequency
    }
    
    /**
     Calculates the combined TF-IDF score for each term in a topic.
     
     - Parameters:
        - tf: A dictionary containing the term frequencies for a topic.
        - idf: A dictionary containing the inverse document frequencies for all terms.
     - Returns: A dictionary mapping each term to its c-TF-IDF score.
     
     This function multiplies the term frequency (TF) by the inverse document frequency (IDF) to calculate the c-TF-IDF score for each term, highlighting terms that are both frequent in the topic and rare across other topics.
     */
    internal func calcualatecCTFIDF(tf: [String : Double], idf: [String : Double]) -> [String : Double] {
        var cTFIDF = [String: Double]()
        
        // Calculate c-TF-IDF by multiplying term frequency by inverse document frequency
        for (term, tfValue) in tf {
            if let idfValue = idf[term] {
                cTFIDF[term] = tfValue * idfValue
            }
        }
        
        return cTFIDF
    }
    
    /**
     Filters keywords based on a dynamic threshold.
     
     - Parameters:
        - keywords: A dictionary mapping each keyword to its score.
        - thresholdFactor: A factor that determines the threshold relative to the maximum score.
     - Returns: A dictionary containing only the keywords whose score exceeds the calculated threshold.
     
     This function dynamically filters out less significant keywords by keeping only those that have a score above a certain percentage of the maximum score.
     */
    internal func filterKeywords(keywords: [String: Double], thresholdFactor: Double) -> [String: Double] {
        let maxScore = keywords.values.max() ?? 0.0
        let threshold = maxScore * thresholdFactor
        return keywords.filter { $0.value > threshold }
    }
}
