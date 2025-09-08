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

public protocol SNLPIndexedCorpus: SNLPCorpus & Sendable {
    
    //associatedtype Index: SNLPIndex
    
    var index: any SNLPIndex { get set }
    
    @inlinable
    mutating func buildIndex() async
    
    @inlinable
    mutating func rebuildIndex() async
        
    @inlinable
    func searchFor(_ query: String, limit: Int?) async -> [Int]
    
    @inlinable
    func searchFor(_ query: MLXArray, limit: Int?) async -> [Int]
}

extension SNLPIndexedCorpus {
    /// Builds the index
    public mutating func buildIndex() async {
        await index.insert(encodedDocuments)
        assert (documents.count == encodedDocuments.count)
    }
    
    /// Builds the index
    public mutating func rebuildIndex() async {
        
        await self.index.rebuild(dimensions: dimensions, embeddings: encodedDocuments)
        
        assert (documents.count == encodedDocuments.count)
    }
    
    /// Searches for a query string in the corpus
    /// - Parameters:
    ///   - query: The query string
    ///   - limit: The maximum number of results to return
    /// - Returns: The indices of the documents most similar to the
    @inlinable
    public func searchFor(_ query: String, limit: Int?) async -> [Int] {
        let q = await documentEncoder.encodeSentence(query)
        return await index.find(near: q, limit: limit ?? Int.max)
    }
    
    /// Searches for a query vector in the corpus
    /// - Parameters:
    ///   - query: The query vector
    ///   - limit: The maximum number of results to return
    /// - Returns: The indices of the documents most similar to the query vector
    @inlinable
    public func searchFor(_ query: MLXArray, limit: Int?) async -> [Int] {
        return await index.find(near: query, limit: limit ?? Int.max)
    }
}
