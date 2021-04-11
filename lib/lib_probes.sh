#!/bin/bash

#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               | For: Watcher-Soft             ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   All use full function                                           ****#
#*******************************************************************************************#

if [ "$(dirname ${0})" == "." ]; then
    source ../includes/config.sh    # Get all global variable
else
    source $(dirname ${0})/../includes/config.sh
fi

    
############################
### Get all user connected
getOnlineUser() { 
    echo $(who | cut -d' ' -f1 | sort | uniq)
    }

############################
### Get list of all user
getUser() {
    echo $(cat /etc/passwd | awk -F: '$3 >= 1000 { print $1}')
}

getConnectedUserList() { 
    echo $(who | cut -d' ' -f1 | sort | uniq)
    }

############################
### Get user connected
getConnectedUserCount() { 
    echo $(who | awk '{print $1}' | sort -u |  wc -l)
    }

############################
### Get User Home directory
getUserList() { 
    echo $(cat /etc/passwd| cut -d':' -f1,7 | grep -v "/nologin$" | grep -v "/false$" | grep -v "/sync$" | cut -d':' -f1 | tr "\n" " ")
    }

############################
### Get User Home directory
getUserHomeDir() { 
    if [ $# -eq 1 ] ; then
        echo $(cat /etc/passwd| cut -d':' -f1,6,7 | grep -v "/nologin$" | grep -v "/false$" | grep -v "/sync$" | grep $1 | cut -d':' -f2 | tr "\n" " ")
    else
        echo "-1"
    fi
    }

############################
### Get disk utilisation of one user
UserDiskCheck(){ 
    if [ $# -eq 1 ]
    then
        UserHomeDir="$(getUserHomeDir $1)"
        if [ -d $UserHomeDir ]; then
            echo $(du -ms $UserHomeDir | awk '{print $1}') #Return in Mo
        else
            echo "-1"
        fi
    else
        echo "-1"
    fi
}
