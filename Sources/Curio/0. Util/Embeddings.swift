//
//  Embeddings.swift
//  Curio
//
//  Created by Jim Wallace on 2024-12-06.
//

import Accelerate

public struct EmbeddingUtils {
    /// L2 normalizes a vector of Floats in place.
    /// - Parameter vector: The input vector that needs to be L2 normalized.
    @inlinable
    public static func l2Normalize(_ vector: inout [Float]) {
        guard !vector.isEmpty else {
            fatalError("Unable to normalize an empty vector")
        }
        let vDSPLength = vDSP_Length(vector.count)
        
        // Calculate the L2 norm (Euclidean norm) of the vector
        var norm: Float = 0.0
        vector.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                fatalError("Unable to access vector buffer")
            }
            vDSP_svesq(baseAddress, 1, &norm, vDSPLength)
            norm = sqrt(norm)
            
            // Calculate the reciprocal of the norm to normalize the vector
            guard norm > 0 else {
                fatalError("Norm is zero, cannot normalize the vector")
            }
            var reciprocalNorm = 1.0 / norm
            
            // Apply the normalization by multiplying each element with the reciprocal of the norm
            vDSP_vsmul(baseAddress, 1, &reciprocalNorm, baseAddress, 1, vDSPLength)
        }
    }
}
