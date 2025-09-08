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

/// Represents the full dendrogram
public class Dendrogram {
    var root: DendroNode?

    /// Builds a dendrogram from a list of edges (e.g., MST edges)
    /// Each edge has two points and the mutual reachability distance (weight)
    init(_ mst: [Edge]) {

        // Start by treating each point as its own cluster
        let numPoints = mst.count + 1
        var clusters = Array(0..<numPoints).map { DendroNode(point: $0) }
        
        // Sort edges by increasing distance to build the hierarchy
        let sortedEdges = mst.sorted { $0.weight < $1.weight }
        
        for edge in sortedEdges {
            let clusterA = findCluster(for: edge.a, in: clusters)
            let clusterB = findCluster(for: edge.b, in: clusters)
            
            // Merge the clusters and create a new internal node
            let newCluster = DendroNode(children: [clusterA, clusterB], mergeDistance: edge.weight)
            
            // Remove old clusters and add the new one
            clusters.removeAll { $0 === clusterA || $0 === clusterB }
            clusters.append(newCluster)
        }
        
        // The last remaining cluster is the root of the dendrogram
        root = clusters.first
    }
    
    /// Helper to find the cluster a point belongs to
    private func findCluster(for point: Int, in clusters: [DendroNode]) -> DendroNode {
        return clusters.first { $0.points.contains(point) }!
    }

    /// Print the entire dendrogram, visiting all nodes
    func printDendrogram() {
        guard let root = root else {
            print("Dendrogram is empty")
            return
        }
        root.traverseDendrogram()
    }
    
    /// Print clusters formed below a given distance threshold
    func printClusters(belowThreshold threshold: Double) {
        guard let root = root else {
            print("Dendrogram is empty")
            return
        }
        root.printClusters(atThreshold: threshold)
    }
    
}

