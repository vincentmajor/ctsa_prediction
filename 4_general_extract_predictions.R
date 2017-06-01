#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# test if there is at least TWO arguments: if not, return an error
if (length(args) <= 1) {
  stop("At least two arguments must be supplied, filenames for fasttext predictionss and the raw test data for true labels", call.=FALSE)
} else {
  ## extract the arguments
  path.results = args[1]
  path.test = args[2]
}
 
## load and install if necessary
if(!require(dplyr)){install.packages("dplyr", repos = "https://cloud.r-project.org"); library(dplyr)}
if(!require(tidyr)){install.packages("tidyr", repos = "https://cloud.r-project.org"); library(tidyr)}
if(!require(ROCR)){install.packages("ROCR", repos = "https://cloud.r-project.org"); library(ROCR)}

extract_predictions = function(path.results, path.test){
  ## first, read the table in.
  raw = read.table(path.results, sep = " ", header = F)
  ## hard coded headers throughout -- this could be improved!
  colnames(raw) = c("pred_a", "prob_a", "pred_b", "prob_b", "pred_c", "prob_c")
  ## format is not label_1, label_2 etc, instead ordered by probability
  ## rows == length test file
  
  ## use tidyr::unite to combine columns to then sort in order
  raw.combined = unite(raw, a, pred_a, prob_a) %>% unite(b, pred_b, prob_b) %>% unite(c, pred_c, prob_c)
  raw.ordered = data.frame(t(apply(raw.combined, 1, sort)))
  colnames(raw.ordered) = c("prob_1", "prob_2", "prob_3")
  
  ## define function to extract the probability after the __label__ prefix
  remove_label_string = function(x){
    substring(x, 12) ## everything after the 12th character
  }
  ## use it
  df = raw.ordered %>% mutate_each(funs(remove_label_string))
  colnames(df) = c("prob_1", "prob_2", "prob_3")
  
  ## the truth, read as lines, extract only the tenth character
  ## does not allow longer labels -- could be improved!
  testset.raw = readLines(path.test)
  testset.labels = sapply(testset.raw, function(x) substr(x, 10, 10) )
  names(testset.labels) <- NULL
  
  ## combine into prob df and save to file
  df$truth = testset.labels
  write.csv(df, file = gsub(".txt", "_tidy.csv", path.results), row.names = FALSE )
  
  ## now AUC
  
  auc.matrix = matrix(0, nrow = 1, ncol = 3)
  for(class in 1:(ncol(df)-1)){
    truth = as.integer(df[,ncol(df)] == class)
    probs = as.numeric(df[,class])
    
    pred = ROCR::prediction(probs, truth)
    auc.matrix[1,class] = ROCR::performance(pred, measure = 'auc')@y.values[[1]]
    roc = ROCR::performance(pred, measure = 'tpr', x.measure = 'fpr')
    
    png(gsub(".txt", ".png", path.results), width = 6, height = 6, units = "in", res = 300)
    plot(roc, ylim = c(0,1), xlim = c(0,1), col = 'white', cex.lab = 1.4, yaxs='i', xaxs='i')
    grid(lty = 'solid')
    abline(0,1)
    lines(roc@x.values[[1]], roc@y.values[[1]], col = grey(0.2, alpha = 0.5), lwd = 4)
    dev.off()
  }
  write.csv(auc.matrix, gsub(".txt", "auc_matrix.csv", path.results), row.names = F)
  
}

extract_predictions(path.results, path.test)

writeLines("Done!")