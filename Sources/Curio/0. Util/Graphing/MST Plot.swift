// Helper Functions for Drawing Scatter Plot
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import MLX

@available(macOS 12.0, *)
public func makeMSTPlot(data: [[Float]], mst: [Edge], dataSetName: String) {
    // Ensure data has 2D points.
    guard data.count > 0, data[0].count == 2 else {
        fatalError("Data must be a 2D array with each element containing exactly two Float values (x, y).")
    }
    
    // Drawing parameters
    let width: CGFloat = 4800    // High resolution width
    let height: CGFloat = 3200   // High resolution height
    let padding: CGFloat = 100.0 // Padding for axes
    let context = createContext(width: width, height: height)
    
    // Draw axes (same as scatter plot)
    drawAxes(context: context, width: width, height: height, padding: padding)
    
    let graphWidth = width - 2 * padding
    let graphHeight = height - 2 * padding
    
    // Extract x and y values and determine the data range.
    let xValues = data.map { $0[0] }
    let yValues = data.map { $0[1] }
    let minX = xValues.min() ?? 0
    let maxX = xValues.max() ?? 1
    let minY = yValues.min() ?? 0
    let maxY = yValues.max() ?? 1
    
    // Helper to convert a data point (x,y) into canvas coordinates.
    func canvasPoint(from point: [Float]) -> CGPoint {
        let x = CGFloat(point[0])
        let y = CGFloat(point[1])
        let xPos = padding + graphWidth * CGFloat((x - CGFloat(minX)) / (CGFloat(maxX) - CGFloat(minX)))
        let yPos = height - padding - graphHeight * CGFloat((y - CGFloat(minY)) / (CGFloat(maxY) - CGFloat(minY)))
        return CGPoint(x: xPos, y: yPos)
    }
    
    // Draw MST edges as red lines.
    context.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
    context.setLineWidth(2.0)
    
    for edge in mst {
        let pointA = canvasPoint(from: data[edge.a])
        let pointB = canvasPoint(from: data[edge.b])
        context.move(to: pointA)
        context.addLine(to: pointB)
        context.strokePath()
    }
    
    // Optionally, draw the nodes as blue circles on top.
    context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
    let pointSize: CGFloat = 6.0
    for point in data {
        let pos = canvasPoint(from: point)
        let pointRect = CGRect(x: pos.x - pointSize / 2, y: pos.y - pointSize / 2, width: pointSize, height: pointSize)
        context.fillEllipse(in: pointRect)
    }
    
    // Save the image.
    saveImage(context: context, dataSetName: "mst_\(dataSetName)")
}

