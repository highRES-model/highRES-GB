import plotly as py
import plotly.graph_objs as go
import sqlite3 as sq
import pandas as pd
import os
from plotly import tools
import sys
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import geopandas as gpd

# import plotly.figure_factory as ff

legNames = {'Solar': 'Solar',
            'Windonshore': 'Onshore Wind',
            'Windoffshore_Shallow': 'Shallow Offshore',
            'Windoffshore_Mid': 'Mid Depth Offshore',
            'Windoffshore_Floating': 'Floating Offshore',
            'NaturalgasOCGTnew': 'Natural Gas OCGT'}


# function to return the parameter we want from specific database (connection object)
def get(table, con):
    return pd.read_sql('select * from ' + table, con)


def mergeGEN(vre, nonvre, con):
    vretab = get(vre, con).rename(columns={'vre': 'gen'})
    nonvretab = get(nonvre, con).rename(columns={'non_vre': 'gen'})
    return vretab.append(nonvretab)


def convertToInt(df, col):
    df[col] = pd.to_numeric(df[col])
    return df


#  reduce small numbers to zero. leaves original dataframe unchanged
def clean(df, col):
    df2 = df.copy()
    df2[col][df2[col] < 0.001] = 0
    return df2


# return list of tables in database whose names contain a specific string
def look(con,string):
    tables = getlist(con)
    return [t for t in tables if string in t]


# print tables and their sizes for tables in db that have string in name
def lookshape(string):
    for t in look(string):
        shape = get(t, con).shape
        print('%s\t%s' % (t, shape))


# return scenario settings from reading db file
def dbFileSettings(db):
    settings = {}
    settings['waves'] = int(db.split('waves')[1].split('_')[0])
    settings['fcost'] = int(db.split('fcost')[1].split('_')[0])
    settings['RPS'] = int(db.split('RPS')[1].split('_')[0])
    return settings


def makedbName(dbgeneric, labelDict):
    dbstring = dbgeneric
    for param in labelDict.keys():
        dbstring = dbstring.replace(param, str(labelDict[param]))
    return dbstring


# drop down to selected indices on df. eg. (h,df) then returns the sum over all other indices for each hour
def dropto(indices, df):
    df_piv = df.pivot_table(index=indices, aggfunc='sum').reset_index()
    return df_piv


def getlist(con):
    cursor = con.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")

    tables = cursor.fetchall()
    tables = [x[0] for x in tables]
    return tables


# create traces for bar graphs (one trace per set of data)
def bar_trace(df, X, Y):
    trace = go.Bar(
        x=df[X],
        y=df[Y]
    )
    return trace


# create bar chart with one series
def barplot(df, X, Y, title, file):
    trace = bar_trace(df, X, Y)

    data = [trace]
    layout = go.Layout(title=title, )
    fig = go.Figure(data=data, layout=layout)
    py.offline.plot(fig, filename=file, auto_open=False)
    return py.offline.plot(fig, filename=file, auto_open=False, output_type='div')


# barplot(get('vre_cap_tot',con),'vre','value','title',path+reportdir+'vrecap.html')


# create bar chart with multiple series. series is the column name with the series identifiers
# mode is either stack or group
def seriesbarplot(df, X, Y, series, mode, title, file):
    data = []
    if 'h' in df.columns:
        df = convertToInt(df, 'h')
    l = [x for x in df[series].unique()]
    l.reverse()
    for s in l:
        trace = go.Bar(
            x=df[df[series] == s][X],
            y=df[df[series] == s][Y],
            name=s
        )
        data.append(trace)
    layout = go.Layout(title=title, barmode=mode)
    fig = go.Figure(data=data, layout=layout)
    # py.offline.plot(fig,filename=file,auto_open=False)
    return py.offline.plot(fig, include_plotlyjs=False, output_type='div')


# gem_sum_h = mergeGEN('var_vre_gen_sum_h','var_non_vre_gen_sum_h',con)
# stackbarplot(gen_sum_h,'h','value','gen',path+reportdir+'generation_hourly.html')

def lineTrace(df, X, Y, name):
    trace = go.Scatter(x=df[X], y=df[Y], name=name)
    return trace


def makeSupplyCurveDf(df, vreCol, vreVal, lcoeCol, summationCol):
    vredf = df[df[vreCol] == vreVal].sort_values(by=lcoeCol)
    vredf['cummulative'] = vredf[summationCol].cumsum()
    return vredf


