#!/usr/bin/env Rscript

## Default when nothing is passed
args = commandArgs(trailingOnly = TRUE)
if(length(args) != 2){
    args <- c("--help")    
}

## Help section
if("--help" %in% args) {
  cat("
      Plot the GC effects before and after correction 
 
      Example:
      ./plot_correction corrected.txt plot.png \n\n")
 
  q(save="no")
}

# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot
# objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)

  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)

  numPlots = length(plots)

  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                    ncol = cols, nrow = ceiling(numPlots/cols))
  }

 if (numPlots==1) {
    print(plots[[1]])

  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))

    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

cmd = paste("cat",args[1],"|cut -f 4,5,6 | shuf -n 200000", sep = " ")
data = read.table(pipe(cmd))
names(data) = c("gc", "raw", "corrected")

library("ggplot2")
library("reshape2")


ylm = 2*quantile(data$raw, .99)
p1 = ggplot(data, aes(x = gc, y = raw)) +
     geom_point(colour = "red", alpha = 0.1) +
     xlab("GC") + ylab("Raw Counts") + ggtitle("GC bias before correction") +
     ylim(0,ylm)

ylm = 2*quantile(data$corrected, .99)
p2 = ggplot(data, aes(x = gc, y = corrected)) +
     geom_point(colour = "blue", alpha = 0.1) +
     xlab("GC")+ylab("Corrected Counts") + ggtitle("GC bias after correction") + 
     ylim(0,ylm)
  
png(args[2], width = 2000, height = 480)  
multiplot(p1,p2,cols=2)
dev.off()

