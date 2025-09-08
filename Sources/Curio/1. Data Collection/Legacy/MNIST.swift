//
//  MNIST.swift
//  SwiftNLP
//
//  Created by Jim Wallace on 2024-11-19.
//

import Foundation

public enum MNISTLoadingError: Error {
    case failedToOpenFile(String)
    case fileTooSmall
    case invalidMagicNumber(UInt32)
    case unexpectedEndOfFile
}

public func loadMNIST(from url: URL) throws -> [[Float]]? {
    guard let data = try? Data(contentsOf: url) else {
        throw MNISTLoadingError.failedToOpenFile("Failed to open file at \(url.path)")
    }

    // Ensure the file is at least large enough for the header
    guard data.count > 16 else {
        throw MNISTLoadingError.fileTooSmall
    }

    // Read the header
    let magicNumber = data[0..<4].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
    guard magicNumber == 2051 else {
        throw MNISTLoadingError.invalidMagicNumber(magicNumber)
    }

    let numberOfImages = data[4..<8].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
    let rows = data[8..<12].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
    let cols = data[12..<16].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }

    let imageSize = Int(rows * cols)
    let imageStartIndex = 16

    guard data.count >= imageStartIndex + imageSize * Int(numberOfImages) else {
        throw MNISTLoadingError.unexpectedEndOfFile
    }

    var images: [[Float]] = []
    images.reserveCapacity(Int(numberOfImages))

    // Process each image
    data.withUnsafeBytes { buffer in
        let bytes = buffer.bindMemory(to: UInt8.self)
        for i in 0..<Int(numberOfImages) {
            let startIndex = imageStartIndex + i * imageSize
            let endIndex = startIndex + imageSize
            let floatImage = (startIndex..<endIndex).map { Float(bytes[$0]) / 255.0 }

            if !floatImage.allSatisfy({ $0 == 0 }) {
                images.append(floatImage)
            }
        }
    }

    return images
}

public func loadMNISTLabels(from url: URL) throws -> [String]? {
    guard let data = try? Data(contentsOf: url) else {
        throw MNISTLoadingError.failedToOpenFile("Failed to open file at \(url.path)")
    }

    // Ensure the file is at least large enough for the header
    guard data.count > 8 else {
        throw MNISTLoadingError.fileTooSmall
    }

    // Read the header
    let magicNumber = data[0..<4].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
    guard magicNumber == 2049 else {
        throw MNISTLoadingError.invalidMagicNumber(magicNumber)
    }

    let numberOfLabels = data[4..<8].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
    let labelStartIndex = 8

    guard data.count >= labelStartIndex + Int(numberOfLabels) else {
        throw MNISTLoadingError.unexpectedEndOfFile
    }

    var labels: [String] = []
    labels.reserveCapacity(Int(numberOfLabels))

    // Process each label
    data.withUnsafeBytes { buffer in
        let bytes = buffer.bindMemory(to: UInt8.self)
        for i in 0..<Int(numberOfLabels) {
            let labelIndex = labelStartIndex + i
            labels.append(String(bytes[labelIndex]))
        }
    }

    return labels
}