def plotSupplyCurves(df, X, Y, series, title, file, png=False):
    data = []
    for ser in df[series].unique():
        vredf = makeSupplyCurveDf(df, series, ser, Y, X)
        trace = lineTrace(vredf, 'cummulative', Y, ser)
        data.append(trace)

    axis_template = dict(showgrid=True, zeroline=True, showline=True)  # ,mirror='all')
    yax = axis_template
    yax['title'] = 'LCOE (£/MWh)'
    xax = axis_template
    xax['title'] = 'Cummulative Supply (TWh/yr)'

    layout = go.Layout(title=title, xaxis=xax, yaxis=yax, legend=dict(x=0.7, y=0.95))
    fig = go.Figure(data=data, layout=layout)
    py.offline.plot(fig, filename=file, auto_open=False)
    return py.offline.plot(fig, filename=file, output_type='div')


# div=plotSupplyCurves(VREsupply,'potential_generation_TWh','potential_lcoe(£/MWh)','series','Input Supply Curves',path+'\\compare\\potential_supply_curves.html')

# create bar chart with multiple series and also one or more line graphs
def seriesbarline(df, X, Y, series, lines, title, file):
    data = []
    if 'h' in df.columns:
        df = convertToInt(df, 'h')
    bars = [x for x in df['gen'].unique() if x not in lines]
    bars.reverse()
    for b in bars:  # set up bar chart data
        # print(s)
        trace = go.Bar(
            x=df[df[series] == b][X],
            y=df[df[series] == b][Y],
            name=b  # ,marker={'color':colordict[b]}
        )
        data.append(trace)
    for l in lines:
        trace_l = go.Scatter(  # data for line graph
            x=df[df[series] == l][X],
            y=df[df[series] == l][Y],
            name=l,
            line=dict(
                color=('rgb(0, 0, 0)'),
                width=1)
        )
        data.append(trace_l)
    layout = go.Layout(title=title, barmode='stack')
    fig = go.Figure(data=data, layout=layout)
    # py.offline.plot(fig,filename=file,auto_open=False)
    return py.offline.plot(fig, include_plotlyjs=False, output_type='div')


# d=seriesbarline(clean(gen_sum_h.append(dem).append(store_h),'value'),'h','value','gen',['Demand'],'Generation with Demand and Storage',path+reportdir+'generation__storage_hourly_demand.html')

# create the trace for a pie chart. useful if making subplots
def pie_trace(labels, values, domain):
    lab = [x for x in labels]
    val = [x for x in values]
    lab.reverse()
    val.reverse()
    if type(domain) is dict:
        trace = go.Pie(labels=lab, values=val, sort=False, domain=domain)  # marker={'colors':colours[:11]},
    else:
        trace = go.Pie(labels=lab, values=val, sort=False)
    return trace


# create a pie chart
def pie(labels, values, title, file):
    trace = pie_trace(labels, values, False)
    layout = go.Layout(title=title)
    figure = go.Figure(data=[trace], layout=layout)
    py.offline.plot(figure, filename=file, auto_open=False)
    figure['layout'].update(height=500)
    return py.offline.plot(figure, filename=file, output_type='div')


# d=pie(gen_sum.index,gen_sum.values,path+reportdir+'generation_pie.html')


# gen_sum=gen_sum_h.pivot_table(values='value',index='gen',aggfunc='sum')
# pie(gen_sum.index,gen_sum.values,'generation_pie.html')

# storage columns not named properly in db for some reason
def storecolfix(df):
    df.columns = ['z', 'h', 's', 'value']


# starting at time 0, count the number of periods of varying time length that have a positive mean storage output
def generationTimeFrameCount(store_h):
    count = []
    T = []
    for t in [1, 4, 12, 24, 48, 72, 168, 730]:
        store_h['t'] = pd.to_numeric(store_h.h) // t
        s = store_h.pivot_table(values='value', aggfunc='mean', index='t')
        count.append(s[s > 0].count())
        T.append(t)
    return pd.Series(data=count, index=T)


# merge storage variables to bring generation and demand into same dataframe
def mergestore(con):
    dem = get('store_demand', con)
    gen = get('store_gen', con)
    storecolfix(gen)
    storecolfix(dem)
    df = pd.merge(gen, dem, how='outer', on=['z', 'h', 's'])
    df.columns = ['z', 'h', 's', 'generation', 'demand']
    df.demand = -df.demand
    dfout = pd.melt(df, id_vars=['z', 'h', 's'], var_name='mode')
    return dfout


# mergestore(con)

# load transmission and calculate GWkm
def transload(con):
    tcap = get('var_trans_cap', con)
    tdist = get('trans_links_dist', con)
    del tcap['lo']
    del tcap['up']
    del tcap['marginal']
    trans = pd.merge(tcap, tdist, how='left',
                     on=['z', 'z_alias', 'trans']).dropna()  # dropna gets rid of duplicates (bidirectional lines)
    trans.value = trans.value * 100  # convert from 100km to km units
    trans.rename(columns={'level': 'MW', 'value': 'km'}, inplace=True)
    trans['GWkm'] = trans['MW'] * trans['km'] * 0.001
    trans['route'] = trans.z.str.cat(trans.z_alias, sep='.')
    return trans


