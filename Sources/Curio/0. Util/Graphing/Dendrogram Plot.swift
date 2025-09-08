//
//  Dendrograph.swift
//  Curio
//
//  Created by Jim Wallace on 2025-03-13.
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import MLX

@available(macOS 12.0, *)
public func makeDendrogramPlot(dendrogram: Dendrogram, dataSetName: String) {
    // Drawing parameters
    let width: CGFloat = 4800
    let height: CGFloat = 3200
    let padding: CGFloat = 100.0
    let context = createContext(width: width, height: height)
    
    let graphWidth = width - 2 * padding
    let graphHeight = height - 2 * padding
    
    // Dictionary to store computed positions for each node.
    var nodePositions: [DendroNode: CGPoint] = [:]
    
    // Iterative function to collect all leaf nodes.
    func collectLeavesIterative(from root: DendroNode) -> [DendroNode] {
        var leaves: [DendroNode] = []
        var stack: [DendroNode] = [root]
        
        while !stack.isEmpty {
            let node = stack.removeLast()
            if node.isLeaf {
                leaves.append(node)
            } else if let children = node.children {
                stack.append(contentsOf: children)
            }
        }
        return leaves
    }
    
    // Iterative function to compute the maximum mergeDistance.
    func maxMergeDistanceIterative(from root: DendroNode) -> Double {
        var maxVal = root.mergeDistance ?? 0.0
        var stack: [DendroNode] = [root]
        while !stack.isEmpty {
            let node = stack.removeLast()
            if let mergeDist = node.mergeDistance {
                maxVal = max(maxVal, mergeDist)
            }
            if let children = node.children {
                stack.append(contentsOf: children)
            }
        }
        return maxVal
    }
    
    // Ensure dendrogram has a root.
    guard let root = dendrogram.root else {
        fatalError("Dendrogram is empty")
    }
    
    // Use the iterative function to collect leaves.
    let leaves = collectLeavesIterative(from: root)
    let numLeaves = leaves.count
    if numLeaves == 0 {
        fatalError("No leaves found in dendrogram")
    }
    
    // Assign x positions for leaves evenly; y = bottom (graphHeight + padding)
    let xSpacing = numLeaves > 1 ? graphWidth / CGFloat(numLeaves - 1) : 0
    for (i, leaf) in leaves.enumerated() {
        let x = padding + CGFloat(i) * xSpacing
        let y = padding + graphHeight  // leaves at bottom
        nodePositions[leaf] = CGPoint(x: x, y: y)
    }
    
    // Use the iterative maxMergeDistance function.
    let maxMerge = maxMergeDistanceIterative(from: root)
    
    // Iteratively compute internal node positions using post-order traversal.
    func computePositionsIterative(root: DendroNode) {
        var stack: [DendroNode] = [root]
        var postOrder: [DendroNode] = []
        
        while !stack.isEmpty {
            let node = stack.removeLast()
            postOrder.append(node)
            if let children = node.children {
                stack.append(contentsOf: children)
            }
        }
        postOrder.reverse()  // Process leaves first.
        
        for node in postOrder {
            if node.isLeaf { continue }  // Leaves already have positions.
            if let children = node.children {
                let childPositions = children.compactMap { nodePositions[$0] }
                if !childPositions.isEmpty {
                    let avgX = childPositions.map { $0.x }.reduce(0, +) / CGFloat(childPositions.count)
                    let mergeDist = node.mergeDistance ?? 0.0
                    // Scale y so that mergeDist == 0 maps to bottom and mergeDist == maxMerge maps to top.
                    let y = padding + graphHeight - CGFloat(mergeDist / maxMerge) * graphHeight
                    nodePositions[node] = CGPoint(x: avgX, y: y)
                }
            }
        }
    }
    computePositionsIterative(root: root)
    
    // Iteratively collect all line segments (vertical and horizontal) that connect parent and child nodes.
    var segments: [(start: CGPoint, end: CGPoint)] = []
    var nodeStack: [DendroNode] = [root]
    while !nodeStack.isEmpty {
        let currentNode = nodeStack.removeLast()
        if let children = currentNode.children, let parentPos = nodePositions[currentNode] {
            for child in children {
                if let childPos = nodePositions[child] {
                    // Vertical segment: from child's position to parent's y-level (keeping child's x).
                    let verticalSegment = (start: childPos, end: CGPoint(x: childPos.x, y: parentPos.y))
                    // Horizontal segment: from child's x at parent's y-level to parent's position.
                    let horizontalSegment = (start: CGPoint(x: childPos.x, y: parentPos.y), end: parentPos)
                    segments.append(verticalSegment)
                    segments.append(horizontalSegment)
                }
                nodeStack.append(child)
            }
        }
    }
    
    // Create a single mutable path and add all segments.
    let path = CGMutablePath()
    for segment in segments {
        path.move(to: segment.start)
        path.addLine(to: segment.end)
    }
    
    // Draw the aggregated path in one stroke.
    context.addPath(path)
    context.setStrokeColor(CGColor(gray: 0, alpha: 1))
    context.setLineWidth(2.0)
    context.strokePath()
    
    // Optionally, draw circles at node positions.
    context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
    for pos in nodePositions.values {
        let circleRect = CGRect(x: pos.x - 4, y: pos.y - 4, width: 8, height: 8)
        context.fillEllipse(in: circleRect)
    }
    
    // Save the image.
    saveImage(context: context, dataSetName: "dendrogram_\(dataSetName)")
}
