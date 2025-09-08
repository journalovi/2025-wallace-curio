//
//  DotProduct.swift
//  SwiftNLP
//
//  Created by Jim Wallace on 2024-11-15.
//

import MLX
import Accelerate
import SwiftFaiss

public struct DotProduct: DistanceMetric & Sendable {
    
    public var faissMetric: SwiftFaiss.MetricType { return .innerProduct }
    
    public init() {}
    
    /// Calculates the dot product between two vectors.
    /// - Parameters:
    ///   - lhs: The first vector (MLXArray).
    ///   - rhs: The second vector (MLXArray).
    /// - Returns: The dot product between the two vectors.
    @inlinable
    public func distance(between lhs: MLXArray, _ rhs: MLXArray) -> MLXArray {
        // Ensure dimensions match for the two vectors
        guard lhs.shape == rhs.shape else {
            fatalError("Arrays must have the same shape for dot product calculation")
        }
        
        // Calculate the dot product between lhs and rhs
        return lhs.T.matmul(rhs, stream: .gpu) // Assuming lhs and rhs are 1D vectors
    }
    
    @inlinable
    public func batchDistance(between lhs: MLXArray, _ rhs: MLXArray) -> MLXArray {
        
        // Compute the element-wise product, then sum over axis 1 to get row-wise dot products.
        return (lhs * rhs).sum(axis: 1)
    }
    
    @inlinable
    public func fullPairwiseDistance(between lhs: MLX.MLXArray, _ rhs: MLX.MLXArray) -> MLX.MLXArray {
        // For the dot product metric, simply compute the matrix multiplication.
        // Each element (i, j) in the resulting matrix is the dot product of lhs[i] and rhs[j].
        return lhs.matmul(rhs.T)
    }

    
    @inlinable
    public func distance(between lhs: [Float], _ rhs: [Float]) -> Double {
        precondition(lhs.count == rhs.count, "Vectors must have the same length.")
        
        let count = vDSP_Length(lhs.count)
        var result: Float = 0.0
        
        // Dot Product
        vDSP_dotpr(lhs, 1, rhs, 1, &result, count)
        return Double(result)
    }
}