# takes an input of a list of file locations for images, and outputs a list of html that writes those images to the screen
# used for maps, which can't be made using plotly
def image_html(images):
    width = 600
    height = 400
    im_html = ['<img src="%s" align="left" style="width:%spx;height:%spx;">' % (im, width, height) for im in images]
    return im_html


# writes the html report. graphs is a list of plotly graphs in div text format (a type of html).
# im_html is a list of html scripts that refer to image files. header is the title, htmlfile is the file output
def mkreport(graphs, im_html, header, htmlfile):
    html_string = '''
    <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
    <header>
        <h1 align="center" face="verdana"> %s </h1>
    <header>
    ''' % header + ''.join(graphs) + ''.join(im_html)

    f = open(htmlfile, 'w')
    f.write(html_string)
    f.close()
    return html_string


# reads .dd formatted input files and returns a dataframe, requires column names as input
def read_dd(cols, file):
    df = pd.read_csv(file, names=['code', 'value'], skiprows=0, sep=' ', engine='python')
    df[cols] = df['code'].apply(lambda x: pd.Series(str(x).split('.')))
    cols.append('value')
    return df[cols]


# join necessary sources to create a dataframe with "percentage fill"
# and capacity factor for each vre in each region
def vre_pct(vre_cap_r, vreCF,con):
    areas = get('area', con)
    cap2area = get('cap2area', con)
    cap2area.rename(columns={'value': 'density'}, inplace=True)
    areas = areas.pivot_table(columns=['vre', 'r'], aggfunc='sum').reset_index().rename(columns={0: 'total_area'})
    areas = areas[['vre', 'r', 'total_area']]

    vre_cap_r_pct = pd.merge(areas, vre_cap_r, on=['vre', 'r'])
    vre_cap_r_pct = vre_cap_r_pct.merge(cap2area, on='vre')
    vre_cap_r_pct['pct_installed'] = 100 * vre_cap_r_pct.value / vre_cap_r_pct[
        'total_area']  # value is the actual invested capacity (variable output)

    vreCF.rename(columns={'value': 'CF', 'vre_loadCF': 'vre'}, inplace=True)
    vreCF2 = vreCF.pivot_table(values='CF', index='r', columns='vre')
    vreCF2['Windoffshore_Mid'] = vreCF2.Windoffshore_Shallow
    vreCF2['Windoffshore_Floating'] = vreCF2.Windoffshore_Shallow
    vreCF2['r'] = vreCF2.index
    vreCF2 = pd.melt(vreCF2, id_vars=['r'])
    vreCF2.rename(columns={'value': 'CF'}, inplace=True)
    vre_cap_r_pct = pd.merge(vre_cap_r_pct, vreCF2, on=['vre', 'r'])
    return vre_cap_r_pct


def getCF(con):
    vrecapr = vre_pct(get('vre_cap_r', con), get('vre_CF_r', con))  # load resource capacity factors
    vrecapr.rename(columns={'value': 'capacity'}, inplace=True)
    vrecapr['CFweighted'] = vrecapr['CF'] * vrecapr['capacity']
    vreCF = vrecapr.pivot_table(values=['capacity', 'CFweighted'], index='vre', aggfunc='sum')
    vreCF['CF'] = vreCF['CFweighted'] / vreCF['capacity']
    return vreCF


# plot the "percentage fill" of each region on a chart against capacity factor for each vre
def pctplot(vrepct, file):
    filelocs = []
    for vre in vrepct.vre.unique():
        plt.plot(vrepct[vrepct.vre == vre].CF, vrepct[vrepct.vre == vre].pct_installed, 'o')
        plt.title(vre)
        plt.ylim([0, 100])
        plt.ylabel('Percentage fill')
        plt.xlabel('Available Capacity Factor')
        plt.savefig(file + vre + '.png')
        filelocs.append(file + vre + '.png')
        plt.close()
    return filelocs


# vrecapr=vre_pct(get('vre_cap_r',con),get('vre_CF_r',con))
# pctplot(vrecapr)

# create a trace for a bubble plot (one trace = one series)
# using col as the series identifier, ser as the series name,x,y as the plotting axes, and z as the bubble size
def bubbleplot_trace(df, col, ser, x, y, z):
    X = df[df[col] == ser][x]
    Y = df[df[col] == ser][y]
    Z = df[df[col] == ser][z]
    Z_norm = 100 * Z / Z.max()  # bubble size is normalised and adjusted to size 100, can change for visual preference
    trace = go.Scatter(
        x=X,
        y=Y,
        mode='markers',
        marker=dict(size=Z_norm, sizemode='area'))
    return trace


# t=bubbleplot_trace(vrecapr,'vre','Solar','CF','pct_installed','total_area')
# py.offline.plot([t])

