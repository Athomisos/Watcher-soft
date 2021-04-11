#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               |  For: Watcher-Soft            ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   CPU probe for Watcher-Soft                                      ****#
#*******************************************************************************************#

'''
DESCRIPTION :
  * Watcher-Soft plugin used to return machine "CPU (Total, User, System)".
'''

#DEFAULT_OPTIONS="-w 85 -c 90"
#La ligne si dessus permet l'option 4 du point 2 (autoconfig des sondes)

__author__ = "Aubertin Emmanuel"
__copyright__ = "2021, CERI"
__credits__ = ["Aubertin Emmanuel"]
__license__ = "GPL"
__version__ = "1.0.0"

import os, psutil                   # Basic du TP. Necessite apt-get install python3-psutil
import sys, argparse, json          # Ajoute les fonctions necéssaire pour le parsing de la ligne de commande et la "presentation JSON" 
import pandas as pd                 # Ajoute Panda pour faciliter la manipulation des données

sys.path=[sys.path[0]+"/../lib/"]   # Ajoute le chemin de class custom
from UserInfo import *              # Charge la class et les fonctions


if __name__ == '__main__':

    if os.geteuid() != 0:
        print ("Seul root peut executer cette sonde.")
        sys.exit(1)

    parser = argparse.ArgumentParser(description="""
        Check and return CPU usage per connected user.
        """,
        usage="""
            CPU_probe.py -w 85 -c 90 -v
        """,
        epilog="version {}, license {}, copyright {}, credits {}".format(__version__,__license__,__copyright__,__credits__))
    parser.add_argument('-w', '--warning', type=int, nargs='?', help='warning trigger', default=85)
    parser.add_argument('-c', '--critical', type=int, nargs='?', help='critical trigger', default=90)
    parser.add_argument('-v', '--verbose', help='be verbose', action='store_true')

    args = parser.parse_args()
    
    ListCurrentConnectedUsers = psutil.users() 
    DataFrameUsers = UsersDataframe(psutil.users())

    SeriesUsers = DataFrameUsers['name'].squeeze() # Converti la colone utilisateur du DataFrame en Series
    ListCurrentUsers = pd.unique(SeriesUsers) # Extrait une list unique

    Users = []
    Global_State = 0
    Out = str()
    Perf = str()
    
    PosList = 0
    for CurrentUser in ListCurrentUsers:
        state = 0
        processus = GetProcessesInformation(CurrentUser)
        DataFrameProc = ProcessusDataframe(processus) # Tri les informations systeme
        #print(DataFrameProc)
        CurrentDataFrame = DataFrameProc.query('utilisateur == "' + CurrentUser +'"')
        CurrentDataFrame = CurrentDataFrame.round(1) # Arrondi les valeurs
        cpu_percent = CurrentDataFrame.agg({'CPU_Usage' : ['sum']}).values[0]
        #memory_consom = CurrentDataFrame.agg({'MEM_Usage' : ['sum']}).values[0]

        if cpu_percent[0] >= args.critical:
            Global_State = 2
        if Global_State == 0: 
            if cpu_percent[0] >= args.warning:
                Global_State = 1
        cpu_usage = cpu_percent[0]/os.cpu_count()
        if PosList == 0:
            Out += "L'utilisateur " + CurrentUser + " consomme " + str(cpu_usage) + "% de cpu "
            Perf += "| " + CurrentUser + "_cpu=" + str(cpu_usage) + ";" + str(args.warning) + ";" + str(args.critical) + "; " 
        else:
            Out += ", L'utilisateur " + CurrentUser + " consomme " + str(cpu_percent[0]) + "% de cpu"
            Perf += CurrentUser + "_cpu=" + str(cpu_usage) + ";" + str(cpu_usage) + ";" + str(args.critical) + "; " 

        PosList += 1

    if Global_State == 2:
        print("CRITICAL:",Out,Perf,"\n")
    if Global_State == 1:
        print("WARNING:",Out,Perf,"\n")
    if Global_State == 0:
        print("OK:",Out,Perf,"\n")

    sys.exit(Global_State)