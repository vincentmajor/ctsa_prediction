#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# test if there is EXACTLY TWO arguments: if not, return an error
if (length(args) != 2) {
  stop("EXACTLY two arguments must be supplied, starting and ending triple digit integers", call.=FALSE)
} else {
  ## extract the two start and end values
  iter.start = args[1]
  iter.end = args[2]
}

#### XML way of iterating ----

## load and install if necessary
if(!require(XML)){install.packages("XML", repos = "https://cloud.r-project.org"); library(XML)}

## check that the output dir exists.
if(!dir.exists("data/extracted")){
  dir.create("data/extracted")
}

## define a function to extract from one XML file
## takes a integer, i, which is the file number
## will automatically pad to 3 characters so 1, 10, 100 all fine
extract_from_one_XML = function(i){
  i.string = as.character(i)
  while(nchar(i.string) < 3){
    i.string = paste0("0", i.string)
  }

  ## skip down the XML tree to the good stuff
  first.path = "/PubmedArticleSet/PubmedArticle/MedlineCitation"

  writeLines(paste0("Started on iteration ", i, ", targeting file medline17n0", i, ".xml"))
  filename.in = paste0("data/raw/medline17n0", i.string, ".xml")
  filename.out = paste0("data/extracted/ex_medline17n0", i.string,".txt")
  
  if(file.exists(filename.out)){
    return(NA)
  }
  
  if(!file.exists(filename.in)){
    writeLines(paste0(filename.in, " cannot be found. Skipping this document"))
    return(FALSE)
  }
  
  ## set up xml and parse it
  doc <- xmlParse(filename.in, useInternalNodes = TRUE)
  
  ## time this part
  curr.time = proc.time()
  df.full = do.call(rbind, xpathApply(doc, first.path, function(node) {
    
    pmid <- xmlValue(node[["PMID"]])
    year = xmlValue(node[["Article"]][["Journal"]][["JournalIssue"]][["PubDate"]][["Year"]])
    title = xmlValue(node[["Article"]][["ArticleTitle"]])
    abstract = xmlValue(node[["Article"]][["Abstract"]])
    abstract = gsub("|", " ", abstract, fixed = TRUE)
    ## xmlValue concats any multiple nodes for structured abstracts
    ## remove any pipes before I use it as a delim - they do exist!
    #abstract = xmlValue(node[["Article"]][["Abstract"]][["AbstractText"]])
    
    data.frame(pmid, year, title, abstract, stringsAsFactors = FALSE)
    
  }))
  print(proc.time() - curr.time); remove(curr.time) ## took 165 seconds
  #remove(doc)
  
  ## some missingness in the year field and the abstracts for older articles
  ## remove any rows with missingness.
  df = na.omit(df.full)
  
  writeLines(paste0("This file contains ", nrow(df.full), " articles. Only ", nrow(df), " remain with complete data."))
  #remove(df.full) ## clean up
  
  ## write the complete df to file delimited by pipe because the abstracts 
  ## contain all kinds of crap
  ## swapping from readr::write_csv to base write.table with some non default arguments to avoid loading readr
  ## its also quicker
  #readr::write_delim(df, filename.out, delim = "|")
  write.table(df, filename.out, sep = "|", quote = F, row.names = F)
  #remove(df) ## clean up
  return(TRUE)
}

## testing
#extract_from_one_XML(352)
output.status = sapply(iter.start:iter.end, extract_from_one_XML)
print(output.status)
