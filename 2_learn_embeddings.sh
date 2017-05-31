#!/bin/sh

## Vincent Major
## Created February 25 2017
## Last modified May 30 2017

## This script will unzip data, if needed, and use word2vec
## or fastText to learn unsupervised embeddings.
## The number of threads for both word2vec and fastText is 
## hard-coded == 8 here. Update depending on your machine!

if ! [ -f data/all_medline_post2000.txt ]; then
	if [ -f data/all_medline_post2000.txt.gz ]; then
		gzip -c -d data/all_medline_post2000.txt.gz > data/all_medline_post2000.txt
	else
		echo "Could not find raw data compressed nor decompressed. Download it!"
	fi
fi

## check word2vec and fastText installed, download and make if need to
if ! [ -f word2vec/word2vec ]; then
	echo "Could not find word2vec so downloading and making..."
	#svn checkout http://word2vec.googlecode.com/svn/trunk/
	wget https://storage.googleapis.com/google-code-archive-source/v2/code.google.com/word2vec/source-archive.zip
	unzip source-archive.zip
	rm source-archive.zip
	mv word2vec/trunk/* word2vec/
	cd word2vec
	make
	cd ..
fi

if ! [ -f fastText/fasttext ]; then
        echo "Could not find fastText so downloading and making..."
        git clone https://github.com/facebookresearch/fastText.git
        cd fastText
        make
        cd ..
fi

## check results/embeddings/ subdir exists
mkdir -p results/embeddings

## Now to learn embeddings
## NOTE: if you have the resources, split these three into separate jobs and increase the number of threads for each

## First skipgram with hierarchial sampling
word2vec/word2vec -train data/all_medline_post2000.txt -output results/embeddings/word2vec_skip_hier.vec -cbow 0 -hs 1 -size 200 -window 5 -threads 8
echo "Done with word2vec skipgram"

## next, CBOW with hierarchial sampling
word2vec/word2vec -train data/all_medline_post2000.txt -output results/embeddings/word2vec_cbow_hier.vec -cbow 1 -hs 1 -size 200 -window 5 -threads 8
echo "Done with word2vec CBOW"

## finally, fastText with skipgram and hierarchical sampling
fastText/fasttext skipgram -input data/all_medline_post2000.txt -output results/embeddings/fasttext_skip_hier -loss hs -dim 200 -minn 3 -maxn 6 -thread 8
echo "Done with fastText skipgram"

echo "Done!"
