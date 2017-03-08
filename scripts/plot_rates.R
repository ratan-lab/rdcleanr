#!/usr/bin/env Rscript

## Default when nothing is passed
args = commandArgs(trailingOnly = TRUE)
if(length(args) != 2){
    args <- c("--help")    
}

## Help section
if("--help" %in% args) {
  cat("
      Plot the fragment rates for GC values 
 
      Example:
      ./plot_rates rates.txt plot.png \n\n")
 
  q(save="no")
}

data = read.table(args[1])
names(data) = c("gc", "numpos", "numfrags", "orate", "srate")

library(ggplot2)
p = ggplot(data) +
    geom_point(aes(x = gc, y = orate)) +
    geom_line(aes(x = gc, y = srate)) +
    ylim(0, max(data$orate)) +
    xlab("GC") +
    ylab("Rate")

png(args[2])
p
dev.off()
