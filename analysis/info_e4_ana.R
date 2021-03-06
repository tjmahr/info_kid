rm(list=ls())
source("analysis/useful.R")

d1 <- read.csv("data/info_e4_rep_data.csv")
d1$expt <- "replication"
d2 <- read.csv("data/info_e4_disambig_data.csv")
d2$expt <- "disambiguation"
d3 <- read.csv("data/info_e4_salience_data.csv")
d3$expt <- "salience"

d <- rbind(d1,d2,d3)
d$expt <- factor(d$expt, levels=c("replication","disambiguation","salience"))
d$age <- d$age_group
d$age[d$age >= 5] <- 4.99 # rounding error in the anonymization process

md <- melt(d, id.vars=c("SID","age","expt"),
           measure.vars=names(d)[grepl("ambig",names(d)) |
                                   grepl("inference",names(d))],
           value.name = "correct")

md$trial <- as.numeric(str_sub(md$variable,2,2))
md$trial.type <- c("filler","inference")[as.numeric(grepl("inference",md$variable))+1]

# reverse disambiguation responses
# the disambiguation "inference" trials are coded as correct when
md$correct[md$expt=="disambiguation" & md$trial.type=="inference"] <- 1 - md$correct[md$expt=="disambiguation" & md$trial.type=="inference"]

mss <- aggregate(correct ~ trial.type + expt + age + SID,
                 md, mean)
mss$age_group <- factor(floor(mss$age))

ms <- ddply(mss, .(trial.type,expt,age_group),
            summarise,
            cil = ci.low(correct),
            cih = ci.high(correct),
            n = length(correct),
            age = mean(age),
            sd = sd(correct,na.rm=TRUE),
            correct = mean(correct))

#quartz()

p_original <- ggplot(ms) +
  aes(x = age_group, y = correct, fill = trial.type,
      ymin = correct - cil, ymax = correct + cih) +
  stat_identity(geom = "bar", position = position_dodge(.9)) +
  stat_identity(geom = "linerange", position = position_dodge(.9)) +
  geom_hline(yintercept = .5, lty = 2) +
  labs(x = "Age Group (Years)", y = "Proportion Inference Consistent") +
  facet_wrap("expt")

# l2 <- lmer(correct ~ age.group + type  + (type|subid) + (1 |item),
#            data=d1,family="binomial")

md$age_group <- factor(floor(md$age))

l1 <- glmer(correct ~ age_group * expt + (1 | SID) + (1 | variable),
             data=subset(md, trial.type=="inference"), family="binomial")
l2 <- glmer(correct ~ age_group + expt + (1 | SID) + (1 | variable),
             data=subset(md, trial.type=="inference"), family="binomial")
anova(l2,l1)
summary(l2)
