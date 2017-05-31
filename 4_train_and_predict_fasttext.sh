#!/bin/bash
#SBATCH --job-name=supervised_predict_5fold
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH --mem=16GB
# mail alert at start, end and abortion of execution
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=vjm261@nyu.edu

## start in /home/vjm261/ctsa_fastext
hostname
pwd

#$1 model vectors path
#$2 dimensions
####$2 training data
####$3 testing data

VECTORS=$1
OUTBASE=$VECTORS"_results_"
TRAINPATH="/scratch/vjm261/ctsa_fasttext/data/labeled/5_fold/ctsa_labeled_fasttext_trainset_"
TESTPATH="/scratch/vjm261/ctsa_fasttext/data/labeled/5_fold/ctsa_labeled_fasttext_testset_"
#echo "$OUTBASE"
#echo "$TRAINPATH"
#echo "$TESTPATH"

for i in {1..5}
do
    #echo "$i"
    OUT="$OUTBASE$i"
    #echo "$OUT"
    
    PROBS=$OUT".txt"
    #echo "$PROBS"    
    
    TRAIN=$TRAINPATH$i".txt"
    TEST=$TESTPATH$i".txt"
    #echo "$TRAIN"
    #echo "$TEST"
    
    ## learn the model with pretrainedVectors
    fastText/fasttext supervised -input $TRAIN -output $OUT -pretrainedVectors $VECTORS -dim $2
    
    ## precision recall
    fastText/fasttext test $OUT".bin" $TEST 1
    
    ## test and save to file
    fastText/fasttext predict-prob $OUT".bin" $TEST 3 > $PROBS
done

echo $OUTBASE
echo $TEST

## now call R 5_supervised_extract_predictions.R to do the work
module load r/intel/3.3.2
Rscript 5_supervised_extract_predictions.R $OUTBASE $TESTPATH 5

echo "Done"
