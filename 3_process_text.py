import numpy as np
import pandas as pd
import sys
import csv
import os

print 'Number of arguments:', len(sys.argv), 'arguments.'
print 'Argument List:', str(sys.argv)

if len(sys.argv) >= 3:
    filename_in = sys.argv[1]
    filename_labels = sys.argv[2]
elif len(sys.argv) == 2:
    print "Only one argument found, please provide path to pmids and labels file"
    
else:
    print "No command line arguments found."

filename_out = filename_in.replace(".csv", "_processed.txt")
print "Targeting file " + filename_in + " for processing into " + filename_out
print "Using labels file: " + filename_labels

#### Process text
## define a function that takes a dataframe with text in field text
## removes copyright notices, and normalizes whitespaces to a single space
def process(df):
    # removing whitespaces, punctuations, stopwords, and stemming words
    documents = []
    failures = []
    import re
    pattern = re.compile('[\W_]+')
    for document in df['text']:
        try:
            ## remove trailing terms like Elsevier and All rights reserved
            document =  re.sub(string = document.lower(), pattern = 'copyright.{0,100}?$', repl = '')
            ## remove anything after a copyright.
            ## should check for "published" or "rights reserved"
            
            ## remove everything except alphanumerics and whitespace
            ## word2vec can handle multiple whitespaces between tokens
            ## combine into one string
            outstr = pattern.sub(' ', document)

            ## append outstr
            documents.append(outstr)
        except:
            documents.append(np.nan)
            ## record failures
            failures.append(df[df['text'] == document].index.tolist())
            continue
    
    return [documents, failures]

#### Load, process, save
## loads a file, processes and saves the result
## takes a single integer as input

## check file exists, skip if not
if not os.path.isfile(filename_in):
    print 'Failed to find input file: ' + filename_in

## Reading raw file with pmid, year, title, and abstracts
## this file is created after extraction from XML 
raw = pd.read_table(filename_in, sep="|", quotechar='"', error_bad_lines=False)

## remove years 2000 and earlier
#year_mask = raw['year'] >= 2000 # removed for ctsa labeled articles
#raw_concat = raw[year_mask].copy()
raw_concat = raw.copy()

## combine title and abstracts into one text field and drop the parents
raw_concat["text"] = raw_concat["title"] + " " + raw_concat["abstract"]

#raw_concat.drop('pmid', axis=1, inplace=True) ## for labeled articles, you want to keep pmid to merge on later!
raw_concat.drop('year', axis=1, inplace=True)
raw_concat.drop('title', axis=1, inplace=True)
raw_concat.drop('abstract', axis=1, inplace=True)

## check for and remove any rows with null text field
## don't care if pmid or year is incomplete here
print(raw_concat.shape)
df = raw_concat[raw_concat['text'].notnull()]

#### subset of CTSA LABELED data.
## first load labels
labels = pd.read_csv(filename_labels)

def add_label_tag(num):
    s = "__label__" + str(int(num))
    return s
    
labels["label"] = map(add_label_tag, labels["group"])
labels.drop('group', axis=1, inplace=True)

## merge df onto labels on pmid
df_labels = labels.merge(df, on = 'pmid', how = 'inner')
## inner to only keep the articles with nonnull text

## check for pmids that don't appear - should be empty
print "PMIDs that get removed, this should be an empty list:"
print list(set(labels["pmid"]) - set(df_labels["pmid"]))
## this was an issue with the original XML not containing all pmids
## fixed with updated R parsing script.

# cleanup and drop
#df_labels.drop('pmid', axis=1, inplace=True)
print(df_labels.shape)
## the result is a nice ordered data.frame.

#### Preprocess
## now apply processing function to the real df
df_labels["output"] = process(df_labels)[0] # [0] for output not failures
print df_labels.shape
#df["output"] = process(df)[0] # [0] for output not failures
#print df.shape
#print df.head()

## investigate failures!
#failures = process_documents(df)[1]
#df_failures = df.iloc[[i[0] for i in failures],:]
#print "Failures occured on: " + str(df_failures.shape[0]) + " documents."
#df_failures.head()

## make a copy and filter for non null output strings
df_tosave = df_labels.copy()[df_labels['output'].notnull()]
#df_tosave = df.copy()[df['output'].notnull()]
df_tosave.drop('text', axis=1, inplace=True)
print df_tosave.shape

df_tosave.to_csv(filename_out, sep = ",", header=False, index=False, quoting=csv.QUOTE_NONE)
## save without header or index/rownames or quotes around the string.

print "Done!"
