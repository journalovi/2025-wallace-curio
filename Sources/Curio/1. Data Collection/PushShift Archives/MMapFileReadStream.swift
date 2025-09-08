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

/// A memory-mapped file read stream
public class MMapFileReadStream {
    private let data: Data
    private var currentIndex = 0
    
    public init(path: String) throws {
        let url = URL(fileURLWithPath: path)
        self.data = try Data(contentsOf: url, options: .alwaysMapped)
    }
}

extension MMapFileReadStream: ReadableStream {
    /// Read data from the stream
    /// - Parameters:
    ///   - buffer: The buffer to read into
    ///   - length: The length of the buffer
    /// - Returns: The number of bytes read
    public func read(_ buffer: UnsafeMutablePointer<UInt8>, length: Int) -> Int {
        let bytesToRead = min(length, data.count - currentIndex)
        data.copyBytes(to: buffer, from: currentIndex..<currentIndex + bytesToRead)
        currentIndex += bytesToRead
        return bytesToRead
    }
}

extension MMapFileReadStream: ByteStream {
    public func close() {}
}