def scatterTrace(df, col, ser, x, y):
    X = df[df[col] == ser][x]
    Y = df[df[col] == ser][y]
    trace = go.Scatter(x=X, y=Y, mode='markers')
    return trace


def vreRegionalCapacityLcoePlot(vrecapr, title):
    data = []
    for v in vrecapr.vre.unique():
        data.append(scatterTrace(vrecapr, 'vre', v, 'potential_lcoe(£/MWh)', 'value'))
        data[-1]['name'] = legNames[v]
        data[-1]['marker'] = {'size': 10}
    fig = go.Figure(data=data, layout=go.Layout(title=title))
    return (py.offline.plot(fig, output_type='div'))


# curtailment is calculated as the percentage of available energy not utilised
def getcurtail(con):  # must be wary of changes to model structure. how curtailment is defined
    t = get('hlast', con).astype(int)['h'][0] + 1  # number of hours in the model
    vrecaptot = get('vre_cap_tot', con).rename(columns={'value': 'capacity_MW'})  # national vre capacity
    curtailtot = get('curtail_z_h', con).rename(columns={'value': 'curtailed_MWh'})  # curtailed energy by vre
    vre_curt = pd.merge(vrecaptot, curtailtot, on='vre')
    vre_gen = get('var_vre_gen_sum_r', con).rename(columns={'value': 'generated_MWh'})  # generated energy by vre
    df = pd.merge(vre_curt, vre_gen, on='vre')
    df['resource_MWh'] = df['curtailed_MWh'] + df[
        'generated_MWh']  # available resource is the generated energy plus the curtailment
    df['curtailment_pct'] = (100 * df['curtailed_MWh'] / df['resource_MWh']).round(3)
    df['CF_generated'] = df['generated_MWh'] / (t * df['capacity_MW'])
    df['CF_resource'] = df['resource_MWh'] / (t * df['capacity_MW'])
    return df


# getcurtail(con)

# geopandas is used to create spatial plots. choose the vre to be plotted, and the column to plot
# the df has columns: r,vre,value
def vreplot(df, vre, col, color, maximum, zones, wgrid_rez,title, file):
    sns.reset_orig()
    fig, ax = plt.subplots()  # define figure
    df = df.loc[df[col] > 1]  # remove data with small values
    ax.axis('equal')
    zones.plot(ax=ax, color='white', linewidth=0.1)  # plot demand zones
    wgrid_rez.plot(ax=ax, color='white', linewidth=0.1)  # plot wind grid within renewable energy zone
    if 'r' in df.columns:  # turn r column from string to int if necessary
        df = convertToInt(df, 'r')
    # slice data to only take the vre in question, and merge data with wind grid to create spatial data
    plotdf = pd.merge(wgrid_rez, df.loc[df.vre == vre], left_on='numpy', right_on='r', how='inner')

    vmin = 0
    vmax = maximum  # upper limit of colour scale is set manually
    plotdf.fillna(0).plot(ax=ax, column=col, cmap=color, linewidth=0.3, vmin=vmin,
                          vmax=vmax)  # data is plotted using a colour map

    ax.axes.get_yaxis().set_visible(False)  # remove axes to clean up the map
    ax.axes.get_xaxis().set_visible(False)
    fig = ax.get_figure()
    cax = fig.add_axes([0.7, 0.15, 0.02, 0.65])  # define size of colour bar. (height,width,y,x)
    sm = plt.cm.ScalarMappable(cmap=color, norm=plt.Normalize(vmin=vmin, vmax=vmax))  # create the colour bar

    sm._A = []
    ax.spines['top'].set_visible(False)  # remove pins on axes
    ax.spines['bottom'].set_visible(False)
    ax.spines['left'].set_visible(False)
    ax.spines['right'].set_visible(False)

    fig.colorbar(sm, cax=cax)  # show the colour bar
    fig.suptitle(title)  # add title to map
    plt.savefig(file, dpi=800)  # save figure

    plt.close()  # close figure to save ram
    return file


