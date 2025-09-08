//
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

/// Represents a cluster or a point in the dendrogram
public class DendroNode {
    var points: Set<Int>  // Indices of points contained in this cluster
    var children: [DendroNode]? // Nil if it's a leaf node, contains children if internal node
    var parent: DendroNode? // Parent node in the dendrogram
    
    var mergeDistance: Double? // Distance at which this cluster was formed (mutual reachability)
    var stability: Double = 0  // Store the calculated stability
    
    // Initializer for leaf nodes (individual points)
    init(point: Int) {
        self.points = [point]
        self.children = nil
        self.mergeDistance = nil
    }
    
    // Initializer for internal nodes (clusters)
    init(children: [DendroNode], mergeDistance: Double) {
        self.points = Set(children.flatMap { $0.points })
        self.children = children
        self.mergeDistance = mergeDistance
        for child in children {
            child.parent = self
        }
    }
    
    // Check if node is a leaf node
    var isLeaf: Bool {
        return children == nil
    }
    
    // Method to merge a child node into the current node
    func merge(with child: DendroNode) {
            guard let children = self.children else {
                return  // No children to merge
            }

            // Attempt to find the child node in the children array
            if let index = children.firstIndex(where: { $0 === child }) {
                
                // Update stability
                stability += (mergeDistance ?? 0) - (child.mergeDistance ?? 0)
                
                // Check if the child has its own children and update their parent references
                if let childChildren = child.children {
                    for grandchild in childChildren {
                        grandchild.parent = self  // Set the new parent for each grandchild
                    }
                }
                
                // Remove the child from the children array
                self.children?.remove(at: index)
                
                // Update child's parent to nil
                child.parent = nil
            }
        }
}



extension DendroNode {
    /// Depth-first traversal of the dendrogram
    func traverseDendrogram() {
        if isLeaf {
            print("Leaf node with points: \(points)")
        } else {
            print("Internal node with merge distance: \(mergeDistance!) and points: \(points.sorted())")
            for child in children! {
                child.traverseDendrogram()
            }
        }
    }
    
    /// Print clusters based on a distance threshold
    func printClusters(atThreshold threshold: Double) {
        if let distance = mergeDistance, distance > threshold {
            // If the cluster's merge distance is greater than the threshold, print the whole cluster
            print("Cluster at threshold \(threshold) with points: \(points.sorted())")
        } else {
            // Otherwise, traverse children and print their clusters
            if let children = children {
                for child in children {
                    child.printClusters(atThreshold: threshold)
                }
            }
        }
    }
}



extension DendroNode: Hashable {
    // Conform to Hashable
    
    static public func == (lhs: DendroNode, rhs: DendroNode) -> Bool {
        // Compare nodes based on points and mergeDistance, adjust if needed
        return lhs.points == rhs.points && lhs.mergeDistance == rhs.mergeDistance
    }

    
    public func hash(into hasher: inout Hasher) {
        // Hash the points and mergeDistance
        hasher.combine(points)
        if let mergeDistance = mergeDistance {
            hasher.combine(mergeDistance)
        }
    }
}
