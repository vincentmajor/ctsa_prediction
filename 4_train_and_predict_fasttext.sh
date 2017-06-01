#!/bin/bash

VECTORBASE="results/embeddings/"
OUTBASE="results/models/"
## ensure output dir exists
mkdir -p OUTBASE

TRAINPATH="data/labeled/ctsa_fasttext_input_"
TESTPATH="data/labeled/ctsa_fasttext_input_"

## iterate
#for i in {1..5} ## for cross validation
for VECTORS in fasttext_skip_hier word2vec_skip_hier word2vec_cbow_hier
do
    ## train on all, test on all
    TRAIN=$TRAINPATH"wholeset.txt"
    TEST=$TRAIN

    ## example about how to perform cross validation
    #TRAIN=$TRAINPATH$i".txt"
    #TEST=$TESTPATH$i".txt"
    
    MODEL=$OUTBASE$VECTORS"_model"
    
    echo $TRAIN
    echo $MODEL
    echo $VECTORS
    echo $TEST
    
    ## learn the model with pretrainedVectors
    fastText/fasttext supervised -input $TRAIN -output $MODEL -pretrainedVectors $VECTORBASE$VECTORS".vec" -dim 200
    
    ## precision recall
    fastText/fasttext test $MODEL".bin" $TEST 1
    
    ## test and save to file
    fastText/fasttext predict-prob $MODEL".bin" $TEST 3 > $MODEL"_predictions.txt"
    
    ## now call R to extract probabilities, save a tidy format and AUC plot
    Rscript 4_general_extract_predictions.R $MODEL"_predictions.txt" $TEST
done

echo "Done!"
