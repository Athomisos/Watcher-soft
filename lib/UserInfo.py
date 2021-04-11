# -*- coding: utf-8 -*-
#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               |  For: Watcher-Soft            ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   User probe for Watcher-Soft                                      ****#
#*******************************************************************************************#


'''
DESCRIPTION :
  * Watcher-Soft user info python class.
'''

import os, sys, psutil          # Basic du TP. Necessite apt-get install python3-psutil
import pandas as pd             # Ajoute Panda pour faciliter la manipulation des données


def GetProcessesInformation(user):
    proc_dict_list = []
    for process in psutil.process_iter():
        with process.oneshot():
            utilisateur = process.username() # Recupere l'utilisateur du process
            if utilisateur == user:
                pid = process.pid # Recupere le PID
                val_cpu = [] # Recupere le % usage CPU du process et c'est tout une affaire avec Python :-(
                for i in range(5):
                    p = psutil.Process(process.pid)
                    p_cpu = p.cpu_percent(interval=0.1)
                    val_cpu.append(p_cpu)
                    CPU_Usage = float(sum(val_cpu))/len(val_cpu) #Moyenne sur 0,5 sec (5 x 0.1)

                MEM_Usage = process.memory_full_info().uss # Recupere l'utilisation mémoire du process
                proc_dict_list.append({ 'utilisateur': utilisateur, 'pid': pid, 'CPU_Usage': CPU_Usage, 'MEM_Usage': MEM_Usage })
    return proc_dict_list

def ProcessusDataframe(processus):
    DataFrame = pd.DataFrame(processus, columns = ['utilisateur', 'pid', 'CPU_Usage', 'MEM_Usage'])
    DataFrame.sort_values(by=['utilisateur'], ascending=False, inplace=True, na_position='first')
    return DataFrame

def UsersDataframe(psusers):
    DataFrame = pd.DataFrame(psusers, columns = ['name', 'terminal', 'host', 'started', 'pid'])
    DataFrame.sort_values(by=['name'], ascending=False, inplace=True, na_position='first')
    return DataFrame
