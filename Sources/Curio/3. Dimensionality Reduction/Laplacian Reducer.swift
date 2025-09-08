//
//  Laplacian Initializer.swift
//  SwiftNLP
//
//  Created by Jim Wallace on 2024-11-19.
//

import Cmlx
import MLX
import MLXLinalg
import Accelerate


/// A Principal Component Analysis (PCA) reducer
public struct LaplacianReducer: SNLPMatrixReducer {
    
    public let targetDimensions: Int
    public let approximate: Bool
    public let fsc: FuzzySimplicialComplex?
    
    /// Initialize a new PCA reducer with the specified target dimensions
    /// - Parameter targetDimensions: The number of dimensions to reduce to
    init(targetDimensions: Int) {
        self.targetDimensions = targetDimensions
        self.approximate = false
        self.fsc = nil
    }
    
    
    /// Initialize a new PCA reducer with the specified target dimensions
    /// - Parameters:
    ///   - targetDimensions: The number of dimensions to reduce to
    ///   - normalize: Whether to normalize the embeddings to lie on the unit sphere
    init(targetDimensions: Int, fsc: FuzzySimplicialComplex? = nil, approximate: Bool = false) {
        self.targetDimensions = targetDimensions
        self.approximate = approximate
        self.fsc = fsc
    }
        
    /// Reduce the data in place on an MLXArray
    /// - Parameter data: The data to reduce (MLXArray)
    @inlinable
    func reduce(_ data: inout MLX.MLXArray) {
        reduce(&data, approximate: self.approximate)
    }
    
    /// Reduce the data in place on an MLXArray
    /// - Parameters:
    ///   - data: The data to reduce (MLXArray)
    ///   - normalize: Whether to normalize the embeddings to lie on the unit sphere
    @inlinable
    func reduce(_ data: inout MLXArray, approximate: Bool = false) {
        
        // If we don't have an FSC, throw an error for now
        // TODO: we could build one if we were given a corpus
        guard let fsc else {
            fatalError("Laplacian reducer requires a Fuzzy Simplicial Complex.")
        }
        
        if approximate {
            // For now, let's just sample at 40% of total
            let numSamples = Int(Double(data.shape[0]) * 0.4)
            data = computeLaplacianEmbedding(fsc: fsc, numDimensions: targetDimensions, samples: numSamples)
        } else {
            data = computeLaplacianEmbedding(fsc: fsc, numDimensions: targetDimensions)
        }
    }
        
    @inlinable
    public func computeLaplacianEmbedding(fsc: FuzzySimplicialComplex, numDimensions: Int = 2, samples: Int? = nil) -> MLXArray {
               
        // Construct Affinity Graph (Affinity Matrix)
        var affinityMatrix: MLXArray
        if let samples {
            affinityMatrix  = fsc.generateSampledAffinityMatrix(sampleSize: samples)
        } else {
            affinityMatrix = fsc.generateAffinityMatrix()
        }
        
        // Compute the degree matrix (diagonal matrix with node degrees)
        let degreeMatrix = sum(affinityMatrix, axis: 1, stream: .gpu)
        
        // Compute D^(-1/2) for normalized Laplacian
        let D_inv_sqrt = clip( diag(1.0 / sqrt(degreeMatrix)), min: 0.0 )
        
        // Compute normalized Laplacian: L_norm = I - D^(-1/2) * A * D^(-1/2)
        let I = eye(affinityMatrix.shape[0])
        let laplacian = I - D_inv_sqrt.matmul(affinityMatrix, stream: .gpu).matmul(D_inv_sqrt, stream: .gpu)
        
        // Eigenvalue Decomposition
        // Compute the smallest `n_components` eigenvalues and corresponding eigenvectors
        // TODO: Switch to eigh() when it lands in Swift-MLX
        let (U, S, _) = svd(laplacian, stream: .cpu) // TODO: Not supported on GPU yet
                            
        // Find the smallest non-zero eigenvalues
        var nonZeroIndices: [Int] = []
        for v in S.enumerated().reversed() {
            if sum(v.element).item(Float.self) > 1e-6 {
                //print("\(v.offset)  -> \(sum(v.element).item(Float.self))")
                nonZeroIndices.append(v.offset)
            }
            if nonZeroIndices.count == numDimensions {
                break
            }
        }
        
        assert( nonZeroIndices.count  == numDimensions )
        
        let eigenvalues = U[0..., MLXArray(nonZeroIndices)]
        return eigenvalues
        
    }
    
}
