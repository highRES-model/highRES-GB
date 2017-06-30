# -*- coding: utf-8 -*-
"""
Created on Mon May  8 15:47:28 2017

@author: Andy
"""
import os
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
from scipy import stats
path=r'C:\Users\Andy\Google Drive\Extended Research\graphing'

file = path+r'\cost_data.csv'
costs_raw = pd.read_csv(file)
costs = costs_raw[costs_raw.turbines>=10]

plt.plot(costs['depth'],costs['cost'],'o')
plt.title('Offshore Wind Costs - Existing and Planned, UK')
plt.ylabel('Cost per MW (£millions)')
plt.xlabel('Average Depth (m)')

outCosts = {}

outCosts['shallow'] = costs[costs.depth<=20].cost.mean()
outCosts['mid'] = costs[costs.depth>=20].cost.mean()

slope, intercept, r_value, p_value, std_err = stats.linregress(costs[costs.depth<=20]['depth'],
                                                               costs[costs.depth<=20]['cost'])
UKTM_depth = 15
outCosts['UKTM_equivalent'] = intercept + slope*UKTM_depth

costRatio = {}
for k in outCosts.keys():
    costRatio[k] = outCosts[k]/outCosts['UKTM_equivalent']
print(outCosts)
print(costRatio)