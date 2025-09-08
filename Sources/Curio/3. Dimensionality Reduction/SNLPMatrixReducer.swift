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

protocol SNLPMatrixReducer: SNLPReducer {
    
    @inlinable
    func reduce(_ data: inout MLXArray) async
}
    
extension SNLPMatrixReducer {
    /// Reduce a corpus by returning a new corpus with reduced embeddings
    /// - Parameter corpus: The `SNLPCorpus` corpus to reduce
    /// - Returns: A new corpus with reduced embeddings
    func reduceCorpus<C: SNLPCorpus>(_ corpus: C) async -> C {
        precondition(corpus.encodedDocuments.allSatisfy { $0.count >= targetDimensions }, "All embeddings must be longer than target dimension.")

        var result = corpus.copy()
        await reduce(&result.encodedDocumentsAsMLXArray)
        result.dimensions = targetDimensions
        return result
    }

    /// Reduce a corpus in place
    /// - Parameter corpus: The `SNLPCorpus` corpus to reduce
    mutating func reduceCorpus<C: SNLPCorpus>(_ corpus: inout C) async {
        await reduce(&corpus.encodedDocumentsAsMLXArray)
        corpus.dimensions = targetDimensions
    }
}
