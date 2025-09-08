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
@preconcurrency import MLX


public struct IndexedCorpus<Item: SNLPDataItem & Sendable>: SNLPIndexedCorpus & Sendable  {
    
    
    public var documentEncoder: any SNLPEncoder
    public var index: any SNLPIndex
    public var metric: DistanceMetric = EuclideanDistance()
    public var dimensions: Int
    
    public var documents = [Item]()
    public var encodedDocuments = [[Float]]()
    
    /// Initializes a new `IndexedCorpus` with the specified encoder and index.
    /// - Parameters:
    ///   - item: The type of item to store in the corpus.
    ///   - encoder: The encoder to use to encode documents.
    ///   - index: The index to use to store and search documents.
    public init(
        item: Item.Type = String.self,
        encoder: any SNLPEncoder = CoreMLEncoder(),
        metric: DistanceMetric = EuclideanDistance()
    ) {
        documents = []
        encodedDocuments = []
        dimensions = encoder.dimensions
        self.metric = metric
        
        documentEncoder = encoder
        index = FAISS(type: .flat, metric: metric, dimensions: dimensions)
        encodedDocuments = [[Float]]()
    }
    
    public init( _ corpus: any SNLPCorpus<Item>) async {
     
        documents = corpus.documents
        documentEncoder = corpus.documentEncoder
        encodedDocuments =  corpus.encodedDocuments
        dimensions = corpus.dimensions
        metric = corpus.metric
        
        self.index = FAISS(corpus)
        
        assert( corpus.count == count )
        assert( corpus.documents.count == documents.count )
        assert( corpus.encodedDocuments.count == encodedDocuments.count )
    }
}
