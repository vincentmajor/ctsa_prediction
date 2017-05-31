#!/bin/bash

## Vincent Major
## Created February 25 2017
## Last modified May 30 2017

## This script will take a raw xml file of pubmed articles,
## extract their pmids, years, titles and abstracts using R, and
## process the text and combine with manual labels using python.

## This script is intended to allow other users to supply other input data
## and recreate fasttext input.

Rscript 3_extract_id_year_title_abstract_from_labeled_xml.R data/labeled/ctsa_raw.xml

python 3_process_text.py data/labeled/ctsa_raw_extracted.csv data/labeled/ctsa_pmids_labels.csv
