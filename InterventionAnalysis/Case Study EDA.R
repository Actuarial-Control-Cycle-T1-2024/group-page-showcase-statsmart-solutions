# ACTL5100 Case Study 
# Kate Jones

setwd("~/Documents/UNSW/ACTL5100/Case Study")
library(data.table)
library(stringr)
library(janitor)
library(tidyverse)
library(ggrepel)

## initial data cleaning and adding relevant cols
interventions <- fread("interventions.csv")
names(interventions) <- make_clean_names(names(interventions))

interventions[, mort_impact_lower := as.numeric(str_extract(approximate_impact_on_mortality_rates, "\\d+"))]
interventions[, mort_impact_upper := as.numeric(str_extract(approximate_impact_on_mortality_rates, "\\d+(?=%(?!.*\\d+%.*$))"))]
interventions[, mort_impact_ave := rowMeans(interventions[,c('mort_impact_lower', 'mort_impact_upper')])]

interventions[, cost_lower := as.numeric(str_extract(approximate_per_capita_cost, "\\d+"))]
interventions[, approximate_per_capita_cost := gsub(",", "", approximate_per_capita_cost)]  # one cost value has a comma, need to remove else r won't read full value
interventions[, cost_upper := as.numeric(str_extract(approximate_per_capita_cost, "\\d+(?= per(?!.*\\d+ per.*$))"))]
interventions[, cost_mean := rowMeans(interventions[, c('cost_lower', 'cost_upper')])]

interventions[, row_id := 1:.N]

# adding policyholder & population data (info from Lumaria encyclopedia entry and in force dataset)
inforce <- 978582
smoking_perc <- 0.18

# creating estimates of how many people affected by each intervention; this is done manually by examining each intervention 
# ASSUMPTIONS: (1) interventions only affect policyholders
# (2): the participation in programs (eg educational workshop) is estimated to be 40% of target population; this uptake percentage can be adjusted - maybe do some research?
# (3): for workshops/programs/campaigns etc, 10 sessions/programs are conducted a year
# (4): for interventions that pay by incentive (eg vaccinations), there are 5 per year
# (5): 50% of population has/will have at some point a chronic disease (this 50% is the Australian statistic, possibly need to change for Lumaria? Source: https://www.abs.gov.au/statistics/health/health-conditions-and-risks/health-conditions-prevalence/latest-release)
# (6): 10 apps used in well-being apps intervention, 5 events per year in social events intervention & 5 wellness retreats p.a.

uptake <- 0.4 
num_sessions <- 10
num_incentives <- 5
chronic <- 0.5
interventions[, cost_per_annum := cost_mean]  
# for interventions that pay per participant or similar:
interventions[c(2, 4:6, 8, 9, 12:16, 18:22, 30, 31, 33, 36, 38, 40, 50), cost_per_annum := cost_mean*uptake*inforce] # changes are done manually per intervention depending on what the cost is for (eg per participant, per program etc)
# interventions that pay per program/workshop:
interventions[c(7, 10, 24:26, 28, 32, 34, 37, 39, 41:44, 46, 47), cost_per_annum := cost_mean * num_sessions]
# intervtions that pay per incentive: 
interventions[c(11, 29, 49), cost_per_annum := cost_mean * num_incentives]
# other manual manipulations: 
interventions[3, cost_per_annum := cost_mean * inforce * smoking_perc]
interventions[17, cost_per_annum := cost_mean * inforce * 0.5]
interventions[23, cost_per_annum := cost_mean * 10]  # assumed 10 apps to be used
interventions[27, cost_per_annum := cost_mean * 5]  # assumed 5 social events p.a.
interventions[48, cost_per_annum := cost_mean * 5]  # assumed 5 wellness retreats p.a.

fwrite(interventions, 'interventions manipulated.csv')


#### visualisations
theme_set(theme_classic())

## looking at individual costs and benefits, no adjustments for number of people affected etc
# mort impact
ggplot(data = interventions, mapping = aes(x = row_id, y = mort_impact_ave)) + geom_point(color = 'hotpink') + 
  labs(x = 'Intervention', y = 'Mean Reduction in Mortality')

# cost
ggplot(data = interventions, mapping = aes(x = row_id, y = cost_mean)) + geom_point(color = 'blue') + 
  labs(x = 'Intervention', y = 'Mean Cost to Implement')

# cost vs mort impact
ggplot(data = interventions, mapping = aes(x = mort_impact_ave, y = cost_mean)) + geom_point(color = 'red') + 
  labs(x = 'Mean Reduction in Mortality', y = 'Mean Cost to Implement')

# cost vs mort, zoomed in to main section
ggplot(data = interventions, mapping = aes(x = mort_impact_ave, y = cost_mean)) + geom_point(color = 'red') + 
  labs(x = 'Mean Reduction in Mortality', y = 'Mean Cost to Implement') + coord_cartesian(xlim = c(1, 10), y = c(0, 700)) + 
  geom_text_repel(aes(label = ifelse(mort_impact_ave >= 5, row_id, "")), 
                  box.padding = 0.5, 
                  point.padding = 0.5,
                  segment.color = "grey",
                  direction = "both", 
                  max.overlaps = 100)
# the optimal point is bottom right corner, ie high reduction in mortality plus low cost
# this is intervention 35 and 37, ie Incentives for Preventive Screenings and Cancer Prevention Initiatives

## costs and benefits over full in force population (ie costs adjusted to be annual amounts - note many assumptions are made so these values could be v different)
# cost pa vs mort reduction
ggplot(data = interventions, mapping = aes(x = mort_impact_ave, y = cost_per_annum)) + geom_point(color = 'red') + 
  labs(x = 'Mean Reduction in Mortality', y = 'Mean Cost p.a. to Implement')

# cost pa vs mort, excl smoking intervention
ggplot(data = interventions, mapping = aes(x = mort_impact_ave, y = cost_per_annum)) + geom_point(color = 'red') + 
  labs(x = 'Mean Reduction in Mortality', y = 'Mean Cost p.a. to Implement') + coord_cartesian(xlim = c(0, 10)) +
  geom_text_repel(aes(label = ifelse(mort_impact_ave >= 5, row_id, "")), 
                  box.padding = 0.5, 
                  point.padding = 0.5,
                  segment.color = "grey",
                  direction = "both", 
                  max.overlaps = 100)
# now option 7 (weight management programs) seems to be an optimal option as well 
# 16 (heart health screenings) is pretty good too but keep in mind the y axis (cost) is very large so 16 is still relatively costly
# 28 (holistic stress reduction) and 41 (mindfulness programs) are good too


