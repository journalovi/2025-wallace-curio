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
import MLX
import SwiftFaiss

protocol SNLPClusteringAlgorithm: Sendable {
    
    //var metric: DistanceMetric { get }
    
    @inlinable
    mutating func getClusters<C: SNLPCorpus>(_ corpus: C) async -> (clusters: [[Int]], outliers: [Int]?)
    
    @inlinable
    mutating func getClusters<C: SNLPIndexedCorpus>(_ corpus: C) async -> (clusters: [[Int]], outliers: [Int]?)
    
}

/// If we don't have an index already, build one
extension SNLPClusteringAlgorithm {
    
    @inlinable
    mutating func getClusters<C: SNLPCorpus>(_ corpus: C) async -> (clusters: [[Int]], outliers: [Int]?) {
        
        // Ensure the corpus is not already an SNLPIndexedCorpus to avoid recursion
        if let indexedCorpus = corpus as? any SNLPIndexedCorpus {
            return await getClusters(indexedCorpus)
        }
                
        let indexedCorpus = await IndexedCorpus(corpus)
        
        return await getClusters(indexedCorpus)
    }
}
