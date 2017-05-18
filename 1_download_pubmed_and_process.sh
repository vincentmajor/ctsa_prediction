#!/bin/sh

## Vincent Major
## Created February 25 2017
## Last modified May 17 2017

## This script will download all of PubMed from it's ftp server
## extract titles, years, and abstracts from the raw XML
## filter to year >= 2000, process the text and combine.

## This script will take a long time to execute, require a lot(!) of storage, 
## and will take up PubMed's bandwidth.
## DO NOT EXECUTE THIS IF YOU ARE NOT COMMITTED TO DO SO!

## The resulting 'combined' file is available on github.
## You don't have to run this script!

if ! [ -f data/all_medline_post2000.txt ]; then
	## wget all files from PubMed
	##test on 10 files
	#wget ftp://ftp.ncbi.nlm.nih.gov/pubmed/baseline/medline17n087*.xml.gz -P data/raw
	# everything
	wget ftp://ftp.ncbi.nlm.nih.gov/pubmed/baseline/medline17n0*.xml.gz -P data/raw
	## Unzip all of them
	gunzip data/raw/*.xml.gz
	
	## Use R to extract data from XML files, will cycle through files
	Rscript 1_extract_id_year_title_abstract_from_raw_xml.R 1 892
	## output files will be in data/extracted/
	
	## use python to process text, function loops skipping missing files
	python 1_process_text.py 1 892
	## output files will be in data/processed
	
	## paste all files together, separating by \n, removing blank lines
	paste --delimiter=\\n --serial data/processed/prc_medline17n*.txt | sed '/^\s*$/d' > data/all_medline_post2000.txt
fi

echo "Done!"
