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

import MLX
import SwiftFaiss

public protocol DistanceMetric: Sendable {
    
    @inlinable
    func distance(between lhs: MLXArray, _ rhs: MLXArray) -> MLXArray
    
    @inlinable
    func batchDistance(between lhs: MLXArray, _ rhs: MLXArray) -> MLXArray
    
    @inlinable
    func fullPairwiseDistance(between lhs: MLXArray, _ rhs: MLXArray) -> MLXArray

    @inlinable
    func distance(between lhs: MLXArray, _ rhs: MLXArray) -> Double
    
    @inlinable
    func distance(between lhs: [Float], _ rhs: [Float]) -> Double
    
    @inlinable
    var faissMetric: SwiftFaiss.MetricType { get }
}

extension DistanceMetric {
    
    /// Calculates the distance between two vectors.
    /// - Parameters:
    ///  - lhs: The first vector (MLXArray).
    ///  - rhs: The second vector (MLXArray).
    /// - Returns: The distance between the two vectors.
    @inlinable
    public func distance(between lhs: MLXArray, _ rhs: MLXArray) -> Double {
        let d: MLXArray = distance(between: lhs, rhs)
        let f: Float = d.item()
        return Double(f)
    }
}
