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

extension SNLPCorpus {
    /// Loads the documents from a bundled NDJSON archive.
    /// - Parameters:
    ///   - resource: The name of the resource file.
    ///   - withExtension: The extension of the resource file.
    ///   - maxDocuments: The maximum number of documents to load.
    ///   - bundle: The bundle to load the resource from.
    /// - Returns: An array of documents.
    /// - Throws: An error if the resource cannot be found or loaded.
    @inlinable
    mutating func loadFromBundledNDJSONArchive(_ resource: String, withExtension: String, maxDocuments: Int = Int.max, in bundle: Bundle) async {
        guard let resourceURL = bundle.url(forResource: resource, withExtension: withExtension) else {
            fatalError("Failed to find \(resource).\(withExtension) in test bundle.")
        }
        await loadFromNDJSONArchive(resourceURL, maxDocuments: maxDocuments)
    }
    
    /// Loads the documents from an NDJSON archive.
    /// - Parameters:
    ///   - resourceURL: The URL of the resource file.
    ///   - maxDocuments: The maximum number of documents to load.
    /// - Returns: An array of documents.
    @inlinable
    mutating func loadFromNDJSONArchive(_ resourceURL: URL, maxDocuments: Int = Int.max) async {
        guard let documentsAsData = try? Data(contentsOf: resourceURL) else {
            fatalError("Failed to load \(resourceURL).")
        }
        
        var (documents, _ ): ([Item],[Data]) = try! await loadFromRedditArchive(documentsAsData)
  
        // We don't want to include deleted/removed posts
        documents = documents.filter { !$0.fullText.isEmpty && $0.fullText != "[removed]" && $0.fullText != "[deleted]" }
                
        if documents.count > maxDocuments {
            documents = Array(documents.prefix(maxDocuments))
        }
        
        await addUntokenizedDocuments(documents)
    }
}
