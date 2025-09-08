// Helper Functions for Drawing Scatter Plot
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import MLX

@available(macOS 12.0, *)
internal func createContext(width: CGFloat, height: CGFloat) -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: Int(width),
        height: Int(height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Failed to create graphics context.")
    }
    
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return context
}

@available(macOS 12.0, *)
internal func drawAxes(context: CGContext, width: CGFloat, height: CGFloat, padding: CGFloat) {
    //let graphWidth = width - 2 * padding
    //let graphHeight = height - 2 * padding
    
    // Draw axes
    context.setStrokeColor(CGColor(gray: 0, alpha: 1))
    context.setLineWidth(2.0)
    
    // X-axis
    context.move(to: CGPoint(x: padding, y: height - padding))
    context.addLine(to: CGPoint(x: width - padding, y: height - padding))
    context.strokePath()
    
    // Y-axis
    context.move(to: CGPoint(x: padding, y: padding))
    context.addLine(to: CGPoint(x: padding, y: height - padding))
    context.strokePath()
    
    // Top
    context.move(to: CGPoint(x: padding, y: padding))
    context.addLine(to: CGPoint(x: width - padding, y: padding))
    context.strokePath()

    // Right
    context.move(to: CGPoint(x: width - padding, y: padding))
    context.addLine(to: CGPoint(x: width - padding, y: height - padding))
    context.strokePath()

    
}

@available(macOS 12.0, *)
internal func saveImage(context: CGContext, dataSetName: String) {
    guard let cgImage = context.makeImage() else {
        fatalError("Failed to create CGImage from context.")
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let dateString = dateFormatter.string(from: Date())
    let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    let fileName = "scatterplot_\(dataSetName)_\(dateString).png"
    let fileURL = downloadsDirectory.appendingPathComponent(fileName)

    guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("Failed to create image destination.")
    }
    
    CGImageDestinationAddImage(destination, cgImage, nil)
    if !CGImageDestinationFinalize(destination) {
        fatalError("Failed to write image to file.")
    }
}


@available(macOS 12.0, *)
public func makeScatterPlot(_ data: MLXArray, dataSetName: String) {
    let rows = data.shape[0]
    let columns = data.shape[1]
    let encodedDocuments = (0..<rows).map { rowIndex in
        data[rowIndex, 0..<columns].asArray(Float.self)
    }
    
    makeScatterPlot(encodedDocuments, dataSetName: dataSetName)
}

@available(macOS 12.0, *)
public func makeScatterPlot(_ data: [[Float]], dataSetName: String) {
    guard data.count > 0, data[0].count == 2 else {
        return
        //fatalError("Data must be a 2D array with each element containing exactly two Float values (x, y).")
    }
    
    // Extract x and y values from the data array
    let xValues = data.map { $0[0] }
    let yValues = data.map { $0[1] }
    
    let width: CGFloat = 4800 // Increased width for high resolution
    let height: CGFloat = 3200 // Increased height for high resolution
    let padding: CGFloat = 100.0 // Increased padding for better clarity

    // Create a CGContext to draw the scatter plot
    let context = createContext(width: width, height: height)
    
    // Draw axes
    drawAxes(context: context, width: width, height: height, padding: padding)
    
    let graphWidth = width - 2 * padding
    let graphHeight = height - 2 * padding
    
    // Determine the range of the data
    let minX = xValues.min() ?? 0
    let maxX = xValues.max() ?? 1
    let minY = yValues.min() ?? 0
    let maxY = yValues.max() ?? 1
    
    // Draw the scatter points
    context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
    let pointSize: CGFloat = 6.0 // Reduced point size to accommodate more points
    
    for (x, y) in zip(xValues, yValues) {
        let xPos = padding + graphWidth * CGFloat((x - minX) / (maxX - minX))
        let yPos = height - padding - graphHeight * CGFloat((y - minY) / (maxY - minY))
        let pointRect = CGRect(x: xPos - pointSize / 2, y: yPos - pointSize / 2, width: pointSize, height: pointSize)
        context.fillEllipse(in: pointRect)
    }
    
    // Save the image
    saveImage(context: context, dataSetName: dataSetName)
}

@available(macOS 12.0, *)
public func makeScatterPlot(dataSets: [[[Float]]], dataSetName: String) {
    guard !dataSets.isEmpty && dataSets.allSatisfy({ $0.count > 0 && $0[0].count == 2 }) else {
        fatalError("Each dataset must be a non-empty 2D array with each element containing exactly two Float values (x, y).")
    }
    
    let width: CGFloat = 4800 // Increased width for high resolution
    let height: CGFloat = 3200 // Increased height for high resolution
    let padding: CGFloat = 100.0 // Increased padding for better clarity

    // Create a CGContext to draw the scatter plot
    let context = createContext(width: width, height: height)
    
    // Draw axes
    drawAxes(context: context, width: width, height: height, padding: padding)
    
    let graphWidth = width - 2 * padding
    let graphHeight = height - 2 * padding
    
    // Determine the range of all data points for scaling
    let allXValues = dataSets.flatMap { $0.map { $0[0] } }
    let allYValues = dataSets.flatMap { $0.map { $0[1] } }
    let minX = allXValues.min() ?? 0
    let maxX = allXValues.max() ?? 1
    let minY = allYValues.min() ?? 0
    let maxY = allYValues.max() ?? 1
    
    let pointSize: CGFloat = 6.0 // Reduced point size to accommodate more points
    let colors: [CGColor] = [
        CGColor(red: 1, green: 0, blue: 0, alpha: 1),
        CGColor(red: 0, green: 1, blue: 0, alpha: 1),
        CGColor(red: 0, green: 0, blue: 1, alpha: 1),
        CGColor(red: 1, green: 1, blue: 0, alpha: 1),
        CGColor(red: 0, green: 1, blue: 1, alpha: 1),
        CGColor(red: 1, green: 0, blue: 1, alpha: 1)
    ]
    
    // Draw each dataset with a different color
    for (index, data) in dataSets.enumerated() {
        let color = colors[index % colors.count] // Cycle through colors if more than available
        context.setFillColor(color)
        
        for point in data {
            let x = point[0]
            let y = point[1]
            let xPos = padding + graphWidth * CGFloat((x - minX) / (maxX - minX))
            let yPos = height - padding - graphHeight * CGFloat((y - minY) / (maxY - minY))
            let pointRect = CGRect(x: xPos - pointSize / 2, y: yPos - pointSize / 2, width: pointSize, height: pointSize)
            context.fillEllipse(in: pointRect)
        }
    }
    
    // Save the image
    saveImage(context: context, dataSetName: dataSetName)
}
