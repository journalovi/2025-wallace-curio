//
//  Topic.swift
//  Curio
//
//  Created by Jim Wallace on 2025-02-27.
//

public struct Topic: CustomStringConvertible {
    var label: String
    var documents: [Int]
    var keywords: [String: Double]
    
    public var description: String {
        // Display these in descending order
        let sortedKeywords = keywords.sorted { $0.value > $1.value }
        
        // Format them so we don't see all the digits
        let formattedKeywords = sortedKeywords.map { "\($0.key) (\(String(format: "%.4f", $0.value)))" }.joined(separator: ", ")
        return "\(label) (\(documents.count) documents): \(formattedKeywords)"
    }
}
