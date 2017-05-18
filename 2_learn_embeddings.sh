#!/bin/sh

## Vincent Major
## Created February 25 2017
## Last modified May 17 2017

## This script will unzip data, if needed, and use word2vec
## or fastText to learn unsupervised embeddings.

if ! [ -f data/all_medline_post2000.txt ]; then
	gzip -c -d data/all_medline_post2000.txt.gz > data/all_medline_post2000.txt
done

## Now to learn embeddings
## NOTE: if you have the resources, split these three into separate jobs and increase the number of threads for each

## First skipgram with hierarchial sampling
word2vec/word2vec -train data/all_medline_post2000.txt -output results/embeddings/word2vec_skip_hier -cbow 0 -hs 1 -size 200 -window 5 -threads 8

## next, CBOW with hierarchial sampling
word2vec/word2vec -train data/all_medline_post2000.txt -output results/embeddings/word2vec_cbow_hier -cbow 1 -hs 1 -size 200 -window 5 -threads 8

## finally, fastText with skipgram and hierarchical sampling
fastText/fasttext skipgram -input data/all_medline_post2000.txt -output results/embeddings/fasttext_skip_hier -loss hs -dim 200 -minn 3 -maxn 6 -thread 8

echo "Done!"
