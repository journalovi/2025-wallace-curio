//
//  SNLPCorpus + MLXArray.swift
//  SwiftNLP
//
//  Created by Jim Wallace on 2024-11-15.
//

@preconcurrency import MLX

extension SNLPCorpus {
    
    // Computed property to get or set encodedDocuments as MLXArray
    var encodedDocumentsAsMLXArray: MLXArray {
        get {
            let values = encodedDocuments.flatMap { $0 }
            return MLXArray(values, [encodedDocuments.count, dimensions])
        }
        set {
            let rows = newValue.shape[0]
            let columns = newValue.shape[1]
            encodedDocuments = (0..<rows).map { rowIndex in
                newValue[rowIndex, 0..<columns].asArray(Float.self)
            }
            dimensions = columns
        }
    }
    
}
