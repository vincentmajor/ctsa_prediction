import numpy as np
import pandas as pd
import sys
import csv
import os

print 'Number of arguments:', len(sys.argv), 'arguments.'
print 'Argument List:', str(sys.argv)

if "ipykernel" not in sys.argv[0]:
    i_start = sys.argv[1]
    i_end = sys.argv[2]
else:
    i_start = 348 ## test case
    i_end = 348
    print "example"
print "Targeting files " + str(i_start) + " to " + str(i_end)

## Ensure the output directory exists, creat if not.
if not os.path.exists('data/processed'):
    os.makedirs('data/processed')

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
## define a function that loads a file, processes and saves the result
## takes a single integer as input
def load_process_save(i):
    ## If the argument is less then 3 characters, pad with zeros on the left
    i_string = str(i)
    while len(i_string) < 3:
        i_string = "0" + i_string
    #print i_string
    print "Targeting file: " + 'data/extracted/ex_medline17n0' + i_string + '.txt'

    ## check file exists, skip if not
    if not os.path.isfile('data/extracted/ex_medline17n0' + i_string + '.txt'):
        print 'Failed to find file: ' + 'ex_medline17n0' + i_string + '.txt' 
        return(False)
    
    ## Reading raw file with pmid, year, title, and abstracts
    ## this file is created after extraction from XML 
    raw = pd.read_table('data/extracted/ex_medline17n0' + i_string + '.txt', sep="|", quotechar='"', error_bad_lines=False)

    ## remove years 2007 and earlier
    year_mask = raw['year'] >= 2000

    raw_concat = raw[year_mask].copy()
    ## combine title and abstracts into one text field and drop the parents
    raw_concat["text"] = raw_concat["title"] + " " + raw_concat["abstract"]

    #print raw_concat["title_abstract"][0]
    raw_concat.drop('pmid', axis=1, inplace=True)
    raw_concat.drop('year', axis=1, inplace=True)
    raw_concat.drop('title', axis=1, inplace=True)
    raw_concat.drop('abstract', axis=1, inplace=True)

    ## check for and remove any rows with null text field
    ## don't care if pmid or year is incomplete here
    df = raw_concat[raw_concat['text'].notnull()]

    ## now apply processing function to the real df
    df["output"] = process(df)[0] # [0] for output not failures
    print df.shape
    df.head()

    ## investigate failures!
    #failures = process_documents(df)[1]
    #df_failures = df.iloc[[i[0] for i in failures],:]
    #print "Failures occured on: " + str(df_failures.shape[0]) + " documents."
    #df_failures.head()

    ## make a copy and filter for non null output strings
    df_tosave = df.copy()[df['output'].notnull()]
    df_tosave.drop('text', axis=1, inplace=True)
    print df_tosave.shape

    df_tosave.to_csv('data/processed/prc_medline17n0' + i_string + '.txt', sep = ",", header=False, index=False, quoting=csv.QUOTE_NONE)
    ## save without header or index/rownames or quotes around the string.
    return(True)


for i in range(int(i_start), int(i_end)+1):
    load_process_save(i)
