import sqlite3 as sq
import pandas as pd
import os
from reporting import *
import shutil

def getMemoryUsage(tableList,con):
    dataUsage = {}
    for t in tableList:
        dataUsage[t] = get(t,con).memory_usage().sum()
#getMemoryUsage(tableUnique['common'],connections[0])

def makeDirectory(mainPath,mergePath):
    if not os.path.exists(mainPath+mergePath):
        os.makedirs(mainPath+mergePath)

def replaceString(myString, dict):
    for k in dict.keys():
        myString = myString.replace(k, dict[k])
    return myString

#make a scenarios settings table in a database with columns scenario/identifier/value
def makeScenariosTable(connection):
    cursor = connection.cursor()
    cursor.execute("""CREATE TABLE 
                        IF NOT EXISTS scenarios (
                        scenario string NOT NULL,
                        identifier string NOT NULL,
                        value string NOT NULL
                        );""")

#scenarios table in sqlite database
def writeToScenarioTable(connection,scenarioDatabasefile):
    scenarioSettings = dbFileSettings(scenarioDatabasefile)
    for id in scenarioSettings.keys():
        cursor.execute("INSERT INTO scenarios (scenario,identifier,value) VALUES ('%s','%s','%s');"%(scen,id,scenarioSettings[id]))



mainPath   = r'C:\Users\ucqba01\Documents\Local Data\testing databases/'
mergePath = r'\merged'
databases = [f for f in os.listdir(mainPath) if f[-3:] == '.db']
connections = [sq.connect(mainPath+db) for db in databases]
print(databases)

tables = getList(connections[0])
print(tables)

#this loop is very slow
tableUnique = {'common':[],'specific':[]}
for t in tables:
    tableData0 = get(t,connections[0])
    tableData1 = get(t,connections[1])
    if tableData0.equals(tableData1):
        tableUnique['common'].append(t)
    else:
        tableUnique['specific'].append(t)

print('common tables',len(tableUnique['common']))
print('specific tables',len(tableUnique['specific']))

makeDirectory(mainPath,mergePath)
mergeDataBaseFile = '/merge5.db'

shutil.copy(mainPath+'/'+databases[0],mainPath+mergePath+mergeDataBaseFile)
mergeCon = sq.connect(mainPath+mergePath+mergeDataBaseFile)

makeScenariosTable(mergeCon)

#make a dict of scenario names for each database in the list
scenarioNames = {}
for db in databases:
    scenarioNames[db] = replaceString(db,{'hR_m_2002_waves':'w','_newfuelcost.db':''})

for t in tableUnique['specific']:
    scen=scenarioNames[databases[0]]
    colCursor = mergeCon.execute('select * from %s'%t)
    cursor = mergeCon.cursor()
    if 'scenario' not in [col[0] for col in colCursor.description]:
        cursor.execute("ALTER TABLE %s ADD COLUMN scenario string;"%t)
        print('adding scenario column to %s'%t)
    cursor.execute("UPDATE %s SET scenario='%s'" %(t,scen))

writeToScenarioTable(mergeCon,databases[0])

for db in databases:
    if db != databases[0]:
        cursor.execute("ATTACH DATABASE \"%s\" AS %s;"%(mainPath+'\\'+db,'toAppend'))

def removeCommonTables(connection)
    for t in tableUnique['common']:
        cursor = connection.cursor()
        cursor.execute("DROP TABLE %s;" %t)
    cursor.execute("VACUUM")
