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

/// A BufferedMemoryStream that can be used to pull out JSON objects on the fly as part of an Elva streaming decompression chain
public class MMapStreamingRedditArchiveDecoder<T: Decodable> {
    
    // Same functionality as Elva's BufferedMemoryStream
    public private(set) var representation: Data = Data()
    private var readerIndex: Int = 0

    /// Determine whether we should keep each element, defaults to keep everything
    private var filter: (T) -> Bool
    
    /// Where to put output if we want to keep it in memory
    public var memoryStore: [T]?  = nil
    
    /// Where to write output to if we just want to keep streaming it, e.g., possibly a `FileWriteStream`
    private var outputStream: WriteableStream? = nil
    
    // TODO: Remove this later possibly
    /// Save any errors so that we can fix decoding
    public var errorStore: [Data] = [Data]()
    
    // We'll use this to pull out objects
    private let decoder = JSONDecoder()
    
    /// Initializer that immediately decompresses the stream and writes it to another stream
    /// - Parameters:
    ///   - from: The stream to read from
    ///   - to: The stream to write to
    ///   - filter: A closure that determines whether to keep each element
    ///   - config: The decompression configuration
    /// - Throws: Any errors that occur during
    public init(
        from: ReadableStream,
        to: WriteableStream,
        filter: @escaping (T) -> Bool = { _ in true },
        config: ZSTD.DecompressConfig = ZSTD.DecompressConfig.default
    ) throws {
        outputStream = to
        self.filter = filter
        try ZSTD.decompress(reader: from, writer: self, config: config)
    }
    
    /// Initalizer that immediately decompresses the stream and stores its items in an array
    /// - Parameters:
    ///   - from: The stream to read from
    ///   - filter: A closure that determines whether to keep each element
    ///   - config: The decompression configuration
    /// - Throws: Any errors that occur during
    public init(
        from: ReadableStream,
        filter: @escaping (T) -> Bool = { _ in true },
        config: ZSTD.DecompressConfig = ZSTD.DecompressConfig.default
    ) throws {
        memoryStore = [T]()
        self.filter = filter
        try ZSTD.decompress(reader: from, writer: self, config: config)
    }
    
    /// Initalizer that immediately decompresses the file and stores its items in an array
    /// - Parameters:
    ///   - path: The path to the file to decompress
    ///   - filter: A closure that determines whether to keep each element
    ///   - config: The decompression configuration
    /// - Throws: Any errors that occur during
    public init(
        path: String,
        filter: @escaping (T) -> Bool = { _ in true },
        config: ZSTD.DecompressConfig = ZSTD.DecompressConfig.default
    ) throws {
        guard let inputStream = try? MMapFileReadStream(path: path) else {
            throw NSError(
                domain: "com.example.decompression",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create memory-mapped file stream at path: \(path)"]
            )
        }

        memoryStore = [T]()
        self.filter = filter
        try ZSTD.decompress(reader: inputStream, writer: self, config: config)
    }
    
    /// Initalizer that immediately decompresses the file and stores its items in an array
    /// - Parameters:
    ///   - inputPath: The path to the file to decompress
    ///   - outputPath: The path to write the output to
    ///   - filter: A closure that determines whether to keep each element
    ///   - config: The decompression configuration
    /// - Throws: Any errors that occur during
    public init(
        inputPath: String,
        outputPath: String,
        filter: @escaping (T) -> Bool = { _ in true }
    ) throws {
        guard let inputStream = try? MMapFileReadStream(path: inputPath),
              let outputStream = try? FileWriteStream(path: outputPath) else {
            throw NSError(
                domain: "com.example.decompression",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create file streams for paths: \(inputPath) or \(outputPath)"]
            )
        }
        
        self.outputStream = outputStream
        self.filter = filter
        let config = ZSTD.DecompressConfig(parameters: [.windowLogMax(31)])
        try ZSTD.decompress(reader: inputStream, writer: self, config: config)
    }
}
 

extension MMapStreamingRedditArchiveDecoder: WriteableStream {
    /// Write data to the stream
    /// - Parameters:
    ///   - data: The data to write
    ///   - length: The length of the data
    /// - Returns: The number of bytes written
    public func write(_ data: UnsafePointer<UInt8>, length: Int) -> Int {
        representation += Data(bytes: data, count: length)
        
        // While we have newlines, work through the file
        while let range = representation.range(of: Data([0x0A])) {
            let chunk = representation.subdata(in: 0..<range.lowerBound + 1)
            representation.removeSubrange(0..<range.lowerBound + 1)
                        
            let item = try? decoder.decode(T.self, from: chunk)
            
            // If we found an error, save the data
            if item == nil {
                errorStore.insert(chunk, at: errorStore.count)
            }
            
            if let item = item, filter(item) {
                if memoryStore != nil {
                    memoryStore!.insert(item, at: memoryStore!.count)
                }
                if let output = outputStream {
                    let size = chunk.count
                    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
                    chunk.copyBytes(to: buffer, count: size)
                    let _ = output.write(buffer, length: size)
                }
            }
        }
                
        return length
    }
    
    /// Close the stream
    public func close() {
        if let out = outputStream {
            out.close()
        }
    }
}
