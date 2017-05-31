#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# test if there is EXACTLY ONE argument: if not, return an error
if (length(args) != 1) {
  stop("EXACTLY one argument must be supplied - a valid path to an xml file.", call.=FALSE)
} else {
  ## extract the argument, the path to file
  path.string = args[1]
}

#### XML way of iterating ----

## load and install if necessary
if(!require(XML)){install.packages("XML", repos = "https://cloud.r-project.org"); library(XML)}

## define a function to extract from one file
## takes a string path
extract_XML_from_path = function(s){

  ## skip down the XML tree to the good stuff
  first.path = "/PubmedArticleSet/PubmedArticle/MedlineCitation"

  #writeLines(paste0("Started on iteration ", i, ", targeting file medline17n0", i, ".xml"))
  filename.in = s
  filename.out = gsub(".xml", "_extracted.csv", filename.in)
  writeLines(paste0("Attempting to extract data from ", filename.in, ", into ", filename.out, "."))
  
  if(file.exists(filename.out)){
    writeLines("The output file already exists, skipping execution.")
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
  #df = na.omit(df.full)
  df = df.full ## emptiness is fine for labeled articles.
  
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


output.status = extract_XML_from_path(path.string)
print(output.status)
writeLines("Done!")
