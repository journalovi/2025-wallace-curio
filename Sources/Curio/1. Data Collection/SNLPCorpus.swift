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
@preconcurrency import MLX
import Synchronization

public protocol SNLPCorpus<Item>: Sendable, CustomStringConvertible where Item: Sendable {
    
    associatedtype Item: SNLPDataItem        
        
    var documents: [Item] { get set }
    var encodedDocuments: [[Float]] { get set }
    var documentEncoder: any SNLPEncoder { get set }

    var metric: DistanceMetric { get set }
    var zeroes: [Float] { get }
    var dimensions: Int { get set }
    var count: Int { get }
    
    @inlinable
    mutating func addUntokenizedDocument(_ document: Item) async
    
    @inlinable
    mutating func addUntokenizedDocuments(_ documents: [Item]) async
    
    @inlinable
    func copy() -> Self
}



extension SNLPCorpus {

    public var zeroes: [Float] { documentEncoder.zeroes }
    //public var dimensions: Int { encodedDocuments.first?.count ?? documentEncoder.dimensions } // TODO: Do we store this as a separate shape variable, and update as needed?
    public var count: Int { documents.count }
        
    @inlinable
    public mutating func addUntokenizedDocuments(_ documents: [Item]) async {
        
        let concurrentTasks: Int = max( 1, ProcessInfo.processInfo.activeProcessorCount - 2)
        let batchSize = max(1, documents.count / concurrentTasks) // Divide into 4 batches or at least 1 document per batch
        
        // Append documents to the corpus
        self.documents.append(contentsOf: documents)
        
        var results = Array(repeating: Array(repeating: Float(0.0), count: dimensions), count: documents.count)
        
        await withTaskGroup(of: ([[Float]], Range<Int>).self) { taskGroup in // TODO: Can we modify the original array in-place instead?
            
            for batchStart in stride(from: 0, to: documents.count, by: batchSize) {
                let batchEnd = min(batchStart + batchSize, documents.count)
                let batchRange = batchStart..<batchEnd
                
                let documents = self.documents
                let documentEncoder = self.documentEncoder
                
                taskGroup.addTask { [documents] in
                    return (await documentEncoder.encodeSentences(documents: documents, indices: batchRange), batchRange)
                }
            }
            
            // Consolidate values into storage
            for await (embeddings, range) in taskGroup {
                for (i, idx) in range.enumerated() {
                    results[idx] = embeddings[i]
                }
            }
        }

        encodedDocuments.append(contentsOf: results)
                
        assert(self.documents.count == self.encodedDocuments.count)
    }
                

    
    /// Adds an untokenized document to the corpus, using default tokenization and text processing
    /// - Parameter document: The document to add
    @inlinable
    public mutating func addUntokenizedDocument(_ document: Item) async {

        documents.append(document)
        let d: [Float] = await documentEncoder.encodeSentence(document.fullText)
        encodedDocuments.append(d)
        
        assert( documents.count == encodedDocuments.count )
    }
    
    /// Creates a new `SNLPCorpus` by copying the current corpus.
    @inlinable
    public func copy() -> Self {
        return self
    }
}

extension SNLPCorpus {
    public var description: String {
        var result = "Corpus: \(self.documents.count) documents, encoded as \(self.dimensions) dimensional embeddings\n"
        for i in 0 ..< min(11, documents.count) {
            var documentSummary = String(self.documents[i].fullText.unicodeScalars.filter{ !CharacterSet.controlCharacters.contains($0) }.prefix(75))
            if self.documents[i].fullText.count > 75 {
                documentSummary += "..."
            }
            documentSummary += " "
            
            result += documentSummary
            
            
            // Summarize the encoded document, which is an array of Floats
            let encodedDocument = self.encodedDocuments[i]
            let encodedSummary = encodedDocument.prefix(min(5, encodedDocument.count))  // Take the first 5 floats if possible
                .map { String(format: "%.2f", $0) }         // Format each float to 2 decimal places
                .joined(separator: ", ")
            
            result += encodedSummary + "\n"
        }
        return result
    }
}


extension SNLPCorpus where Self: AnyObject {
    public func copy() -> Self {
        fatalError("Copy() only valid for value types. Conforming classes must provide a sepcialized implementation.")
    }
}
