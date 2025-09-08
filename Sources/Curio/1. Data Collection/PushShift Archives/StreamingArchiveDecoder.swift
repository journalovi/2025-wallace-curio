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
public class StreamingArchiveDecoder<T: Decodable> {
    
    // Same functionality as Elva's BufferedMemoryStream
    public private(set) var representation: Data = Data()
    private var readerIndex: Int = 0

    /// Determine whether we should keep each element, defaults to keep everything
    private var filter: (T) -> Bool
    
    /// Where to put output if we want to keep it in memory
    public var memoryStore: [T]? = nil
    
    /// Where to write output to if we just want to keep streaming it, e.g., possibly a `FileWriteStream`
    private var outputStream: WriteableStream? = nil
    
    /// Save any errors so that we can fix decoding ... remove this later?
    public var errorStore: [Data] = [Data]()
    
    // We'll use this to pull out objects
    private let decoder = JSONDecoder()
    
    
    /// Initalizer that immediately decompresses the stream
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
    
    /// Initalizer that immediately decompresses the stream and stores its items in `memoryStore`
    /// - Parameters:
    ///   - from: The stream to read from
    ///   - filter: A closure that determines whether to keep each element
    ///   - config: The decompression configuration
    /// - Throws: Any errors that occur during the decompression
    public init(
        from: ReadableStream,
        filter: @escaping (T) -> Bool = { _ in true },
        config: ZSTD.DecompressConfig = ZSTD.DecompressConfig.default
    ) throws {
        memoryStore = [T]()
        self.filter = filter
        try ZSTD.decompress(reader: from, writer: self, config: config)
    }
    
    /// Initalizer that immediately decompresses the file and stores its items in `memoryStore`
    /// - Parameters:
    ///   - input: The file to read from
    ///   - filter: A closure that determines whether to keep each element
    ///   - config: The decompression configuration
    /// - Throws: Any errors that occur during the decompression
    public init(
        input: URL,
        filter: @escaping (T) -> Bool = { _ in true },
        config: ZSTD.DecompressConfig = ZSTD.DecompressConfig(parameters: [.windowLogMax(31)])
    ) throws {
        guard let inputStream = try? MMapFileReadStream(path: input.path) else {
            throw StreamingArchiveDecoderError.fileError(message: "Unable to open \(input) for reading.")
        }
        
        memoryStore = [T]()
        self.filter = filter
        try ZSTD.decompress(reader: inputStream, writer: self, config: config)
    }
    
    
    /// Initalizer that immediately decompresses `inputPath` and writes results to `outputPath`
    /// - Parameters:
    ///   - input: The file to read from
    ///   - output: The file to write to
    ///   - filter: A closure that determines whether to keep each element
    ///   - config: The decompression configuration
    /// - Throws: Any errors that occur during the decompression
    public init(
        input: URL,
        output: URL,
        filter: @escaping (T) -> Bool = { _ in true },
        config: ZSTD.DecompressConfig = ZSTD.DecompressConfig(parameters: [.windowLogMax(31)])
    ) throws {
        guard let inputStream = try? MMapFileReadStream(path: input.path) else {
            throw StreamingArchiveDecoderError.fileError(message: "Unable to open \(input) for reading.")
        }
        
        guard let outputStream = try? FileWriteStream(path: output.path) else {
            throw StreamingArchiveDecoderError.fileError(message: "Unable to open \(output) for writing.")
        }
                                
        self.outputStream = outputStream
        self.filter = filter
        try ZSTD.decompress(reader: inputStream, writer: self, config: config)
    }
}
 

extension StreamingArchiveDecoder: WriteableStream {
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
