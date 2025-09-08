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

extension SNLPTopicModel {
    /// Plot the topic model
    /// - Parameter topicModelName: The name of the topic model
    public func plot(topicModelName: String) async {
        var data =  [[[Float]]]()

        var localCorpus = corpus.copy()
        localCorpus.metric = EuclideanDistance()

        if localCorpus.encodedDocumentsAsMLXArray.shape[1] > 2 {
            let UMAP = await UMAP(targetDimensions: 2, numNeighbours: 15, minDistance: 0.3)
            await UMAP.reduceCorpus(&localCorpus)
        }
        
        // Collect data points for each topic
        for topic in topics {
            let topicData = topic.documents.map { localCorpus.encodedDocuments[$0] }
            if topicData.count > 0 {
                data.append(topicData)
            }
        }
        
        makeScatterPlot(dataSets: data, dataSetName: topicModelName)
    }
}
