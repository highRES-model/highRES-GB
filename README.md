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

