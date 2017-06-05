# ctsa_prediction

## Introduction

[Surkis et al.](https://translational-medicine.biomedcentral.com/articles/10.1186/s12967-016-0992-8) presented a novel method to label biomedical research along a translational spectrum from basic science through animal and human studies into population studies. The manual labeling process is incredibly laborious; the authors used bag-of-words text classification models to predict the class of articles based on the words in their title and abstracts. The goal of this project was to improve on the performance presented by incorporating text semantics learnt in an unsupervised manner with `word2vec` or `fastText`.

## Full paper

A manuscript has been submitted to IEEE International Conference on Health Informatics (ICHI) 2017. A preprint is available on [arXiv](https://arxiv.org/abs/1705.06262).

## Contents

This repo contains a mixture of the real scripts used to create the results and some example scripts to help others. 

### 1. Downloading PubMed

The bash script [`1_download_pubmed_and_process.sh`](https://github.com/vincentmajor/ctsa_prediction/blob/master/1_download_pubmed_and_process.sh): 
1. Downloads ***all*** MEDLINE records from the MEDLINE [baseline ftp site](ftp://ftp.ncbi.nlm.nih.gov/pubmed/baseline/),
2. Calls a R script (`1_extract_id_year_title_abstract_from_raw_xml.R`) to extract the article data (PMID, year, title and abstract) from the raw XML, and
3. Calls a python script (`1_process_text.py`) that processes the intermediate file created by R and saves a file ready for input into `word2vec`. 

The output of this script is a `data/` directory that contains `raw/`, `extracted/`, and `processed/` subdirectories and one 14 GB text file, `all_medline_post2000.txt`.

**DO NOT RUN THIS SCRIPT WITHOUT PLANNING!** Executing this script takes approximately 24 hours and requires at least 250 GB of storage (the raw XML files are 182 GB of that). Although if you want to filter to a different set of articles (for example, a different date range or from a specific set of journals) or process the text differently, the supplied code should provide a solid starting point. 

NOTE: the `data/all_medline_post2000.txt` file is not included in this repo due to size limitations. It is however, available for download [here](drive.google.com) compressed.

### 2. Learning embeddings

The bash script [`2_learn_embeddings.sh`](https://github.com/vincentmajor/ctsa_prediction/blob/master/2_learn_embeddings.sh): 
1. Decompresses the `data/all_medline_post2000.txt` file, if needed,
2. Downloads and makes `word2vec` and `fastText` if they do not exist in a subdirectory. (Both softwares require a unix OS), and
3. Creates three sets of embeddings:
    * word2vec skip-gram model with hierarchical sampling, dimension=200 and window=5,
    * word2vec CBOW model with hierarchical sampling, dimension=200 and window=5, and
    * fastText skip-gram model with hierarchical sampling, dimension=200 and window=5.
    
The output of this script is three sets of embeddings in vector form. 

**DO NOT RUN THIS SCRIPT WITHOUT PLANNING!** Executing this script takes approximately 26 hours on a machine with 64 GB of RAM and 28 threads. This script supplies the number of threads available as an argument to both `word2vec` and `fastText` but is hard-coded as 8 – check the capability of your machine and adjust accordingly. Although if you want to create embeddings with different data or with different parameters, the supplied code should provide a solid starting point.

NOTE: the embeddings are not included in this repo due to size limitations. They are however, available for download [here](drive.google.com) compressed.

### 3. Processing labeled data for fastText

The bash script [`3_create_fasttext_input.sh`](https://github.com/vincentmajor/ctsa_prediction/blob/master/3_create_fasttext_input.sh) is very similar to that from step 1 but starts with the contents of [`data/labeled`](https://github.com/vincentmajor/ctsa_prediction/tree/master/data/labeled) (i.e. `ctsa_pmids_labels.csv` and `ctsa_raw.xml`)  before:
1. Calls a R script (`3_extract_id_year_title_abstract_from_raw_xml.R`) to extract the article data (PMID, year, title and abstract) from the raw XML file (`data/labeled/ctsa_raw.xml`), and
2. Calls a python script (`3_process_text.py`) that processes the intermediate file created by R and saves a file ready for input into `fastText` with labels (using the default fastText prefix of `'__label__'`) extracted from the second input file (`ctsa_pmids_labels.csv`). 

The output of this script is several intermediate files in `data/labeled/` and a `fastText` input file: `ctsa_fasttext_input_wholeset.txt`. 

NOTE: Ideally, one would want to split this data into cross validation folds (as performed in the full paper) but this script is simply an example.

### 4. Train and predict with fastText

The bash script [`4_train_and_predict_fasttext.sh`](https://github.com/vincentmajor/ctsa_prediction/blob/master/4_train_and_predict_fasttext.sh) uses each pretrained embedding from step 2 to:
1. Train a `fastText` model on the labeled data (`ctsa_fasttext_input_wholeset.txt`),
2. Test the model on the labeled data (ideally, a heldout test set), 
3. Predict the label probabilities for each class on the labeled data (ideally, a heldout test set), and
4. Call a R script to reshape the probabilities into a more tidy format, plot ROC curves for each class and estimate each AUC.

The output is a well formatted csv file of predicted probabilities, one figure of ROCs, and a csv file of AUCs.

NOTE: This script is intended to be an example. Ideally cross validation should be used and these scripts can be modified to do so.

### Decompression of data and embeddings

The bash script [`decompress_data_and_embeddings.sh`](https://github.com/vincentmajor/ctsa_prediction/blob/master/decompress_data_and_embeddings.sh) is provided to ease the use of the raw text corpus and embeddings. Simply download the compressed files from [here](drive.google.com) into the head directory and the script will decompress the four files into their correct place. The script executes in 3 minutes.
