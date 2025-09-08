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

/// Load files from a directory
/// - Parameter inputPath: The directory to load files from
/// - Returns: An array of file contents
public func loadFileContents(from inputPath: String) -> [String] {
    var fileContents = [String]()
    let fileManager = FileManager.default
    
    // Convert the input to a valid file path
    let path: String
    if let url = URL(string: inputPath), url.isFileURL {
        path = url.path
    } else {
        path = inputPath
    }
    
    // Check if the path exists and is a directory
    guard let directoryEnumerator = fileManager.enumerator(atPath: path) else {
        print("Directory does not exist or path is incorrect.")
        return fileContents
    }
    

    // Iterate through each subdirectory and file
    for case let filePath as String in directoryEnumerator {
        var isDirectory: ObjCBool = false
        let fullPath = (path as NSString).appendingPathComponent(filePath)
        
        if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory), !isDirectory.boolValue {
            do {
                let content = try String(contentsOfFile: fullPath, encoding: .utf8)
                fileContents.append(content)
            } catch {
                //print("Error loading file \(filePath): \(error)")
            }
        }
    }
    
    return fileContents
}
