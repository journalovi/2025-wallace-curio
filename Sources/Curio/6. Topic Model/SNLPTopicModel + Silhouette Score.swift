//
//  SNLPTopicModel + Silhouette Score.swift
//  SwiftNLP
//
//  Created by Mingchung Xia on 2024-10-18.
//

extension SNLPTopicModel {
    public func silhouetteScore(_ metric: DistanceMetric = EuclideanDistance()) -> Double {
        // Ensure we have enough topics for the calculation
        guard topics.count > 1 else { return 0.0 }

        var totalScore = 0.0
        var totalDocuments = 0

        // Iterate over all topics and their documents
        for currentTopic in topics {
            for doc in currentTopic.documents {
                // Calculate a(i): Average distance to all other documents in the same cluster
                let a_i = averageIntraClusterDistance(document: doc, cluster: currentTopic.documents)

                // Calculate b(i): Minimum average distance to all other clusters
                let b_i = averageInterClusterDistance(document: doc, currentCluster: currentTopic.documents)

                // Calculate the silhouette score for this document
                let s_i = (b_i - a_i) / max(a_i, b_i)

                // Accumulate total score and document count
                totalScore += s_i
                totalDocuments += 1
            }
        }

        // Return the mean silhouette score
        return totalDocuments > 0 ? totalScore / Double(totalDocuments) : 0.0
    }

    /// Calculate the average intra-cluster distance (a(i)) for a document.
    /// - Parameters:
    ///   - document: The document index to calculate the distance for.
    ///   - cluster: The list of document indices in the same cluster.
    /// - Returns: The average distance to all other documents in the same cluster.
    private func averageIntraClusterDistance(document: Int, cluster: [Int], _ metric: DistanceMetric = EuclideanDistance()) -> Double {
        guard cluster.count > 1 else { return 0.0 }

        var totalDistance = 0.0
        var documentCount = 0

        for otherDoc in cluster where otherDoc != document {
            let distance = metric.distance(between: corpus.encodedDocuments[document], corpus.encodedDocuments[otherDoc])
            totalDistance += distance
            documentCount += 1
        }

        return documentCount > 0 ? totalDistance / Double(documentCount) : 0.0
    }

    /// Calculate the average inter-cluster distance (b(i)) for a document to the nearest cluster.
    /// - Parameters:
    ///   - document: The document index to calculate the distance for.
    ///   - currentCluster: The list of document indices in the current cluster.
    /// - Returns: The minimum average distance to all documents in other clusters.
    private func averageInterClusterDistance(document: Int, currentCluster: [Int], _ metric: DistanceMetric = EuclideanDistance()) -> Double {
        var minAverageDistance = Double.greatestFiniteMagnitude

        for otherTopic in topics where otherTopic.documents != currentCluster {
            var totalDistance = 0.0
            var documentCount = 0

            for otherDoc in otherTopic.documents {
                let distance = metric.distance(between: corpus.encodedDocuments[document], corpus.encodedDocuments[otherDoc])
                totalDistance += distance
                documentCount += 1
            }

            let averageDistance = documentCount > 0 ? totalDistance / Double(documentCount) : 0.0
            minAverageDistance = min(minAverageDistance, averageDistance)
        }

        return minAverageDistance
    }
}

