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
import ZSTD

/// A parallelizable version of the file processing function
/// - Parameters:
///   - fileData: The data to process
///   - verbose: Whether to print verbose output
/// - Returns: A tuple containing the posts and the errors
public func loadFromRedditArchive<C: Decodable>( _ fileData: Data, verbose: Bool = false) async throws -> (posts: [C], errors: [Data]) {
    
    var posts =  [C]()
    var errorData = [Data]()
    
    //let fileData = try Data(contentsOf: fileURL)
    var splitData: [Data]
                         
    let decoder = JSONDecoder()
        
    //let inputStream = FileReadStream()
    let inputMemory = BufferedMemoryStream(startData: fileData)
    let decompressMemory = BufferedMemoryStream()
    //let streamingDecoder = BufferedRedditArchiveDecoder<C>(saveTo: decompressMemory)
    try ZSTD.decompress(reader: inputMemory, writer: decompressMemory, config: ZSTD.DecompressConfig.default)
    let decompressedData = decompressMemory.representation
    
            
    splitData = splitDataIntoLines(data: decompressedData)

    // Error logging variables
    var lastData: Data? = nil
        
    for data in splitData {
        do {
            // Reset our error tracking variables
            lastData = data
            posts.append( try decoder.decode(C.self, from: data) )
            
        } catch {
            //numberOfErrors += 1
            errorData.append(lastData!)
        }
    }
    
    return (posts, errorData)
}

@inlinable
func splitDataIntoLines(data: Data) -> [Data] {
    var lines = [Data]()
    var lineStart = data.startIndex
    var lineEnd: Data.Index?
    var current = data.startIndex
    while current < data.endIndex {
        if data[current] == 10 { // ASCII newline
            lineEnd = current
            var line = data[lineStart..<lineEnd!]
            if line.last == 44 { line.removeLast() } // Remove trailing commas
            lines.append(line)
            lineStart = data.index(after: current)
        }
        current = data.index(after: current)
    }
    if lineStart < current {
        var line = data[lineStart..<current]
        
        if line.last == 44 { line.removeLast() } // Remove trailing commas
        
        lines.append(line)
    }
    return lines
}
