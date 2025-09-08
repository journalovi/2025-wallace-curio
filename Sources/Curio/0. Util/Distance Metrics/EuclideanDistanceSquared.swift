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
import Accelerate
import MLX
import SwiftFaiss

public struct EuclideanDistanceSquared: DistanceMetric & Sendable {
    
    public var faissMetric: SwiftFaiss.MetricType { return .l2 }
    
 
    public init() {}
    
    /// Calculates the Euclidean distance between two vectors.
    /// - Parameters:
    ///   - lhs: The first vector (MLXArray).
    ///   - rhs: The second vector (MLXArray).
    /// - Returns: The Euclidean distance between the two vectors.
    @inlinable
    public func distance(between lhs: MLXArray, _ rhs: MLXArray) -> MLXArray {
        // Ensure dimensions match for the two vectors
        guard lhs.shape == rhs.shape else {
            fatalError("Arrays must have the same shape for distance calculation")
        }

        // Calculate the difference between the two vectors
        let difference = lhs - rhs

        // Square the difference and sum it up
        let sumOfSquares = difference.square().sum()

        // Return the square root of the summed squares for Euclidean distance
        return sumOfSquares
    }
    
    @inlinable
    public func batchDistance(between lhs: MLXArray, _ rhs: MLXArray) -> MLXArray {
        
        // Compute the difference for each row.
        let difference = lhs - rhs
        // Square the differences element-wise and sum across the feature axis.
        let sumOfSquares = difference.square().sum(axis: 1)
        
        return sumOfSquares
    }
    
    @inlinable
    public func fullPairwiseDistance(between lhs: MLX.MLXArray, _ rhs: MLX.MLXArray) -> MLX.MLXArray {
        // Compute squared L2 norms for each row.
        let lhsSquared = lhs.square().sum(axis: 1)    // Shape: [lhs.rows]
        let rhsSquared = rhs.square().sum(axis: 1)      // Shape: [rhs.rows]
        
        // Compute pairwise dot products.
        let dotProduct = lhs.matmul(rhs.T)
        
        // Compute squared Euclidean distances:
        // For each pair (i, j):
        //   ||lhs[i] - rhs[j]||² = ||lhs[i]||² + ||rhs[j]||² - 2 * dot(lhs[i], rhs[j])
        let distancesSquared = lhsSquared[0..., .newAxis] + rhsSquared[.newAxis, 0...] - 2 * dotProduct
        
        // Clip negative values (due to numerical inaccuracies) to zero.
        return clip(distancesSquared, min: 0, max: Float.greatestFiniteMagnitude)
    }


    
    @inlinable
    public func distance(between lhs: [Float], _ rhs: [Float]) -> Double {
        precondition(lhs.count == rhs.count, "Vectors must have the same length.")
        
        let count = vDSP_Length(lhs.count)
        var result: Float = 0.0
        
        // Cartesian Distance (Euclidean Distance)
        vDSP_distancesq(lhs, 1, rhs, 1, &result, count)
        return Double(result)
    }
}
