import os
import sys
file_dir = os.getcwd()
sys.path.append(file_dir)
from reporting import *

DATApath = r'C:\Users\ucqba01\Documents\Local Data\Round 6'
round6 = makeComparisonTable(DATApath)
plotComparisonHeatmaps(round6.replace(to_replace={'waves':{10000:'OFF',400:'ON'}}),['ON','OFF'],[20,40,60,80,90,95],[80,100,120,140],'all',DATApath)
