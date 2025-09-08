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

public struct InMemoryCorpus<Item: SNLPDataItem & Sendable>: SNLPCorpus & Sendable {
    
    public var dimensions: Int
    public var documentEncoder: any SNLPEncoder
    public var documents: [Item]
    public var encodedDocuments: [[Float]]
    public var count: Int { documents.count }
    public var metric: DistanceMetric
            
    /// Initialize a new in-memory corpus with the specified encoder
    /// - Parameters:
    ///   - item: The type of item to store in the corpus
    ///   - encoder: The encoder to use for encoding documents
    ///   - decoder: The decoder to use for decoding documents
    init(item: Item.Type = String.self, encoder: any SNLPEncoder = CoreMLEncoder(), metric: DistanceMetric = EuclideanDistance()) {
        documents = []
        documentEncoder = encoder
        encodedDocuments = [[Float]]()
        dimensions = encoder.dimensions
        self.metric = metric
    }
}
