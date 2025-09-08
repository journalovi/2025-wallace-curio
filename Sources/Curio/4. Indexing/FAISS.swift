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

#if os(macOS)

import Foundation
import SwiftFaiss
import SwiftFaissC
import MLX
import Synchronization
//import OpenMP


// TODO: Expand to include other index types supported by Faiss
// TODO: Add test cases

/// A Faiss index for similarity search
public final class FAISS: SNLPIndex, @unchecked Sendable {

    /// The type of index for FAISS
    public enum indexType {
        case flat
        case ivf
        case lsh
        case pq
        case ivfpq
    }
    
    public var metric: any DistanceMetric
    internal let lock = Mutex<Bool>(false)
    
    internal var index: any BaseIndex
    public let type: indexType
    public var dimensions: Int
    public var nbits: Int
    public var m: Int
    public var nlist: Int

    /// Initialize a new FAISS index with default parameters
    public init(_ corpus: any SNLPCorpus) {
        self.metric = corpus.metric
        self.index = try! FlatIndex(d: corpus.dimensions, metricType: corpus.metric.faissMetric)
        self.type = .flat
        self.dimensions = corpus.dimensions
        self.nbits = 0
        self.m = 0
        self.nlist = 0
        
        insert(corpus.encodedDocuments)
    }
    
    /// Initialize a new FAISS index
    /// - Parameters:
    ///   - type: The type of index to create
    ///   - dimensions: The number of dimensions in the index
    ///   - nbits: The number of bits to use in the LSH index
    ///   - m: The number of subquantizers in the PQ index
    ///   - nlist: The number of cells in the IVF index
    ///   - metricType: The type of metric to use in the index
    public init(
        type: indexType = .flat,
        metric: DistanceMetric = EuclideanDistance(),
        dimensions: Int = 256,
        nbits: Int = 4,
        m: Int = 8,
        nlist: Int = 512
    ) {
        switch type {
        case .flat:
            self.index = try! FlatIndex(d: dimensions, metricType: metric.faissMetric)
        case .ivf:
            self.index = try! IVFFlatIndex(quantizer: FlatIndex(d: dimensions, metricType: metric.faissMetric), d: dimensions, nlist: nlist, metricType: metric.faissMetric)
        case .lsh:
            self.index = try! LSHIndex(d: dimensions, nbits: nbits)
        case .pq:
            self.index = try! AnyIndex.PQ(d: dimensions, m: m, metricType: metric.faissMetric)
        case .ivfpq:
            self.index = try! AnyIndex.IVFPQ(d: dimensions, m: m, metricType: metric.faissMetric)
        }
        
        self.type = type
        self.dimensions = dimensions
        self.nbits = nbits
        self.m = m
        self.nlist = nlist
        self.metric = metric
    }
    
    public init(_ anotherIndex: FAISS) {
        self.metric = anotherIndex.metric
        self.index = try! anotherIndex.index.clone()
        
        self.type = anotherIndex.type
        self.dimensions = anotherIndex.dimensions
        self.nbits = anotherIndex.nbits
        self.m = anotherIndex.m
        self.nlist = anotherIndex.nlist
    }
    
    public func count() -> Int {
        return index.count
    }
    
    public func insert(_ vectors: [[Float]]) {
        
        assert(vectors.allSatisfy { $0.count == dimensions })
        let initialSize = index.count
        
        //lock.withLock { _ in
        do {
            try index.add(vectors)
        } catch {
            print("Error inserting \(vectors.count) vectors: \(error)")
            for v in vectors {
                print(v)
            }
        }
        //}
        
        assert(index.count == vectors.count + initialSize)
    }

    
    /// Insert a new vector into the index
    /// - Parameter vector: The vector to insert (MLXArray)
    public func insert(_ vector: MLXArray) {
        
        assert(vector.shape[1] == dimensions)
        
        let vectorArray = vector.asArray(Float.self)
        let rowLength = vector.shape[1]
        var foldedArray: [[Float]] = []
        
        for i in stride(from: 0, to: vectorArray.count, by: rowLength) {
            let row = Array(vectorArray[i..<min(i + rowLength, vectorArray.count)])
            foldedArray.append(row)
        }
        
        let ids: [Int] = Array(0..<foldedArray.count)
        lock.withLock { _ in
            try! index.add(foldedArray, ids: ids) // FIXME: This method isn't currently supported
        }
        
        assert( index.count >= vector.shape[0] )
    }
    
    /// Find the nearest neighbors to the specified query vector
    /// - Parameters:
    ///   - query: The query vector (MLXArray)
    ///   - limit: The maximum number of neighbors to return
    /// - Returns: The labels of the nearest neighbors
    public func find(near query: MLXArray, limit: Int) -> [Int] {
        let results = lock.withLock { _ in
            try! index.search([query.asArray(Float.self)], k: limit)
        }
        
        assert( results.labels.flatMap{ $0 }.count >= limit)
        
        return results.labels.flatMap{ $0 }.filter { $0 != -1 }
    }
    
    public func find(near query: [Float], limit: Int) async -> [Int] {
        let results = lock.withLock { _ in
            try! index.search([query], k: limit)
        }
        
        assert( results.labels.flatMap{ $0 }.count >= limit)
        
        return results.labels.flatMap{ $0 }.filter { $0 != -1 }
    }
    
    
    public func clone() async -> FAISS {
        return FAISS(self)
    }
    

    public func rebuild(dimensions: Int, embeddings: [[Float]]) async {
        switch type {
        case .flat:
            self.index = try! FlatIndex(d: dimensions, metricType: metric.faissMetric)
        case .ivf:
            self.index = try! IVFFlatIndex(quantizer: FlatIndex(d: dimensions, metricType: metric.faissMetric), d: dimensions, nlist: nlist, metricType: metric.faissMetric)
        case .lsh:
            self.index = try! LSHIndex(d: dimensions, nbits: nbits)
        case .pq:
            self.index = try! AnyIndex.PQ(d: dimensions, m: m, metricType: metric.faissMetric)
        case .ivfpq:
            self.index = try! AnyIndex.IVFPQ(d: dimensions, m: m, metricType: metric.faissMetric)
        }
        self.dimensions = dimensions
        
        lock.withLock { _ in
            try! index.train(embeddings)
            insert(embeddings)
        }
    }
    
    
}

extension AnyIndex {
    /// Initialize a new HNSW index
    /// - Parameters:
    ///   - d: The number of dimensions
    ///   - m: The number of neighbors to consider
    ///   - metricType: The type of metric to use
    /// - Returns: A new HNSW index
    public static func HNSW(d: Int, m: Int, metricType: MetricType) throws -> AnyIndex {
        try AnyIndex(d: d, metricType: metricType, description: "HNSW,Flat")
    }
 }

extension FAISS: CustomStringConvertible {
    public var description: String {
        return """
        FAISS Index:
        - Type: \(type)
        - Metric: \(Swift.type(of: metric)) (\(metric.faissMetric))
        - Dimensions: \(dimensions)
        - NBits: \(nbits)
        - M: \(m)
        - NList: \(nlist)
        """
    }
}


#endif
