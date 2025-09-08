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
//
// This is modified from the similarity-topology package by Jaden Geller under the MIT License.
//

import Foundation
import HNSWAlgorithm
import SimilarityMetric


/// A vector index that can be used to manage a graph of elements by key and level
public struct EphemeralVectorIndex<Key: BinaryInteger, Level: BinaryInteger, Metric: SimilarityMetric, Metadata> {
    private var nextKey: Key = 0
    public private(set) var vectors: [Metric.Vector] = []
    
    public typealias Graph = EphemeralGraph<Key, Level>
    
    public var graph = Graph()
    public var metric: Metric
    public var config: Config

    /// Initialize a new EphemeralVectorIndex with the specified metric and configuration
    /// - Parameters:
    ///   - metric: The metric to use for similarity calculations
    ///   - config: The configuration to use for the index
    public init(metric: Metric, config: Config) {
        self.metric = metric
        self.config = config
    }
    
    internal var manager: IndexManager<Graph, Metric> {
        .init(graph: graph, metric: metric, vector: { vectors[Int($0)] }, config: config)
    }

    public typealias Neighbor = NearbyVector<Graph.Key, Metric.Vector, Metric.Similarity>
    
    /// Find the nearest neighbors to the specified query vector
    /// - Parameters:
    ///   - query: The query vector
    ///   - limit: The maximum number of neighbors to return
    /// - Returns: The nearest neighbors as `Neighbor`
    public func find(near query: Metric.Vector, limit: Int) throws -> some Sequence<Neighbor> {
        try manager.find(near: query, limit: limit)
    }
    
    /// Insert a new vector into the index
    /// - Parameters:
    ///   - vector: The vector to insert
    ///   - generator: The random number generator to use for the index
    ///  - Returns: The key for the inserted vector
    public mutating func insert(_ vector: Metric.Vector, using generator: inout some RandomNumberGenerator) -> Key {
        vectors.append(vector)
        let key = nextKey
        nextKey += 1
        
        manager.insert(vector, forKey: key, using: &generator)
        return key
    }
}
