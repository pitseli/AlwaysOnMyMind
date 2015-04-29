library("R.matlab")  # Package to read Matlab files
library("abind")     # Package to combine multi-dimensional arrays
library("ggplot2")   # Package for plotting
library("reshape")   # Package for data reshaping
library("ROCR")      # Package for classifier performance measures

library("MASS")      # Package for LDA

## It is recommended to use a regularized LDA version; in Matlab an
## implementation is available in the BBCI Toolbox:
## - http://bbci.de/toolbox/ToolboxSetup.html
## - Function 'train_RLDAshrink'



### Read epoched data (see 'AOMMread.m' file): #######################

epo <- local({
  irr <- readMat("example_epoched_cleaned_datairr.mat")$d   # ALLEEG(1).data
  rel <- readMat("example_epoched_cleaned_datarel.mat")$d   # ALLEEG(2).data
  cat <- readMat("example_epoched_cleaned_datacat.mat")$d   # ALLEEG(3).data

  data <- abind(irr, rel, cat)
  
  ev <- c(rep("IRR", dim(irr)[3]), rep("REL", dim(rel)[3]), rep("CAT", dim(cat)[3]))
  ev <- factor(ev, levels = c("REL", "IRR", "CAT"))
  
  ti <- as.numeric(readMat("example_epoched_cleaned_times.mat")$t)         # ALLEEG(1).times
  ch <- unlist(readMat("example_epoched_cleaned_chanlocs.mat")$l[1, 1, ])  # ALLEEG(1).chanlocs
  
  dimnames(data)[[1]] <- ch
  
  list(data = data, event = ev, times = ti)
})


str(epo)



### Grand average of Pz channel: #####################################

d_pz <- epo$data["Pz", , ]

str(d_pz)


## Compute grand average:
ga_rel <- rowMeans(d_pz[, epo$event == "REL"])
ga_irr <- rowMeans(d_pz[, epo$event == "IRR"])
ga_cat <- rowMeans(d_pz[, epo$event == "CAT"])

ga_rel

## Plot it:
plot(ga_rel, type = "n", ylim = c(-5, 7), axes = FALSE)
axis(2)
axis(1, at = seq(1, 500, by = 50), labels = epo$times[seq(1, 500, by = 50)])
box()

lines(ga_rel, col = "green")
lines(ga_irr, col = "red")
lines(ga_cat, col = "blue")

## Let's ignore the cats ...



### Simple feature engineering: ######################################

## Four intervals:
int <- rbind(c(300, 350),
             c(350, 400),
             c(400, 450),
             c(450, 500))
int


## Which rows in the data array are inside the intervals?
idx <- apply(int, 1, function(i) which(epo$times > i[1] & epo$times <= i[2]))
idx


## Extract features with 'mean' aggregation:
str(d_pz)                        # Full data set
str(d_pz[idx[, 1], ])            # Specific time intervals
str(colMeans(d_pz[idx[, 1], ]))  # Mean aggregation, one value per epoch


## Create feature set:
featdf <- apply(idx, 2, function(i) colMeans(d_pz[i, ]))
featdf <- as.data.frame(featdf)
featdf$Relevance <- epo$event

str(featdf)
head(featdf)
summary(featdf)


## Remove 'CAT' epochs:
featdf <- subset(featdf, Relevance != "CAT")
summary(featdf)

featdf$Relevance <- featdf$Relevance[, drop = TRUE]
summary(featdf)
head(featdf)



### A bit of feature analysis: #######################################

ggplot(melt(featdf), aes(Relevance, value)) + geom_boxplot()
ggplot(melt(featdf), aes(Relevance, value)) + geom_boxplot() + facet_grid(. ~ variable)


## Can we see the difference?
plot(featdf$V3, featdf$V4, pch = 19, col = featdf$Relevance, cex = 0.5)


## Some indications for a difference:
wilcox.test(V1 ~ Relevance, data = featdf)
wilcox.test(V2 ~ Relevance, data = featdf)
wilcox.test(V3 ~ Relevance, data = featdf)
wilcox.test(V4 ~ Relevance, data = featdf)



### Let's build a more complex feature set: ##########################

## Take every channel into account:
featdf <- lapply(rownames(epo$data),
                 function(ch) {
                   apply(idx, 2, function(i) colMeans(epo$data[ch, i, ]))
                 })
featdf <- do.call(cbind, featdf)
str(featdf)


featdf <- as.data.frame(featdf)
featdf$Relevance <- epo$event
featdf <- subset(featdf, Relevance != "CAT")
featdf$Relevance <- featdf$Relevance[, drop = TRUE]

str(featdf$Relevance)

str(featdf)


### Setup training and test sets: ####################################

p = 0.75  # Ratio for training and test set

idx <- seq(nrow(featdf))
idx <- split(idx, featdf$Relevance)  # str(idx)

set.seed(1234)

idx_train <- lapply(idx, function(i) sample(i, round(length(i) * p)))  # str(idx_train)
idx_test <- mapply(setdiff, idx, idx_train)  # str(idx_test)

str(idx_train)

## Class ratio OK?
length(idx$REL) / length(idx$IRR)
length(idx_train$REL) / length(idx_train$IRR)
length(idx_test$REL) / length(idx_test$IRR)

idx_train <- unlist(idx_train)
idx_test <- unlist(idx_test)



### Fit regularized LDA classifer: ###################################

cl <- lda(Relevance ~ ., data = featdf[idx_train, ])


### Trainings error:
p_train <- predict(cl, newdata = featdf[idx_train, ])

str(p_train)
head(p_train$class)
head(p_train$posterior)

## Confusion table:
table(Prediction = p_train$class, Truth = featdf$Relevance[idx_train])



### Test error:
p_test <- predict(cl, newdata = featdf[idx_test, ])

## Confusion table:
table(Prediction = p_test$class, Truth = featdf$Relevance[idx_test])


## More detailed performance measures:
pred <- prediction(p_test$posterior[, "REL"], featdf$Relevance[idx_test])

performance(pred, "auc")@y.values[[1]]  # AUC

op <- par(mfrow = c(2, 1), mar = c(0, 0, 0, 0))
plot(performance(pred, "prec"))
abline(v = 0.5)
plot(performance(pred, "rec"))
abline(v = 0.5)
par(op)



### Summary: #########################################################

## This shows the basic workflow of building an ERP classifier
##
## Things to improve for homework:
## - Cross-validation (or other resampling method) for estimation of the
##   generalization erro
## - Better feature selection (e.g., via cross-validation)
## - Different classifier



