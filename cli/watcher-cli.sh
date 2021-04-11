#!/usr/bin/bash

#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               |  For: Watcher-Soft            ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   Show graph of Watcher-Soft on term                              ****#
#*******************************************************************************************#

PROGNAME=$(basename $0)
RELEASE="Revision 1.0"
AUTHOR="(c) 2021 Aubertin Emmanuel / Twitter : @BlenderAubertin"
DEBUG=0

# Functions plugin usage
print_release() {
    echo "$RELEASE $AUTHOR"
}

print_usage() {
        echo ""
        echo "$PROGNAME"
        echo ""
        echo "Usage: $PROGNAME | [-h | --help] | [-v | --version] | [-d | --debug]"
        echo ""
        echo "          -h  Aide"
        echo "          -v  Version"
        echo "          -d  Debug"
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
        *)  echo "Argument inconnu: $1"
            print_usage
            ;;
        esac
shift
done



if [ "$(dirname ${0})" == "." ]; then
    pathexec="$(pwd)"
else
    pathexec="$(dirname ${0})/../"
fi

# Verfi si sqllite
if [ ! -x /usr/bin/sqlite3 ]; then
    echo "Ce programme nécéssite sqlite3 pour fonctionner"
    exit
fi

# Verfi rrdtools
if [ ! -x /usr/bin/rrdtool ]; then
    echo "Ce programme nécéssite rrdtool pour fonctionner"
    exit
fi

if [ "$(dirname ${0})" == "." ]; then
    db="../datas/sql/watcher.db"
else
    db="$(dirname ${0})/../datas/sql/watcher.db"
fi

count_probers="$(printf "select count(*) from probers; \n.exit \n" | sqlite3 ${db})" 

if [ $DEBUG -gt 0 ]; then echo "$count_probers probers present in database. Running them..."; fi

probers="$(printf "select id,script,options from probers; \n.exit \n" | sqlite3 ${db})"

if [ $DEBUG -gt 0 ]; then echo "Probers: $probers"; fi

if [ "$(dirname ${0})" == "." ]; then
    rra_path="../datas/rra/"
else
    rra_path="$(dirname ${0})/../datas/rra/"
fi

if [ $DEBUG -gt 0 ]; then echo "rra path = $rra_path"; fi

CURRENT_TIME="$(date +%s)"
for rra in $(ls ${rra_path}*.rrd); do
    Vertical_label="$(rrdinfo $rra | grep "^ds" | tail -1 | cut -d'.' -f1 | sed 's:^ds\[::g' | sed 's:\]::g')"
    /usr/bin/rrdtool fetch $rra MAX -r 300 -s $(($CURRENT_TIME-3600)) -e $CURRENT_TIME | grep -v nan | sed -e 's/,/./g' > ${rra_path}../dat/data-${Vertical_label}.dat
    if [ ! -z $(cat ${rra_path}../dat/data-${Vertical_label}.dat | tail -1 | cut -d':' -f1) ] #si data non vide 
    then
        gnuplot --persist <<EOF 2> /dev/null
        set terminal dumb 120 15
        set xdata time
        set timefmt "%s"
        t0=3600 
        set format x "%H:%M"
        set ytics nomirror
        plot "${rra_path}../dat/data-${Vertical_label}.dat" using 1:2 title "$( echo -e "\e[32m-- \e[1;32m${Vertical_label} \e[0;32m--\e[0m")" w linespoints
EOF

    fi
done
