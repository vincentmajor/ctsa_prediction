#!/bin/bash

## Vincent Major
## Created June 5 2017
## Last modified June 5 2017

date
pwd

## assuming that the compressed files are downloaded into the top directory ctsa_prediction/,
## this script will decompress those files into their correct locations.

## first, the corpus.
gunzip -c all_medline_post2000.txt.gz > data/all_medline_post2000.txt

## now the three sets of embeddings
gunzip -c fasttext_skip_hier.vec.gz > results/embeddings/fasttext_skip_hier.vec
gunzip -c word2vec_skip_hier.vec.gz > results/embeddings/word2vec_skip_hier.vec
gunzip -c word2vec_cbow_hier.vec.gz > results/embeddings/word2vec_cbow_hier.vec

echo "Done!"
