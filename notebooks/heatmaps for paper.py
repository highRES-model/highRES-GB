import os
import sys
topFolder = os.getcwd().split('\\').pop(-1)
moduleDirectory = os.getcwd()[:-len(topFolder)]
sys.path.append(moduleDirectory)

from reporting import *
#py.offline.init_notebook_mode(connected=True) #imports plotly.js to the notebook

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
    VRENames = {'Windoffshore_Mid': 'Mid Depth Offshore Wind Capacity','Windoffshore_Floating': 'Floating Offshore Wind Capacity'}
    title = VRENames[z]
    fig['layout'].update(title=title)
    #fig['layout']['marker']['colorbar']['title'] = 'Capacity (GW)'
    fig['layout'].update(
        annotations=[
            dict(
                x=1.13, y=1.08,  # annotation point
                xref='paper',
                yref='paper',
                text='Capacity (GW)',
                showarrow=False,
                font=dict(size=14)
            )
        ])

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


def plotComparisonHeatmaps(df, waves, RPS, fcost, plotValue, mainpath, filename, filetype='html'):
    reportdir = '\\compare\\'
    if not os.path.exists(mainpath + reportdir):
        os.makedirs(mainpath + reportdir)
    w = {'data': waves, 'title': 'Wave Sensitivity', 'col': 'waves', 'prefix': 'W'}
    fc = {'data': fcost, 'title': 'Relative Floating Cost', 'col': 'fcost', 'prefix': 'C'}
    for param in [w, fc]:
        df = df.loc[df[param['col']].isin(param['data'])]
    print(df.head())

#    if plotValue == 'all':
#        for value in [c for c in df.columns if c not in ['RPS', w['col'], fc['col']]]:  # produce a plot for each column
#            print('plotting %s' % value)
#            heatmapsubplots(df, w, fc, value, 'RPS', mainpath + reportdir + '%s.html' % value, filetype)
    #else:
    value = plotValue
    print('plotting %s' % value)
    heatmapsubplots(df, w, fc, value, 'RPS', mainpath + reportdir + '%s.html' % filename, filetype)


DATApath = r'C:\Users\ucqba01\Documents\Local Data\Round 6'
round6 = makeComparisonTable(DATApath)
#convert to GW units
round6.loc[:,'Windoffshore_Floating'] *= 0.001
round6.loc[:,'Windoffshore_Mid'] *= 0.001
round6.replace(to_replace={'waves':{10000:'OFF',400:'ON'}},inplace=True)
round6.sort_values(by=['RPS','waves'],ascending=[True,False],inplace=True)
round6


reportingPath = r'C:\Users\ucqba01\Google Drive\Extended Research\Writing\Images'

reportData = round6.loc[round6['RPS']!=95]

temp = plotComparisonHeatmaps(reportData,['ON','OFF'],[20,40,60,80,90],[80,100,120,140],'Windoffshore_Mid',reportingPath,'Windoffshore_Mid_v2')
temp = plotComparisonHeatmaps(reportData,['ON','OFF'],[20,40,60,80,90],[80,100,120,140],'Windoffshore_Floating',reportingPath,'Windoffshore_Floating_v2')

