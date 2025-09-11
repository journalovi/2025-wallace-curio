```diff
! This paper is under review on the experimental track of the Journal of Visualization and Interaction.
Authors: James R. Wallace (@JimWallace), Mingchung Xia, Adrian Davila, Abhinav Jain, Peter Li, Nicole Mathis, Jean Nordmann, Henry Tian, George Wang, Ali Raza Zaidi, Jason Zhao
OC: TBD
AE: TBD
R1: TBD
R2: TBD
R3: TBD
```

<h2 align="center">Curio</h2>

[![Language](https://img.shields.io/badge/language-Swift-red.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Curio is a research-based, unsupervised topic modelling pipeline for social media, written in Swift. It draws from available libraries to support data collection, document encoding (e.g., CoreML, Model2vec, Apple's Natural Language), dimensionality reduction (e.g., PCA, tSNE, UMAP), clustering (e.g., HDBSCAN, KMeans), and topic modeling. Our goals are to provide a modular and efficient set of tools that work across a variety of data sources. We leverage modern Swift concurrency and libraries like MLX to provide performant and safe implementations that work well on commodity Mac hardware. Curio will enable the development of new qualitative data analysis tools for edge devices like laptops, tablets, and smartphones.


## Roadmap

- *Data Collection*
    - [X] [Reddit API Endpoints](https://www.reddit.com/dev/api/)
    - [X] [PushShift Reddit Archives](https://academictorrents.com/browse.php?search=Watchful1)
    - [ ] Additional data sources (e.g., X, Steam, Github)

- *Encoding*
    - [X] Static Embeddings
        - [X] [GloVE](https://nlp.stanford.edu/projects/glove/)
        - [X] [Apple Natural Language](https://developer.apple.com/documentation/naturallanguage/)
    - [X] Contextual Embeddings (e.g., Sentence-Transformers)        
        - [X] [Open AI API](https://platform.openai.com/docs/api-reference/introduction)
        - [X] CoreML Models (e.g., [All-MiniLM-L6](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2))

- *Dimensionality Reduction*
    - [X] [PCA](https://en.wikipedia.org/wiki/Principal_component_analysis)
    - [X] [t-SNE](https://en.wikipedia.org/wiki/T-distributed_stochastic_neighbor_embedding)
    - [X] Spherical t-SNE 
    - [X] [UMAP](https://en.wikipedia.org/wiki/Nonlinear_dimensionality_reduction#Uniform_manifold_approximation_and_projection)

- *Clustering*
    - [X] [K-Means](https://en.wikipedia.org/wiki/K-means_clustering) 
    - [X] [DBSCAN](https://en.wikipedia.org/wiki/DBSCAN)
    - [X] HDBSCAN

- *Topic Models*
    - [X] c-TF-IDF Keyword Generation
    - [X] Evaluation Metrics (Cosine Similarity, Topic Diversity)


## Installation

You can use Swift Package Manager and specify dependency in Package.swift by adding:

`.package(url: "https://git.uwaterloo.ca/jrWallac/curio.git", from: "0.0.8")`


## Contributing
This project is developed by a team of researchers from the [Human-Computer Interaction and Health Lab](https://uwaterloo.ca/human-computer-interaction-health-lab/) at the [University of Waterloo](https://uwaterloo.ca). The project is led by Prof. Jim Wallace, with contributions from: 
 - Jason Zhao
 - Nicole Mathis
 - Peter Li
 - Adrian Davila
 - Henry Tian
 - Jean Nordmann
 - Mingchung Xia
 - Abhinav Jain
 - George Wang
 - Ali Raza Zaidi

If you would like to contribute to the project, [contact Prof. Wallace](mailto:james.wallace@uwaterloo.ca) with "Curio" in the subject line, and mention one or more of the roadmap items above that you would like to work on. 

## License
All original code released under the MIT license for commercial and non-commercial use.

