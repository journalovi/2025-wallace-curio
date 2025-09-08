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

public struct CosineDissimilarity: DistanceMetric & Sendable {
    
    public var faissMetric: SwiftFaiss.MetricType { return .innerProduct }
    
    public init() {}
    
    /// Calculates the cosine dissimilarity between two vectors.
    /// - Parameters:
    ///   - lhs: The first vector (MLXArray).
    ///   - rhs: The second vector (MLXArray).
    /// - Returns: The cosine dissimilarity between the two vectors.
    @inlinable
    public func distance(between lhs: MLXArray, _ rhs: MLXArray) -> MLXArray {
        // Ensure dimensions match for the two vectors
        guard lhs.shape == rhs.shape else {
            fatalError("Arrays must have the same shape for cosine similarity calculation")
        }
        
        // Calculate the dot product between lhs and rhs
        let dotProduct = lhs.T.matmul(rhs) // Assuming lhs and rhs are 1D vectors
        
        // Calculate the magnitudes (L2 norms) of lhs and rhs
        let lhsNorm = lhs.square().sum().sqrt()
        let rhsNorm = rhs.square().sum().sqrt()
        
        // Compute cosine similarity
        let cosineSimilarity = dotProduct / (lhsNorm * rhsNorm)
        
        return 1 - cosineSimilarity
    }
    
    @inlinable
    public func batchDistance(between lhs: MLXArray, _ rhs: MLXArray) -> MLXArray {

        // Compute the dot product row-wise.
        let dotProduct = (lhs * rhs).sum(axis: 1)
        
        // Compute the L2 norm for each row of lhs and rhs.
        let lhsNorm = (lhs.square().sum(axis: 1)).sqrt()
        let rhsNorm = (rhs.square().sum(axis: 1)).sqrt()
        
        // Compute cosine similarity for each row.
        let cosineSimilarity = dotProduct / (lhsNorm * rhsNorm)
        
        // Return cosine dissimilarity: 1 minus cosine similarity.
        return 1 - cosineSimilarity
    }

    @inlinable
    public func fullPairwiseDistance(between lhs: MLX.MLXArray, _ rhs: MLX.MLXArray) -> MLX.MLXArray {
        // Compute pairwise dot products using matrix multiplication.
        let dotProduct = lhs.matmul(rhs.T)
        
        // Compute the L2 norm for each row.
        let lhsNorm = (lhs.square().sum(axis: 1)).sqrt()   // Shape: [lhs.rows]
        let rhsNorm = (rhs.square().sum(axis: 1)).sqrt()     // Shape: [rhs.rows]
        
        // Reshape norms for broadcasting.
        let lhsNormReshaped = lhsNorm[0..., .newAxis]       // Shape: [lhs.rows, 1]
        let rhsNormReshaped = rhsNorm[.newAxis, 0...]         // Shape: [1, rhs.rows]
        
        // Compute cosine similarity matrix, with clipping for numerical stability.
        let cosineSimilarity = clip(dotProduct / (lhsNormReshaped * rhsNormReshaped), min: -1, max: 1)
        
        // Compute cosine dissimilarity as 1 - cosine similarity.
        return 1 - cosineSimilarity
    }
    
    @inlinable
    public func distance(between lhs: [Float], _ rhs: [Float]) -> Double {
        return 1 - CosineSimilarity().distance(between: lhs, rhs)
    }
}