# colour map based on zones rather than grid cells. can use for demand, storage, non-vre
# in this function the df input only has one series of data in it, eg: r,value
def zonemap(df, col, title, file):
    fig, ax = plt.subplots()
    ax.axis('equal')
    # wgrid_rez.plot(ax=ax,color='white',linewidth=0.1)
    if 'r' in df.columns:
        df = convertToInt(df, 'r')
    plotdf = pd.merge(wgrid.rename(columns={'numpy': 'r'}), df)

    plotdf.plot(ax=ax, column=col)
    zones.plot(ax=ax, color='white', linewidth=0.1)
    ax.spines['top'].set_visible(False)
    ax.spines['bottom'].set_visible(False)
    ax.spines['left'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.axes.get_yaxis().set_visible(False)
    ax.axes.get_xaxis().set_visible(False)

    fig.suptitle(title)
    plt.savefig(file, dpi=800)
    plt.close()


# look at wave data. note, wave data is deleted before export in normal runs
# to save space, as it is an input parameter and very large. eg, use waves_2002_test_3.db
def wavehist(wavcon):
    waves = get('waves_raw', wavcon)
    waves[waves.value > 0].value.hist(bins=100, normed=True, cumulative=True)
    return waves[waves.value > 0].value.describe(np.arange(10) / 10)


# waves df input. outputs percentiles for every region where floating turbines are installed
def wavesregional(waves, con):
    vrecapr = get('vre_cap_r', con)
    floatingr = vrecapr[vrecapr.vre == 'Windoffshore_Floating'][vrecapr.value > 1].r.tolist()
    des = pd.DataFrame()
    for R in floatingr:
        des[R] = waves[waves.value > 0][waves.r_all == R].value.describe(np.arange(100) / 100)
    return des


# produces some quality control outputs. should grow this list to more quickly see when something went wrong
# currently only checks input data
def qualitycontrol(con, directory, overwrite):
    if not os.path.exists(directory):
        os.makedirs(directory)
        print('making directory %s' % directory)
    VRE = get('vre', con).g.tolist()
    vreCF = get('vre_CF_r', con).rename(columns={'vre_loadCF': 'vre'})
    areas = get('area', con)
    for vre in VRE:
        # map of area on/off for each vre
        if overwrite or not os.path.exists('%s\\area_%s.png' % (directory, vre)):
            print('writing %s areas' % vre)
            vreplot(areas, vre, 'value', 'nipy_spectral', areas[areas.vre == vre].max()['value'], vre + ' areas',
                    '%s\\area_%s.png' % (directory, vre))
            # map of vre-CF on/off for each vre. from GAMS: vre_CF_r(vre_loadCF,r) = sum(h,vre_gen_load(vre_loadCF,r,h))/ card(h);
        if (overwrite or not os.path.exists('%s\\CF_%s.png' % (directory, vre))) and vre not in ['Windoffshore_Mid',
                                                                                                 'Windoffshore_Floating']:
            print('writing %s CF' % vre)
            vreplot(vreCF, vre, 'value', 'viridis', 1, vre + ' CF', '%s\\CF_%s.png' % (directory, vre))
        if overwrite or not os.path.exists('%s\\zones_%s.png' % (directory, vre)):
            zonemap(areas[areas.vre == vre], 'z', '%s zone definitions' % vre, '%s\\zones_%s.png' % (directory, vre))

            # %%


def plotComparisonCorrelationHeatmaps(waves, mypath, RPS, fcost, dbstring,title):
    f, axarr = plt.subplots(len(fcost), len(RPS))
    f.suptitle(title)
    #RPS = [20, 40, 60, 80, 90, 95]
    #fcost = [80, 100, 120, 140]
    fcost.reverse()
    reportdir = '\\compare\\'
    for rps in RPS:
        for fc in fcost:
            mydbstring = dbstring.replace('(waves)', str(waves)).replace('(rps)', str(rps)).replace('(fcost)', str(fc))
            connection = sq.connect(mypath + '\\' + mydbstring)
            vreGenAfterCurtail = get('var_vre_gen_sum_h', connection).pivot(columns='vre', values='value',
                                                                            index='h').round(1)
            vreGenAfterCurtail.rename(columns={'Solar': 'S', 'Windonshore': 'W',
                                               'Windoffshore_Shallow': 'WS',
                                               'Windoffshore_Mid': 'WM',
                                               'Windoffshore_Floating': 'WF'}, inplace=True)
            vregenCorr = vreGenAfterCurtail.corr()
            sns.heatmap(vregenCorr.round(2), cbar=False, annot=True, annot_kws={'size': 5},
                        ax=axarr[fcost.index(fc), RPS.index(rps)], vmin=-1, vmax=1)
            axarr[fcost.index(fc), RPS.index(rps)].set_xlabel('')
            axarr[fcost.index(fc), RPS.index(rps)].set_ylabel('')
            axarr[fcost.index(fc), RPS.index(rps)].axes.get_yaxis().set_visible(False)
            axarr[fcost.index(fc), RPS.index(rps)].axes.get_xaxis().set_visible(False)
            if RPS.index(rps) == 0:
                axarr[fcost.index(fc), RPS.index(rps)].set_ylabel(fc)
                axarr[fcost.index(fc), RPS.index(rps)].axes.get_yaxis().set_visible(True)
            if fcost.index(fc) == len(fcost) - 1:
                axarr[fcost.index(fc), RPS.index(rps)].set_xlabel(rps)
                axarr[fcost.index(fc), RPS.index(rps)].axes.get_xaxis().set_visible(True)
    if not os.path.exists(mypath + reportdir):
        os.makedirs(mypath + reportdir)
    filelocation = mypath + reportdir + 'correlations.png'
    f.savefig(filelocation, dpi=900)
    plt.close(f)
    return filelocation

# plotComparisonCorrelationHeatmaps(10000,path,'hR_m_2002_waves(waves)_RPS(rps)_fcost(fcost)_newfuelcost.db','VRE Generation National Correlation - no wave losses')
# %%
def plotComparisonCapacities(waves, mypath, dbstring, file):
    f, axarr = plt.subplots(4, 6)
    f.suptitle('VRE Capacity for wave setting %s' % waves)
    RPS = [20, 40, 60, 80, 90, 95]
    fcost = [80, 100, 120, 140]
    fcost.reverse()
    reportdir = '\\compare\\'
    for rps in RPS:
        for fc in fcost:
            mydbstring = dbstring.replace('(waves)', str(waves)).replace('(rps)', str(rps)).replace('(fcost)', str(fc))
            connection = sq.connect(mypath + '\\' + mydbstring)
            vrecap = get('vre_cap', connection)
            vrecap.replace({'Solar': 'S', 'Windonshore': 'W',
                            'Windoffshore_Shallow': 'WS',
                            'Windoffshore_Mid': 'WM',
                            'Windoffshore_Floating': 'WF'}, inplace=True)
            vrecap.set_index('vre', inplace=True)
            vrecap = vrecap / 1000
            # sns.barplot(x=vrecap.index,y=vrecap.values,ax=axarr[fcost.index(fc),RPS.index(rps)],)
            vrecap.plot.bar(ax=axarr[fcost.index(fc), RPS.index(rps)], ylim=(0, 100), legend=False,
                            color=['y', 'r', 'g', 'b', 'c'], grid=None)
            axarr[fcost.index(fc), RPS.index(rps)].set_xlabel('')
            axarr[fcost.index(fc), RPS.index(rps)].set_ylabel('')
            axarr[fcost.index(fc), RPS.index(rps)].axes.get_yaxis().set_visible(False)
            axarr[fcost.index(fc), RPS.index(rps)].axes.get_xaxis().set_visible(False)
            if RPS.index(rps) == 0:
                axarr[fcost.index(fc), RPS.index(rps)].set_ylabel(fc)
                axarr[fcost.index(fc), RPS.index(rps)].axes.get_yaxis().set_visible(True)
            if fcost.index(fc) == len(fcost) - 1:
                axarr[fcost.index(fc), RPS.index(rps)].set_xlabel(rps)
                axarr[fcost.index(fc), RPS.index(rps)].axes.get_xaxis().set_visible(True)
    if not os.path.exists(mypath + reportdir):
        os.makedirs(mypath + reportdir)
    filelocation = mypath + reportdir + '%s.png' % file
    f.savefig(filelocation, dpi=900)
    plt.close(f)
    return filelocation


# plotComparisonCapacities(10000,path6,'hR_m_2002_waves(waves)_RPS(rps)_fcost(fcost)_newfuelcost.db','capacities')
# path = r'C:\Users\Andy\Documents\Masters\Thesis\highRES\2017 results\Round 5'
# correlationFile = plotComparisonCorrelationHeatmaps(10000,path,'hR_m_2002_waves(waves)_RPS(rps)_fcost(fcost)_newfuelcost.db')

def sortByLCOE(vrecapr, RPS, demand):
    df = vrecapr[['vre', 'r', 'total_area', 'potential_generation_TWh', 'potential_lcoe(£/MWh)']]
    df.sort_values(by='potential_lcoe(£/MWh)', inplace=True)
    df['cummulative_generation'] = df['potential_generation_TWh'].cumsum()
    df.reset_index(inplace=True)
    del df['index']
    df['install_pct'] = 0
    df['install_pct'].loc[
        df.cummulative_generation * 10 ** 6 < RPS * demand * 1.04] = 100  # 1.04 comes from gen_sum.sum()/demand_tot. we are seeing 4% losses
    lastregion = 1 + df[df.install_pct == 100].index.max()
    leftover = demand_tot * 10 ** -6 - df[df.install_pct == 100].cummulative_generation.max()
    df['install_pct'].iloc[94] = 100 * leftover / df.iloc[94]['potential_generation_TWh']
    df['install_MW'] = df['install_pct'] * df['total_area']
    return df


# highRES_2017_g_wavesON90000_RPS95.db
def getSummaryData(datapath, db):
    connection = sq.connect(datapath + '\\' + db)
    scalars = get('scalars', connection)
    lcoe = scalars.iloc[6].value * 1000
    totalCost = scalars[scalars.name == 'cost_tot']['value'].sum()
    floatingCapex = get('capex_vre', connection).loc[
        get('capex_vre', connection).vre == 'Windoffshore_Floating'].value.sum()
    floatingVarom = get('variableC_vre', connection).loc[
        get('variableC_vre', connection).g == 'Windoffshore_Floating'].value.sum()
    floatingCost = floatingCapex + floatingVarom
    nonFloatingCost = totalCost - floatingCost
    floatingCostTotalPct = 100 * floatingCost / totalCost
    curtail = 100 * getcurtail(connection)['curtailed_MWh'].sum() / getcurtail(connection)['generated_MWh'].sum()
    caps = get('vre_cap_tot', connection).rename(columns={'vre': 'gen'})

    capNonVRE = get('var_non_vre_cap', connection).rename(columns={'non_vre': 'gen', 'level': 'value'})
    caps = caps.append(capNonVRE[['gen', 'value']])

    capsRatios = caps.rename(columns={'gen': 'oldname'})
    capsRatios['value'] = capsRatios['value'] / caps['value'].sum()
    capsRatios['gen'] = capsRatios['oldname'] + r'(VRE Share)'
    del capsRatios['oldname']

    store_cap = get('var_store_gen_cap', connection).rename(columns={'s': 'gen', 'level': 'value'})
    trans_bidirect = get('maxtrans_010', connection)
    trans_bidirect['gen'] = 'bidirect_' + trans_bidirect['trans']
    del trans_bidirect['trans']
    trans_cap = dropto(['trans'], transload(connection))[['trans', 'MW', 'GWkm']]
    trans_cap['trans_mw'] = trans_cap['trans'] + '_mw'
    trans_cap['trans_GWkm'] = trans_cap['trans'] + '_GWkm'
    trans_cap_mw = trans_cap[['trans_mw', 'MW']].rename(columns={'trans_mw': 'gen', 'MW': 'value'})
    trans_cap_GWkm = trans_cap[['trans_GWkm', 'GWkm']].rename(columns={'trans_GWkm': 'gen', 'GWkm': 'value'})
    caps = caps.append(store_cap[['gen', 'value']])
    caps = caps.append(trans_cap_mw)
    caps = caps.append(trans_cap_GWkm)
    caps = caps.append(trans_bidirect)
    caps = caps.append(capsRatios)
    df_sub = caps.pivot_table(columns='gen')
    df_sub['lcoe'] = lcoe
    df_sub['total_cost'] = totalCost
    df_sub['curtail'] = curtail
    df_sub['floating_cost'] = floatingCost
    df_sub['non-floating_systemcost'] = nonFloatingCost
    df_sub['floatingCostTotalPct'] = floatingCostTotalPct
    df_sub['Floating and Mid Capacity Combined'] = caps.set_index('gen').loc['Windoffshore_Mid'].value + \
                                                   caps.set_index('gen').loc['Windoffshore_Floating'].value

    runSettings = dbFileSettings(db)
    for column in runSettings.keys():
        df_sub[column] = runSettings[column]
    return df_sub


def sensitivitydata(X, Y, dbstring, datapath):
    df = pd.DataFrame()
    for x in X['data']:
        for y in Y['data']:
            db = dbstring.replace(X['fileNameReplace'], str(x)).replace(Y['fileNameReplace'], str(y))
            if os.path.exists(datapath + '\\' + db):
                df_sub = getSummaryData(db)
                df = df.append(df_sub)
            else:
                print('ERROR: database %s not found in directory %s' % (dbstring, datapath))
    return df


def heatmaptrace(df, X, Y, Z, zmin, zmax):
    df2 = df[[X['col'], Y['col'], Z]].pivot(columns=X['col'], index=Y['col'])
    trace = go.Heatmap(z=df2.values.tolist(), colorscale='OrRd',
                       x=[X['prefix'] + str(t[1]) for t in df2.columns.tolist()],
                       y=[Y['prefix'] + str(t) for t in df2.index.tolist()],
                       zmin=zmin, zmax=zmax
                       )
    return trace


def heatmapsubplots(df, X, Y, z, W, file,
                    filetype='html'):  # df is the data frame, X is the x axis dict, Y is the y axis dict, z is the values, W is the subplot differentiator
    fig = tools.make_subplots(rows=1, cols=len(df[W].unique()), shared_yaxes=True)
    zmin = df[z].min()
    zmax = df[z].max()
    i = 0
    for w in df[W].unique():
        i = i + 1
        df_sub = df.loc[df[W] == w]
        fig.append_trace(heatmaptrace(df_sub, X, Y, z, zmin, zmax), 1, i)
        fig.layout['xaxis%s' % i]['title'] = '%s%s' % (W, w)
    fig['layout'].update(title='%s' % z)
    if filetype == 'html':
        py.offline.plot(fig, filename=file, auto_open=False)
    else:
        py.offline.plot(fig, filename=file, auto_open=False, image=filetype)


def makeComparisonTable(path):
    df = pd.DataFrame()
    for db in [f for f in os.listdir(path) if '.db' in f and os.stat(path + '\\' + f).st_size > 0]:
        df_db = getSummaryData(path, db)
        df = df.append(df_db)
    return df


def plotComparisonHeatmaps(df, waves, RPS, fcost, plotValue, mainpath, filetype='html'):
    reportdir = '\\compare\\'
    if not os.path.exists(mainpath + reportdir):
        os.makedirs(mainpath + reportdir)
    w = {'data': waves, 'title': 'Wave Sensitivity', 'col': 'waves', 'prefix': 'W'}
    fc = {'data': fcost, 'title': 'Relative Floating Cost', 'col': 'fcost', 'prefix': 'C'}
    for param in [w, fc]:
        df = df.loc[df[param['col']].isin(param['data'])]
    print(df.head())

    if plotValue == 'all':
        for value in [c for c in df.columns if c not in ['RPS', w['col'], fc['col']]]:  # produce a plot for each column
            print('plotting %s' % value)
            heatmapsubplots(df, w, fc, value, 'RPS', mainpath + reportdir + '%s.html' % value, filetype)
    else:
        value = plotValue
        print('plotting %s' % value)
        heatmapsubplots(df, w, fc, value, 'RPS', mainpath + reportdir + '%s.html' % value, filetype)


def getSupplyCurves(thisfcost, allfcosts, connection):  # CF here are do not include wave losses
    vrecapr = vre_pct(get('vre_cap_r', connection), get('vre_CF_r', connection),connection)
    vrecapr = pd.merge(vrecapr, get('capex_vre_r', connection).rename(
        columns={'value': 'total_capex'}))  # add total capex column
    vrecapr['series'] = vrecapr['vre']
    vrecapr.series.replace(to_replace='Windoffshore_Floating', value='Windoffshore Floating %s' % thisfcost,
                           inplace=True)
    for fc in allfcosts:
        if fc != thisfcost:
            df_fc = vrecapr[vrecapr.series == 'Windoffshore Floating %s' % thisfcost]
            df_fc['total_capex'] = df_fc['total_capex'] * fc / thisfcost
            df_fc.series.replace(to_replace='Windoffshore Floating %s' % thisfcost,
                                 value='Windoffshore Floating %s' % fc, inplace=True)
            vrecapr = vrecapr.append(df_fc)
    vrecapr = pd.merge(vrecapr, get('generator_varom', connection).rename(columns={'g': 'vre', 'value': 'varom'}),
                       how='left').fillna(0)  # add varom /MWh column. left join because there is no solar varom
    vrecapr['potential_lcoe(£/MWh)'] = ((vrecapr.total_capex / (
    8760 * vrecapr.CF * vrecapr.value)) + vrecapr.varom) * 1000  # potential LCOE if there was no curtailment
    vrecapr = pd.merge(vrecapr, get('var_vre_gen_sum_z', connection).rename(
        columns={'value': 'actual_generation'}))  # add in actual generation (model output)
    vrecapr['actual_lcoe(£/MWh)'] = ((
                                     vrecapr.total_capex / vrecapr.actual_generation) + vrecapr.varom) * 1000  # total_capex/actual_generation gives £/MWh from capex, then add varom
    vrecapr['potential_generation'] = vrecapr.total_area * 8760 * vrecapr.CF
    demand_tot = get('demand', connection).pivot_table(values='value', index='h', aggfunc='sum').sum()
    vrecapr['potential_generation_ratio'] = vrecapr['potential_generation'] / demand_tot
    vrecapr['actual_generation_ratio'] = vrecapr['actual_generation'] / demand_tot
    vrecapr['potential_generation_TWh'] = vrecapr['potential_generation'] * 10 ** -6
    vrecapr['actual_generation_TWh'] = vrecapr['actual_generation'] * 10 ** -6
    return vrecapr


def getAndPlotSupplyCurves(db, title, filename):
    con = sq.connect(path + '\\' + db)
    VREsupply = getSupplyCurves(80, [80, 100, 120, 140], con)
    div = plotSupplyCurves(VREsupply, 'potential_generation_TWh', 'potential_lcoe(£/MWh)', 'series', title,
                           path + '\\compare\\%s.html' % filename)


def plotRPS90(comparisondata, seriesList):
    sns.reset_defaults()

    rps90 = comparisondata.loc[comparisondata.waves == 10000]
    rps90 = rps90.loc[rps90.RPS == 90]
    rps90.sort_values(by='fcost', inplace=True)
    rps90.set_index('fcost', inplace=True)

    sns.set_palette(sns.hls_palette(len(seriesList), l=0.4, s=0.9))
    rps90[seriesList].plot(marker='o', linestyle='-')
    plt.xlabel(r'Floating Cost %')
    plt.ylabel('Capacity (MW)')
    plt.gca().set_ylim(bottom=0)
    plt.legend()
    plt.title('Trends for RPS90WOFF')
    plt.show()
    plt.close()



