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
import SimilarityMetric
import Accelerate

public struct CartesianDistanceMetric<Vector: Collection & Codable>: SimilarityMetric where Vector.Element: BinaryFloatingPoint & Sendable {
    
    /// Calculates the Euclidean distance between two vectors.
    /// - Parameters:
    ///   - someItem: The first vector.
    ///   - otherItem: The second vector.
    /// - Returns: The Euclidean distance between the two vectors.
    @inlinable @inline(__always)
    public func similarity(between someItem: Vector, _ otherItem: Vector) -> Vector.Element {
        precondition(someItem.count == otherItem.count, "Vectors must be of equal length")
        
        // Calculate the sum of squared differences
        let sumOfSquares = zip(someItem, otherItem).reduce(into: Vector.Element.zero) { result, pair in
            let (left, right) = pair
            let diff = left - right
            result += diff * diff
        }
        
        return Vector.Element(sqrt(Double(sumOfSquares)))
    }
}

extension CartesianDistanceMetric where Vector.Element == Float {
    
    /// Calculates the Euclidean distance between two vectors.
    /// - Parameters:
    ///   - someItem: The first vector.
    ///   - otherItem: The second vector.
    /// - Returns: The Euclidean distance between the two vectors as a Float.
    @inlinable @inline(__always)
    public func similarity(between someItem: [Float], _ otherItem: [Float]) -> Float {
        precondition(someItem.count == otherItem.count, "Vectors must be of equal length")
        var result: Float = 0
        vDSP_distancesq(someItem, 1, otherItem, 1, &result, vDSP_Length(someItem.count))
        return result
    }
}

extension CartesianDistanceMetric where Vector.Element == Double {
    
    /// Calculates the Euclidean distance between two vectors.
    /// - Parameters:
    ///   - someItem: The first vector.
    ///   - otherItem: The second vector.
    /// - Returns: The Euclidean distance between the two vectors as a Double.
    @inlinable @inline(__always)
    public func similarity(between someItem: [Double], _ otherItem: [Double]) -> Double {
        precondition(someItem.count == otherItem.count, "Vectors must be of equal length")
        var result: Double = 0
        vDSP_distancesqD(someItem, 1, otherItem, 1, &result, vDSP_Length(someItem.count))
        return result
    }
}
