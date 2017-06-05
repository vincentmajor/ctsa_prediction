#!/bin/sh

date
pwd

## first, the corpus
gzip -c --best data/all_medline_post2000.txt > all_medline_post2000.txt.gz

## second, the embeddings
gzip -c --best results/embeddings/word2vec_skip_hier.vec > word2vec_skip_hier.vec.gz

gzip -c --best results/embeddings/word2vec_cbow_hier.vec > word2vec_cbow_hier.vec.gz

gzip -c --best results/embeddings/fasttext_skip_hier.vec > fasttext_skip_hier.vec.gz


echo "Done!"
