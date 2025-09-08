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

/// A basic topic model that uses a clustering algorithm to cluster documents
struct LabeledTopicModel: SNLPTopicModel {
    var corpus: any SNLPCorpus
    var reducer: (any SNLPReducer)?
    var topics: [Topic]
        
    /// Initialize the basic topic model
    /// - Parameters:
    ///   - corpus: The corpus to use
    init(
        corpus: any SNLPCorpus,
        labels: [String],
        reducer: (any SNLPReducer)? = nil
    ) {
        self.corpus = corpus
        self.reducer = reducer
        topics = []

        // Create a unique set of all labels and a mapping from label to its index
        let uniqueLabels = Array(Set(labels)) // No need for flatMap; `labels` is already a [String]
        let labelToIndex: [String: Int] = Dictionary(uniqueLabels.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })

        // Create our lists of indices
        var indices = Array(repeating: [Int](), count: uniqueLabels.count)
        for (i, label) in labels.enumerated() {
            if let labelIndex = labelToIndex[label] {
                indices[labelIndex].append(i) // Add the document index to the corresponding label index
            }
        }

        // Create a new topic for each unique label
        for (label, index) in labelToIndex {
            let documents = indices[index]
            let newTopic = Topic(label: label, documents: documents, keywords: [:])
            topics.append(newTopic)
        }
    }

    
    /// Cluster and generate topics
    mutating func cluster() async {
        
        var copy = corpus.copy() // Let's be non-destructive
        
        if var reducer = reducer {
            debugPrint("Reducing: \(reducer.self)")
            await reducer.reduceCorpus(&copy)
            //await reducer.reduce(&copy.encodedDocumentsAsMLXArray)
        }
        
        self.corpus = copy
        await self.plot(topicModelName: "LABELED_TOPIC_MODEL")
    }
}
