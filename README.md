# highRES

This project folder contains reporting functions and the model setup for highRES (currently it does not have the input file generator functions).

The broad description of how to run highRES is:

1) Create input files (.dd files), all of which are referenced in highRES_data_input.gms
2) Choose model settings and run highRES_2017.gms from a command line. This produces an output sqlite database for each model run
3) Use reporting functions to analyse the sqldatabase. Bulk reporting is possible via write_individual_reports.py
4) Comparison reports can be written via write_comparison_reports.py, but this is very scenario specific, and was written for a specific sensitivity analysis looking at cost, waves, and renewable portfolio standard


# Setup

## Dependencies

### Geopandas

Geopandas is a pain to set up.
Using an anaconda distribution, it should be possible to install via
>conda install –c conda-forge geopandas

but it doesn’t seem to work.
Tutorial available here, takes probably 20min
http://geoffboeing.com/2014/09/using-geopandas-windows/

### Plotly
Working with version 
>plotly-1.12.9

# Files
## Pre processing
### pre_processing.py
Functions to write pandas dataframes to .dd files; calculate electrical losses depending on a file containing distance to grid; calculate extra cost associated with depth and produce scale factor file.

Writes offshore area restrictions based on specific shapefile.

### Offshore Wind
-Cost: data and files to calculate relative costs of different offshore wind types.
-Electrical: loss data and lookup table for regions with distance to shoreline.
-Floating: file containing average depth for each region, used to calculate the extra cost on floating wind (the floating_scale function in pre_processing.py)

## Model 
### model_runs.py
Runs the model with relevant switches for the wave/rps/cost scenarios.
### highRES_data_input.gms
Takes in data from .dd files to fill the model.
### highRES_2017.gms

The main model file. Has input switches
|Switch|Options|Description|
|---|---|---|
|floating|ON/OFF|Turns on or off floating wind|
|splitwind|ON/OFF|Turns on or off split offshore wind. If off uses single price and only Shallow and Mid depth input areas. Windoffshore_Shallow then represents all offshore wind|
|inputfile|filename|defines input gms|
|resultsfile|filename|defines results gms|
|UKTMCAP|ON/OFF|Defines whether or not national capacities are taken from the restriction file. Overwridden by RPS_on for most generators|
|RPS_on|ON/OFF| Whether to use the Renewable Portfolio Standard equation or not|
|fcost|number|Percentage relative cost to assign for floating wind relative to mid depth offshore|
|waves|ON/OFF| whether to use waves or not|
|wave_tol| number | Value in metres to use for wave tolerance on significant wave height|
|floatcostfix|ON/OFF| If on, sets the base level floating cost equal to mid depth (any scale factors applied afterwards)|
|fdepth|number|Maximum depth in m for floating wind|
|fdist|number| Maximum distance from shore in km for floating wind|


### highRES_results_2017.gms
Manipulates model output to create useful parameters and inputs everything to an sqlite database.

## Data Analysis
### reporting.py
The module containing reporting functions such as accessing database tables, manipulating data, producing graphs, and pulling graphs together into an html report.
### write_individual_reports.py
Loops through a data folder and produces a report and a directory of graphs for each database in that data folder.
Some variables need to be set to use the script

| Variable      | Type         | Definition |
| ------------- | ------------- | ---------|
| doGeospatial|switch| whether you want to do maps (using geopandas) |
| DATApath  | directory| The folder containing the sqlite databases |
| GISpath | directory | The folder containing GIS files|
| overwriteReports | switch | whether to overwrite the html files if they already exist |
| overwriteMaps | switch | whether to overwrite map images if they exist |
| reportOnDatabases | list of filenames | These reports will be written even if overwriteReports if set to False|

### write_comparison_reports.py
Writes comparison reports for specifically names databases. Quite bespoke to the wave/rps/cost scenario structure.
### data_management.py
Each model run produces an sqlite database. This script has functions that look at the data use of duplicate tables. Idea was to pull together the multiple databases into one place, but it is not complete.
### old_reports_file.py
This is the previous structure of the reporting function. Only refers to functions defined within itself.
