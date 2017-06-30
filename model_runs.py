"""
modify this script to run the model
"""
import os
import datetime
import time
import pandas as pd

def sleep(seconds):
    time.sleep(seconds)
    print("slept for %s seconds" % seconds)

# looks at the log file for the phrase "optimal solution found"
def checkLog(log):
    i = False
    print('Checking log: %s' % log)
    if os.path.exists(log):
        with open(log) as search:
            for line in search:
                line = line.rstrip()  # remove '\n' at end of line
                if 'Optimal solution found.' == line:
                    i = True
        if i:
            outlog = 'Optimal solution found'
        else:
            outlog = 'error - Check log file'
    else:
        outlog = 'Log file not found!'
    return outlog

# returns the solver message eg. "Optimal solution found"
def getLogResult(log):
    if os.path.exists(log):
        with open(log, 'r') as logFile:
            logLines = logFile.readlines()
            line = next((l for l in logLines if l.startswith('Cplex Time:')), None)
    if line is not None:
        return logLines[2 + logLines.index(line)].strip()
    else:
        return 'logfile incomplete'

# reads all logs in a given path and outputs a dataframe with their names and the result
def getAllLogs(logname, path):
    logs = [f for f in os.listdir(path) if logname in f]
    df = pd.DataFrame(index=logs, columns=['cplex_result'])
    for log in logs:
        df.loc[log]['cplex_result'] = getLogResult(path + '\\' + log)
    return df

# converts gdx files into sqlite databases
def gdx2sqlite(gamsfile):
    # gams file: "gdx2sqlite -i hR_l_2002_wavesOFF0_RPS99_fcost100_A.gdx -o sizetest_fast_small.db -fast -small"
    path = 'RND5/'
    infiles = [f[:-4] for f in os.listdir(path) if 'gdx' in f]
    for gdx in infiles:
        cmd = "C:\GAMS\win64\\24.7\gams.exe %s --fileName=%s" % (gamsfile,path + gdx)
        print(cmd)
        os.system('start /wait ' + cmd)

# loop to run multiple scenarios
if False:
    RPS = [95]
    WTOL = ['OFF', 400]
    fcost = [85, 100, 115, 130]

    year = 2002
    version = 'highRES_2017_m'
    lognum = 'RND5'
    CMD = {} #pairs logfiles with the commands that correspond to that run
    r = 0
    total = len(RPS) * len(WTOL) * len(fcost)
    print('total runs: %s' % total)

    for f in fcost:
        for wtol in WTOL:
            if type(wtol) is int:
                waves = 'ON'
                w_tol = wtol
            else:
                waves = 'OFF'
                w_tol = 10000
            for rps in RPS:
                r = r + 1
                nowtime = datetime.datetime.now().time().isoformat()
                print('\nstarting run %s at %s' % (r, nowtime))
                logname = "%s_%s_%sfc%swtol%s%sRPS%s" % (version, year, lognum, f, waves, w_tol, rps)
                cmd = "C:\GAMS\win64\\24.7\gams.exe %s lo 4 Lf=%s --fcost=%i --wave_tol=%i --RPS_val=%i --waves=%s" % (
                version, logname, f, w_tol, rps, waves)
                print(cmd)
                CMD[logname] = cmd
                ##    the function os.system runs the command through the windows terminal
                os.system('start /wait ' + cmd)
                print(checkLog(logname))





