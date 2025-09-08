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
struct BERTopic: SNLPTopicModel {
    var corpus: any SNLPCorpus
    var reducer: (any SNLPReducer)?
    var clusteringAlgorithm: any SNLPClusteringAlgorithm
    var topics: [Topic]
        
    /// Initialize the basic topic model
    /// - Parameters:
    ///   - corpus: The corpus to use
    ///   - clusteringAlgorithm: The clustering algorithm to use
    init(
        corpus: any SNLPCorpus
    ) async {
        self.corpus = corpus
        self.clusteringAlgorithm = HDBScan(minimumNeighbours: 5, minimumClusterSize: 15, mstConstructionMethod: .boruvka)
        self.reducer = await UMAP(targetDimensions: 5, numNeighbours: 15, minDistance: 0.25)
        topics = []
        
        await self.cluster()
    }
    
    /// Cluster and generate topics
    mutating func cluster() async {
        
        var copy = corpus.copy() // Let's be non-destructive
        
        if var reducer = reducer {
            debugPrint("Reducing: \(reducer.self)")
            await reducer.reduceCorpus(&copy)
            //await reducer.reduce(&copy.encodedDocumentsAsMLXArray)
        }
        
        debugPrint("Clustering: \(clusteringAlgorithm.self)")
        let (clusters, outliers) = await clusteringAlgorithm.getClusters(copy)
        
        for i in 0 ..< clusters.count {
            let newTopic = Topic(label: "Topic \(i)", documents: clusters[i], keywords: [:] )
            topics.append(newTopic)
        }
        
        if let outliers = outliers, !outliers.isEmpty {
            let unknownTopic = Topic(label: "Unknown", documents: outliers, keywords: [:] )
            topics.append(unknownTopic)
        }
        
        await generateKeywords()
        self.corpus = copy
        //await plot(topicModelName: "INTERNAL_COPY_CLUSTER")
    }
}
