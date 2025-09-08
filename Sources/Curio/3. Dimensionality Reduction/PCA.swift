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
import MLXLinalg

/// A Principal Component Analysis (PCA) reducer
public struct PCA: SNLPReducer {
    
    
    public let targetDimensions: Int
    let normalize: Bool

    /// Initialize a new PCA reducer with the specified target dimensions
    /// - Parameter targetDimensions: The number of dimensions to reduce to
    init(targetDimensions: Int) {
        self.targetDimensions = targetDimensions
        self.normalize = false
    }
    
    /// Initialize a new PCA reducer with the specified target dimensions
    /// - Parameters:
    ///   - targetDimensions: The number of dimensions to reduce to
    ///   - normalize: Whether to normalize the embeddings to lie on the unit sphere
    init(targetDimensions: Int, normalize: Bool = false) {
        self.targetDimensions = targetDimensions
        self.normalize = normalize
    }
    
    
    /// Reduce a corpus by returning a new corpus with reduced embeddings
    /// - Parameter corpus: The `SNLPCorpus` corpus to reduce
    /// - Returns: A new corpus with reduced embeddings
    func reduceCorpus<C: SNLPCorpus>(_ corpus: C) async -> C {
        precondition(corpus.encodedDocuments.allSatisfy { $0.count >= targetDimensions }, "All embeddings must be longer than target dimension.")
        
        var result = corpus.copy()
        var mlx = corpus.encodedDocumentsAsMLXArray
        reduce(&mlx)
        result.encodedDocumentsAsMLXArray = mlx
        result.dimensions = targetDimensions
        return result
    }
    
    /// Reduce a corpus in place
    /// - Parameter corpus: The `SNLPCorpus` corpus to reduce
    mutating func reduceCorpus<C: SNLPCorpus>(_ corpus: inout C) async {
        var mlx = corpus.encodedDocumentsAsMLXArray
        reduce(&mlx)
        corpus.encodedDocumentsAsMLXArray = mlx
        corpus.dimensions = targetDimensions
    }
    
//    /// Reduce the data in place on an MLXArray
//    /// - Parameter data: The data to reduce (MLXArray)
//    @inlinable
//    func reduce(_ data: inout MLX.MLXArray) {
//        reduce(&data, normalize: false)
//    }

    /// Reduce the data in place on an MLXArray
    /// - Parameters:
    ///   - data: The data to reduce (MLXArray)
    ///   - normalize: Whether to normalize the embeddings to lie on the unit sphere
    @inlinable
    func reduce(_ data: inout MLXArray) {
        
        // Z-score normalization
        let mean = mean(data, axis: 0)
        let std = std(data, axis: 0)
        data = (data - mean) / maximum(std, 1e-18) // Centering data in place

        // Covariance
        let covMat = data.transposed().matmul(data, stream: .gpu) / Float(data.shape[0] - 1)
        let regularization = 1e-5
        let covMatRegularized = covMat + regularization * MLXArray.eye(covMat.shape[0])
        
        // Extract principal components
        let (u, _, _) = MLXLinalg.svd(covMatRegularized, stream: .cpu)
        let principalComponents = u[0..<targetDimensions]

        // Apply PCA reduction in place
        data = data.matmul(principalComponents.transposed(), stream: .gpu)
    }
    
    /// Reduce the data in place on an MLXArray
    /// - Parameters:
    ///   - data: The data to reduce (MLXArray)
    ///   - normalize: Whether to normalize the embeddings to lie on the unit sphere
    @inlinable
    func reduce(_ data: inout MLXArray, explainedVariance: Float) {
        
        // Z-score normalization
        let mean = mean(data, axis: 0)
        let std = std(data, axis: 0)
        data = (data - mean) / maximum(std, 1e-18) // Centering data in place

        // Covariance
        let covMat = data.transposed().matmul(data, stream: .gpu) / Float(data.shape[0] - 1)
        let regularization = 1e-5
        let covMatRegularized = covMat + regularization * MLXArray.eye(covMat.shape[0])
        
        // Extract principal components
        let (u, s, _) = MLXLinalg.svd(covMatRegularized, stream: .cpu)
        
        let totalVariance = s.sum()
        var cumulativeVariance: Float = 0.0
        var dimensionsToKeep = 0
        for (_, value) in s.enumerated() {
            cumulativeVariance += value.item()
            dimensionsToKeep += 1
            
            if (cumulativeVariance / totalVariance).item() >= explainedVariance {
                break
            }
        }
        
        
        let principalComponents = u[0..<dimensionsToKeep]

        // Apply PCA reduction in place
        data = data.matmul(principalComponents.transposed(), stream: .gpu)
    }
}
