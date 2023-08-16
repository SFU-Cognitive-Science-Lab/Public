# Title: FB Analyses
#
# Description: Performs some basic descriptive tests and lmers for the FB 1s9s Experiment
#
# Author: Mark Blair (though I copied extensively from ExNovo 2 Analyses script by Justin O)
# Date Created: 4/19/2023
# Last Edit: Aug 14th 2023
#
# Input: FB2data.txt (or FB3data.txt) in the vault exnovo folder
#
# Output: Statistical tests and assumption checking models for FB 1s9s
# 
## Review and Verrify: 
# Reviewed: Kat [Aug-10-2023]
# Verified: Tyrus [Aug-16-2023]

## PREAMBLE ----

# Uncomment the install packages line if you don't have either of these installed
#install.packages("lme4")
library(lme4)
#install.packages("dplyr")
library(dplyr)
#install.packages("ggplot2")
library(ggplot2)
#install.packages("car")
library(car)
#install.packages("gridExtra")
library(gridExtra)
#install the svglite package
library(svglite)

# clear environment
rm(list = ls())

# set the data_source
data_source <- "FB2data" # can also use FB3data

# Save output
output_file <- paste(data_source,"_analysis_output.txt", sep = " ")
sink(output_file, append = FALSE)

# Set the directory to wherever you have the data file installed
dir1<-rstudioapi::selectDirectory()
setwd(dir1)

# Get the current date and time
current_time <- Sys.time()

# Print the current time and date and data file used
print(current_time)
print(data_source)
cat("\n\n")

# Import Data 
file_path <- file.path(dir1, paste(data_source,".txt", sep = "")) 
data <- read.csv(file_path)

## DATA PROCESSING ------
data = select(data, Subject, FeedbackRT, TrialID, TrialAccuracy)

# Add new condition column
data$Condition = round(data$FeedbackRT,-3)/1000
data$Condition <- factor(data$Condition, levels = c(1, 9), labels = c("Condition 1", "Condition 9"))


# filter for first 6 bins (24*6)
data <- filter(data, TrialID <= 144)

trials_per_bin <- 24
data$TrialBin <- cut(data$TrialID, breaks = seq(0, max(data$TrialID) + trials_per_bin, by = trials_per_bin), labels = FALSE)

# bin all data
ACC.data <- data %>%
  group_by(Subject, Condition, TrialBin) %>%
  summarise(binAcc = mean(TrialAccuracy, na.rm = TRUE),
            nTrials = n(), .groups = 'drop')

# Get the list of Subjects with a sum of nTrials not equal to 144
subject_totals <- ACC.data %>%
  group_by(Subject) %>%
  summarise(totalTrials = sum(nTrials), .groups = 'drop')

subjects_not_144 <- subject_totals %>%
  filter(totalTrials != 144) %>%
  pull(Subject)

print(subjects_not_144)

# filter out subjects without 144 trials.
filtered_ACC_data <- ACC.data %>%
  filter(!Subject %in% subjects_not_144)

avg_binAcc <- filtered_ACC_data %>%
  group_by(Condition, TrialBin) %>%
  summarise(mean_binAcc = mean(binAcc),
            num_subjects = n(), .groups = 'drop')
print(avg_binAcc)

# Calculate the SEM for mean_binAcc
conf_intervals <- filtered_ACC_data %>%
  group_by(Condition, TrialBin) %>%
  summarise(
    mean_binAcc = mean(binAcc),
    sem_binAcc = sd(binAcc) / sqrt(n()),
    .groups = 'drop'
    )

# Convert Condition to a factor with specific labels
avg_binAcc$Condition <- factor(avg_binAcc$Condition, levels = c(1, 9), labels = c("1s FB", "9s FB"))

# Create a plot of mean_binAcc split by Condition and TrialBin with SEM error bars
# color blind safe options
colours1 <- c('#66c2a5', '#fc8d62', '#8da0cb')
colours2 <- c('#1b9e77', '#d95f02', '#7570b3')

ggplot(conf_intervals, aes(x = TrialBin, y = mean_binAcc, group = Condition, color = Condition)) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = mean_binAcc - sem_binAcc, ymax = mean_binAcc + sem_binAcc), width = 0.2) +  # Add SEM as error bars
  labs(x = "Trial Bin", y = "Mean Accuracy", color = "Condition") +
  scale_x_continuous(breaks = 1:6) +  # Set custom x-axis breaks
  theme_classic()+
  scale_color_manual(values = colours2, labels = c("1s FB", "9s FB")) +  # Update the labels in the legend
  scale_fill_manual(values = colours2)+
  theme(title = element_text(size=unit(16, 'points'), family='Arial', color='black'))+
  theme(axis.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(axis.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(plot.margin = unit(c(2,2,2,2), 'points'))

# Save the plot as a svg file
plotfilename <- paste(data_source,"_output_plot.svg", sep = "")
ggsave(plotfilename, width = 8, height = 6, units = "in")

# ACCURACY STATS===================

# set Condition and Subject as a factor
ACC.data$Condition <- as.factor(ACC.data$Condition)
ACC.data$Subject <- as.factor(ACC.data$Subject)

# set up base model TrialBin
ACC.data.fit <- lmer(binAcc ~ TrialBin + (1 | Subject ), data = ACC.data)
summary(ACC.data.fit )
print(summary(ACC.data.fit))

# set up TrialBin + Condition model
ACC.data.fit.condition <- lmer(binAcc ~ TrialBin + Condition + (1 | Subject), data = ACC.data)
print(summary(ACC.data.fit.condition))

# add TrialBin * Condition interaction
ACC.data.fit.condition.interactaction <- lmer(binAcc ~ TrialBin + Condition + TrialBin * Condition + (1 | Subject), data = ACC.data)
print(summary(ACC.data.fit.condition.interactaction))

print(anova(ACC.data.fit.condition,ACC.data.fit))

# NOTES: Condition model fits significantly better

print(anova(ACC.data.fit.condition.interactaction, ACC.data.fit.condition))

# NOTES: Interaction model fits significantly better still - all this is obvious from the graph
# set seed (for bootstrap in CI calculation)
set.seed(5312684)

# NOTE: all assumption checking and model fitting work is down below the analyses

#-----Assumption Checking-----

# Accuracy
# plot of residuals against fitted values
plot(ACC.data.fit.condition.interactaction)
# no major heteroscedasticity

# index plot of residuals
x <- c(1:length(resid(ACC.data.fit.condition.interactaction)))
y <- c(resid(ACC.data.fit.condition.interactaction))
plot(x, y, ylab = "Residuals", xlab = "Case Number")
abline (0,0)
# independent errors, no autocorrelation

# qq plot of residuals
qqnorm(resid(ACC.data.fit.condition.interactaction))
qqline(resid(ACC.data.fit.condition.interactaction)) 
# slight stray from normality, but lmers are robust to this

sink()
closeAllConnections()
