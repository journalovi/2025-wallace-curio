---
title: 'Curio: A Swift package for analysis of social media data'
tags:
  - Swift
  - unsupervised topic modeling
  - qualitative data analysis
  - social media
authors:
  - name: James R. Wallace
    orcid: 0000-0002-5162-0256
    corresponding: true
    affiliation: 1
  - name: Mingchung Xia
    affiliation: 1
  - name: Adrian Davila
    affiliation: 1
  - name: Abhinav Jain
    affiliation: 1
  - name: Peter Li
    affiliation: 1
  - name: Nicole Mathis
    affiliation: 1
  - name: Jean Nordmann
    affiliation: 1
  - name: Henry Tian
    affiliation: 1
  - name: George Wang
    affiliation: 1
  - name: Ali Raza Zaidi
    affiliation: 1
  - name: Jason Zhao
    affiliation: 1

affiliations:
 - name: University of Waterloo, Canada
   index: 1
date: 6 December 2024
bibliography: paper.bib
---

# Summary

Social media constitutes a rich and influential source of information for qualitative researchers. However, while computational techniques like topic modeling are ubiquitous in the machine learning community they are less frequently used by qualitative researchers who often lack the programming skills required to put them to use in their own work. There is therefore an opportunity to explore how computational tools can be designed to align with the existing workflows and capabilities of qualitative researchers, using visual interfaces and commodity computer hardware. 


# Statement of need

`Curio` is a research-based, unsupervised topic modelling pipeline for social media, written in Swift. It draws from available libraries to support data collection, document encoding (e.g., CoreML, Model2vec [@minishlab2024model2vec], Apple's Natural Language), dimensionality reduction (e.g., PCA, tSNE [@tsne], UMAP [@umap]), clustering (e.g., HDBSCAN [@hdbscan], KMeans), and topic modeling. Our goals are to provide a modular and efficient set of tools that work across a variety of data sources. We leverage modern Swift concurrency and libraries like MLX to provide performant and safe implementations that work well on commodity Mac hardware. `Curio` will enable the development of new qualitative data analysis tools for edge devices like laptops, tablets, and smartphones.  

# Acknowledgements

We acknowledge contributions from Jaden Geller [@similaritytopology], Jan Krukowski [@swiftfaiss], and the Minish Lab [@minishlab2024model2vec].

# References