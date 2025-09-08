//
//  Fuzzy Simplicial Complex + Affinity Matrix.swift
//  SwiftNLP
//
//  Created by Jim Wallace on 2024-11-19.
//

import MLX

extension FuzzySimplicialComplex {
    
    // Function to generate an affinity matrix as [[Float]]
    @inlinable
    public func generateAffinityMatrix() -> [[Float]] {
        var affinityMatrix = Array(repeating: Array(repeating: Float(0.0), count: neighbours.count), count: neighbours.count)

        for i in 0 ..< neighbours.count {
            for edge in neighbours[i] {
                let j = edge.b
                affinityMatrix[i][j] = Float(edge.weight)
            }
        }

        assert( affinityMatrix.count == neighbours.count )
        assert( affinityMatrix.first!.count == neighbours.count )
        
        return affinityMatrix
    }
    
    // Function to generate an affinity matrix for a representative sample as [[Float]]
    @inlinable
    public func generateSampledAffinityMatrix(sampleSize: Int) -> [[Float]] {
        // Ensure that the sample size is not greater than the number of nodes
        let sampleSize = min(sampleSize, neighbours.count)
        
        // Randomly select 'sampleSize' nodes from the neighbours
        var selectedIndices = Set<Int>()
        while selectedIndices.count < sampleSize {
            let randomIndex = Int.random(in: 0..<neighbours.count)
            selectedIndices.insert(randomIndex)
        }
        
        // Convert set to array for indexed access
        let sampledIndices = Array(selectedIndices)
        
        // Create an affinity matrix for the sampled nodes
        var affinityMatrix = Array(repeating: Array(repeating: Float(0.0), count: sampleSize), count: sampleSize)
        
        // Populate the affinity matrix using the selected nodes
        for i in 0 ..< sampleSize {
            let originalIndex = sampledIndices[i]
            for edge in neighbours[originalIndex] {
                let j = edge.b
                // Ensure the sampled index is in the selected set
                if let sampledIndex = sampledIndices.firstIndex(of: j) {
                    affinityMatrix[i][sampledIndex] = Float(edge.weight)
                }
            }
        }
        
        assert(affinityMatrix.count == sampleSize)
        assert(affinityMatrix.first!.count == sampleSize)
        
        return affinityMatrix
    }
    
    @inlinable
    public func generateAffinityMatrix() -> MLXArray {
        return MLXArray( generateAffinityMatrix().flatMap{$0}, [ neighbours.count, neighbours.count] )
    }
    
    @inlinable
    public func generateSampledAffinityMatrix(sampleSize: Int) -> MLXArray {
        return MLXArray( generateSampledAffinityMatrix(sampleSize: sampleSize).flatMap{$0}, [ sampleSize, sampleSize] )
    }

}
