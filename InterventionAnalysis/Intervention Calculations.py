# -*- coding: utf-8 -*-
"""
Created on Fri Mar  8 12:56:46 2024

@author: 231334
"""

#%%
# Import packages
import pandas as pd
import os
import seaborn as sns
import numpy as np
import math

#%%
# Set working directory
os.chdir("C:\\Users\\231334\\OneDrive - QBE Management Services Pty Ltd\\University")

# Import data
interventions = pd.read_csv("./interventions manipulated - FINAL.csv")
df = pd.read_csv("./2024-srcsc-superlife-inforce-dataset (2).csv",skiprows=3)
econ = pd.read_excel("./srcsc-2024-lumaria-economic-data - Modified.xlsx",skiprows=11)

#%%
# Define the new variables for the inforce dataset (df)
# FIX the Lapse Indicator
df['Lapse.indicator'] = np.where(df['Lapse.Indicator'].isna(),1,0)
df = df.drop(columns=['Lapse.Indicator'])

# Create the active indicator
df["Actives_Indicator_1"] = np.where(df['Death.indicator'] == 1,'Death',0)
df["Actives_Indicator_2"] = np.where(df['Lapse.indicator'] == 1,'Lapsed',df["Actives_Indicator_1"])
df["Actives_Indicator"] = np.where(df["Actives_Indicator_2"] == 0,'Active',df["Actives_Indicator_2"])
df = df.drop(columns=['Actives_Indicator_1','Actives_Indicator_2'])

# Create the Policy.Age variable
df['Policy.Age'] = 2024 - df['Issue.year'] 

# Create Age.At.Death
df['Age.At.Death'] = np.where(df['Death.indicator'] == 1,df['Issue.age']+df['Year.of.Death']-df['Issue.year'],np.nan)

# Age at 2024
df['Age.At.2024'] = np.where(df['Death.indicator'] == 1,'Dead',df['Issue.age']+2024-df['Issue.year'])

#%%
df['Face.amount'] = df['Face.amount'].astype('float')

Results = pd.crosstab(df['Year.of.Death'],df['Face.amount'].sum(),values = df['Face.amount'],aggfunc = 'sum')
Results = Results.set_axis(['Sum of Payouts'], axis=1)
Results = Results.reset_index()


#%%
# Calculating the mortality assumption
interventions['Mortality_Impact'] = interventions['mort_impact_ave']*interventions['Impacted Population']


#%%
# Calculating payouts with no intervention
M = econ[econ['Year']>=2001]
M = M[['Year','Present Value Factor (End of 2023)']]

Orig_Results = Results.merge(M, left_on = ['Year.of.Death'], right_on= ['Year'])

Orig_Results['PV Results'] = Orig_Results['Present Value Factor (End of 2023)']*Orig_Results['Sum of Payouts']
Orig_Payout = Orig_Results['PV Results'].sum()


#%% 
# Testing for Interventions
# For each intervention, you must define two different factors
# 1. Define the mortality difference and impact on sum of payouts
M = econ[econ['Year']>=2001]
M = M[['Year','Present Value Factor (End of 2023)']]

X = interventions['Mortality_Impact']
Z = []

for i in X:
    Results_Updated = Results
    Results_Updated['Updated Sum of Payout'] = Results_Updated['Sum of Payouts']*(100-i)/100
    Results_2 = Results_Updated.merge(M, left_on = ['Year.of.Death'], right_on= ['Year'])
    Results_2['PV Results'] = Results_2['Present Value Factor (End of 2023)']*Results_2['Updated Sum of Payout']
    Y = Results_2['PV Results'].sum()
    Z.append(Y)


interventions['Intervention_Payout'] = Z


#%% 
# Now calculating Cost for each of the interventions
interventions['Cost per Year'] = interventions['cost_mean']*interventions['Assumed Frequency (per year)']
    
X = interventions['Cost per Year']
M = econ[econ['Year']>=2001]
M = M[['Year','Present Value Factor (End of 2023)']]

Z=[]
    
for i in X:
    M['Yearly Cost'] = i
    M['PV Yearly Cost'] = M['Yearly Cost']*M['Present Value Factor (End of 2023)']
    Y = M['PV Yearly Cost'].sum()
    Z.append(Y)
    
    
interventions['Total Cost'] = Z
#interventions['']
interventions['Benefit'] = Orig_Payout - interventions['Intervention_Payout'] - interventions['Total Cost']

#%% 
# Picking the top 10     
interventions_sorted = interventions.sort_values(by='Benefit',ascending=False)
Final10 = interventions_sorted[0:10]

Final10.to_excel('Final10Interventions.xlsx')
    
#%%
# Calculate the count of new policyholders by year
X = df['Issue.year'].value_counts()
X = X.sort_values()
# Calculate the count of lapsed policyholders by year
Y = df['Year.of.Lapse'].value_counts()
Y = Y.sort_values()    
# Calculate the count of lapsed policyholders by year
Z = df['Year.of.Death'].value_counts()
Z = Z.sort_values()  

