#!/bin/bash

#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               | For: RasPiMusic               ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   Easy instalation of RasPiMusic                                  ****#
#*******************************************************************************************#

PROGNAME=$(basename $0)
RELEASE="Revision 1.0"
AUTHOR="(c) 2021 Aubertin Emmanuel / Twitter : @BlenderAubertin"
DEBUG=0
CRON_TIME=1
# Functions plugin usage
print_release() {
    echo "$RELEASE $AUTHOR"
}

print_usage() {
        echo ""
        echo "$PROGNAME"
        echo ""
        echo "Usage: $PROGNAME | [-h | --help] | [-v | --version] | [-d | --debug] | [-t | --time]"
        echo ""
        echo "          -h  Aide"
        echo "          -v  Version"
        echo "          -d  Debug"
        echo "          -t  Cron minute (see https://doc.ubuntu-fr.org/cron)"
        echo ""
}

print_help() {
        print_release $PROGNAME $RELEASE
        echo ""
        print_usage
        echo ""
        echo ""
                exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit 
            ;;
        -v | --version)
                print_release
                exit 
                ;;
        -d | --debug)
                DEBUG=1
                ;;
        -t | --time)
                CRON_TIME=$1
                ;;
        *)  echo "Argument inconnu: $1"
            print_usage
            ;;
        esac
shift
done

if [ $UID -ne 0 ]; then
    echo -e "\e[1;31mError :\e[22m To install RasPiMusic you need root privileges\e[0m"
    exit 1
fi

function ask_yes_or_no() {
    echo -n "[yes/no] : "
    read -r YESNO
    if [[ $YESNO =~ [yY] ]]; then
        return 0
    fi
    return 1
}

if [ $# - ]
#Install python3 and lib
echo -e "\e[32m--------| \e[1;32mINSTALATION OF DEPENDENCIES\e[32m |--------\e[0m"
apt install -y python3-pip rrdtool sqlite3 git gnuplot

echo -e "\e[32m--------| \e[1;32mPYTHON3 LIB\e[32m |--------\e[0m"
pip3 install Flask Flask-Assets Flask-Cors Flask-Mail pandas psutil

## GIT CLONE
echo -e "\e[32m--------| \e[1;32mGIT CLONE\e[32m |--------\e[0m"
git clone https://github.com/Athomisos/Watcher-soft.git


echo -e "\e[32m--------| \e[1;32mADD ORCHESTRATOR TO CRON.D\e[32m |--------\e[0m"
echo "$CRON_TIME * * * * root $(pwd -P)/orchestrator/Watcher-Soft.sh" > /etc/cron.d/Watcher-Soft
