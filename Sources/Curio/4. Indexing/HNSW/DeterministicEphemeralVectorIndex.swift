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
import PriorityHeapModule
import PriorityHeapAlgorithms
import HNSWAlgorithm

/// A deterministic emphermal vector index
public struct DeterministicEphemeralVectorIndex<Vector: Collection & Codable>: @unchecked Sendable where Vector: Sendable, Vector.Element: BinaryFloatingPoint & Sendable {
    
    public typealias Index = EphemeralVectorIndex<Int, Int, CartesianDistanceMetric<Vector>, Void>
    public var base: Index
    public var typicalNeighborhoodSize: Int
    
    private var vectorRNG: RandomNumberGenerator
    private var graphRNG: RandomNumberGenerator
    
    /// Initialize a new DeterministicEphemeralVectorIndex
    /// - Parameter typicalNeighborhoodSize: The typical neighborhood size
    public init(typicalNeighborhoodSize: Int = 20) {
        base = .init(
            metric: CartesianDistanceMetric<Vector>(),
            config: .unstableDefault(typicalNeighborhoodSize: typicalNeighborhoodSize)
        )
        self.typicalNeighborhoodSize = typicalNeighborhoodSize
        self.vectorRNG = SeedableRNG(seed: 0)
        self.graphRNG = SeedableRNG(seed: 1)
    }
    
    /// Find the nearest neighbors to the query vector
    /// - Parameters:
    ///   - query: The query vector
    ///   - limit: The maximum number of neighbors to return
    ///   - exact: Whether to use exact search
    /// - Returns: The nearest neighbors as `Index.Neighbor`
    @inlinable
    public func find(near query: Vector, limit: Int, exact: Bool = false) throws -> [Index.Neighbor] {
        if exact {
            return Array(PriorityHeap(base.vectors.enumerated().map {
                let similarity = base.metric.similarity(between: query, $0.element)
                return NearbyVector(id: $0.offset, vector: $0.element, priority: similarity)
            }).descending().prefix(limit))
        } else {
            return Array(try base.find(near: query, limit: limit))
        }
    }
    
    /// Generate a random vector using the vector RNG
    /// - Parameter range: The range of the vector
    /// - Returns: A randomly generated point
    public mutating func generateRandom(range: ClosedRange<Double>) -> CGPoint {
        CGPoint(
            x: .random(in: range, using: &vectorRNG),
            y: .random(in: range, using: &vectorRNG)
        )
    }
    
    /// Insert a vector into the index
    /// - Parameter vector: The vector to insert
    /// - Returns: The key of the inserted vector
    @discardableResult
    public mutating func insert(_ vector: Vector) -> Int {
        return base.insert(vector, using: &graphRNG)
    }
}
