#!/usr/bin/bash

#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               |  For: Watcher-Soft            ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   Orchestrator of Watcher-Soft                                    ****#
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
        echo "Ce script est compatible avec un appel via crontab."
        if [ "$(dirname ${0})" == "." ]; then # Gere l'appel avec un patch complet comme l'appel en relatif (./)
            echo "echo \"0/5 * * * * root $(pwd -P)/$(basename ${0})\" > /etc/cron.d/Watcher-Soft"
        else
            echo "echo \"0/5 * * * * root ${0}\" > /etc/cron.d/Watcher-Soft"
        fi
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
    source ../lib/lib_probes.sh   # import all function who give User info
    source ../alerters/conf/receivers.conf
    pathexec="$(pwd)"
else
    source $(dirname ${0})/../lib/lib_probes.sh
    source $(dirname ${0})/../alerters/conf/receivers.conf
    pathexec="$(dirname ${0})/../"
fi

if [ $(id -u) -gt 0 ]; then
    echo "Ce programme nécéssite les droits root"
    exit
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

# Check si l'API et le front Web sont bien demarré
if [ -z "$(ss -ntpl | grep "0.0.0.0:80" | awk '{print $1}')" ]; then
    Current_exec_path="$(pwd)"
    echo "Web front not running"
    cd $pathexec/web_service/
    /usr/bin/nohup ./index.py > ../log/index.log &
    cd $Current_exec_path # Retour au path de lancement
fi
if [ -z "$(ss -ntpl | grep "127.0.0.1:5000" | awk '{print $1}')" ]; then
    Current_exec_path="$(pwd)"
    echo "API is not running"
    cd $pathexec/web_service/
    /usr/bin/nohup ./main_api.py > ../log/api.log &
    cd $Current_exec_path # Retour au path de lancement
fi


if [ "$(dirname ${0})" == "." ]; then
    db="../datas/sql/watcher.db"
else
    db="$(dirname ${0})/../datas/sql/watcher.db"
fi

if [ ! -f $db ]; then
    echo "La database n'existe pas. Creation..."
    touch $db
    printf "CREATE TABLE probers ( id INT PRIMARY KEY, script TEXT, options TEXT, lasttime INT, laststate INT, lastoutput TEXT, lastperf TEXT); \n.exit \n" | sqlite3 ${db}
else
    echo "Loading db..."
fi

#
# Loop sur les probers afin de repondre à l'option 4 du point II
#
#
if [ "$(dirname ${0})" == "." ]; then
    prober_path="../probes/"
else
    prober_path="$(dirname ${0})/../probes/"
fi

prober_list="$(ls $prober_path)"
declare -A prober_array

for probe in $prober_list; do
    DEFAULT_OPTIONS="$(cat ${prober_path}${probe} | grep "^#DEFAULT_OPTIONS=" | cut -d'=' -f2 | sed 's:"::g')"
    prober_array+=( ["$probe"]=$DEFAULT_OPTIONS )
done

for key in ${!prober_array[@]}; do
    echo "Loading prober:${key} ${prober_array[${key}]}"
    exist_probe=0

    # Je verifie pour un faire un insert si besoin
    exist_probe="$(printf "select id from probers WHERE script=\"${key}\"; \n.exit \n" | sqlite3 ${db})"
    if [ -z $exist_probe ]; then exist_probe=0; fi

    if [ $exist_probe -gt 0 ]; then # Le prober exist
        if [ $DEBUG -gt 0 ]; then echo "Prober ($key) already exist with id ($exist_probe)"; fi
    else
        echo "New Prober detected $key. Inserting..."
        next_id="$(printf "select MAX(id+1) from probers;\n.exit\n" | sqlite3 ${db})"
        if [ "$next_id" == "" ]; then next_id=1; fi # 1er insert. :)
        printf "INSERT INTO probers VALUES ($next_id,\"$key\",\"${prober_array[${key}]}\",0,0,\"\",\"\"); \n.exit \n" | sqlite3 ${db}
    fi
done

##
## Fin de l'option 4 de la question II
##

count_probers="$(printf "select count(*) from probers; \n.exit \n" | sqlite3 ${db})" 

echo "$count_probers probers present in database. Running them..."

probers="$(printf "select id,script,options from probers; \n.exit \n" | sqlite3 ${db})"

if [ $DEBUG -gt 0 ]; then echo "Probers: $probers"; fi

if [ "$(dirname ${0})" == "." ]; then # Determine le path d'execution des probers (permet un appel dynamique)
    probe_path="../probes/"
else
    probe_path="$(dirname ${0})/../probes/"
fi

if [ "$(dirname ${0})" == "." ]; then
    rra_path="../datas/rra/"
else
    rra_path="$(dirname ${0})/../datas/rra/"
fi

if [ $DEBUG -gt 0 ]; then echo "Probe_Path = $probe_path"; fi

SAVEIFS=$IFS
IFS=$(echo -en "\n\b") # Petit tips pour gerer les espaces en restant dans le for.

for probe in $probers; do
    if [ $DEBUG -gt 0 ]; then echo "  Probe: $probe"; fi
    probe_id="$(echo $probe | cut -d'|' -f1)"
    torun="$(echo $probe | cut -d'|' -f2)"
    options="$(echo $probe | cut -d'|' -f3)"
    if [ $DEBUG -gt 0 ]; then echo "       Running ($probe_id): ${probe_path}${torun} $options"; fi
    OUT_Prober="$(bash -c "${probe_path}${torun} $options")"
    OUT_exitcode="$?"
    lastoutput="$(echo $OUT_Prober | cut -d'|' -f1)"
    perf_data="$(echo $OUT_Prober | cut -d'|' -f2)"

    if [ $DEBUG -gt 0 ]; then echo "             Output: $lastoutput"; fi
    if [ $DEBUG -gt 0 ]; then echo "             perf_data: $perf_data"; fi
    if [ $DEBUG -gt 0 ]; then echo "             Exit code: $OUT_exitcode"; fi

    CUR_DATE="$(date +%s)"
    declare -A performance_array
    for perf in $(echo $perf_data | tr ' ' '\n'); do # je converti l'espace en \n du fait du changement de IFS pour gerer les espaces dans les for.
        if [ $DEBUG -gt 0 ]; then echo "             Inserting ($perf) in perf array."; fi
        counter_key="$(echo $perf | cut -d'=' -f1)"
        counter_value="$(echo $perf | cut -d'=' -f2 | cut -d';' -f1)"
        performance_array+=( ["$counter_key"]=$counter_value )
    done

    if [ $DEBUG -gt 0 ]; then echo "             Insert in db"; fi
    printf "UPDATE probers SET lasttime=\"$CUR_DATE\",laststate=\"$OUT_exitcode\",lastoutput=\"$lastoutput\",lastperf=\"$perf_data\" WHERE id=\"$probe_id\"; \n.exit \n" | sqlite3 ${db}
    if [ $DEBUG -gt 0 ]; then echo ""; fi

    if [ $DEBUG -gt 0 ]; then echo "             Looking for RRD"; fi

    J_1=$(( $CUR_DATE - 86400))
    for key in ${!performance_array[@]}; do

        if [ ! -f ${rra_path}${torun}-${key}.rrd ]; then

            if [ $DEBUG -gt 0 ]; then echo "                       RRA (${rra_path}${torun}-${key}.rrd) is not yet existing."; fi
            if [ $DEBUG -gt 0 ]; then echo " Running creation---> rrdtool create ${rra_path}${torun}-${key}.rrd --step 300 -b $J_1 DS:${key}:GAUGE:600:U:U: RRA:MAX:0:1:288 RRA:MAX:0:7:288 RRA:MAX:0:30:288 RRA:MAX:0:360:288"; fi
            rrdtool create ${rra_path}${torun}-${key}.rrd --step 300 -b $J_1 DS:${key}:GAUGE:600:U:U: RRA:MAX:0:1:288 RRA:MAX:0:7:288 RRA:MAX:0:30:288 RRA:MAX:0:360:288

            # J'ajoute maintenant la valeur de perf
            if [ $DEBUG -gt 0 ]; then echo "rrdtool update ${rra_path}${torun}.rrd ${CUR_DATE}:${performance_array[${key}]}"; fi
            rrdtool update ${rra_path}${torun}-${key}.rrd ${CUR_DATE}:${performance_array[${key}]}
        else

            if [ $DEBUG -gt 0 ]; then echo "                       RRA (${rra_path}${torun}-${key}.rra) exist."; fi
            if [ $DEBUG -gt 0 ]; then echo "                       Adding perfdata:${key} ${performance_array[${key}]}"; fi
            if [ $DEBUG -gt 0 ]; then echo " Running update---> rrdtool update ${rra_path}${torun}-${key}.rrd ${CUR_DATE}:${performance_array[${key}]}"; fi
            rrdtool update ${rra_path}${torun}-${key}.rrd ${CUR_DATE}:${performance_array[${key}]}  

        fi

    # Section de code qui genere les PNG pour le front Web.

    # Determine la data-source
    CURRENT_TIME="$(date +%s)"
    Vertical_label="$(rrdinfo ${rra_path}${torun}-${key}.rrd | grep "^ds" | tail -1 | cut -d'.' -f1 | sed 's:^ds\[::g' | sed 's:\]::g')"
    /usr/bin/rrdtool fetch ${rra_path}${torun}-${key}.rrd MAX -r 300 -s $(($CURRENT_TIME-3600)) -e $CURRENT_TIME | grep -v nan | sed -e 's/,/./g' > ${rra_path}../dat/data-${Vertical_label}.dat
  
    Line_Labal="$(echo $Vertical_label | tr '_' ' ' | sed -e "s/\b\(.\)/\u\1/g")"

    rrdtool graph ${rra_path}../png/latest-${torun}-${key}.png \
    -w 785 -h 120 -a PNG \
    --slope-mode \
    --start -3600 --end now \
    --vertical-label "$Vertical_label" \
    DEF:${Vertical_label}=${rra_path}${torun}-${key}.rrd:${Vertical_label}:MAX \
    LINE1:${Vertical_label}#ff0000:"$Line_Label"

    done

    if [ "$(dirname ${0})" == "." ]; then
        rra_path="../datas/rra/"
    else
        rra_path="$(dirname ${0})/../datas/rra/"
    fi
    if [ "$(dirname ${0})" == "." ]; then
        PATH_TO_MAIL="./../alerters"
    else
        PATH_TO_MAIL="$(dirname ${0})/../alerters"
    fi

    # Section de code qui gere les alertes si les seuils sont dépassés
    if [ $OUT_exitcode -gt 0 ]; then 
        if [ -z "$BCC" ]
        then 
            if [ $DEBUG -gt 0 ]; then echo -e "\nbash -x ./../alerters/MAIL_alerters.sh -M $RECEIVER -P $torun -S $OUT_exitcode -O \"$lastoutput\"\n"; fi
            $PATH_TO_MAIL/MAIL_alerters.sh -M $RECEIVER -P $torun -S $OUT_exitcode -O "$lastoutput" 
        else 
            if [ $DEBUG -gt 0 ]; then echo -e "\nbash -x ./../alerters/MAIL_alerters.sh -M $RECEIVER -B $BCC -P $torun -S $OUT_exitcode -O \"$lastoutput\"\n"; fi
            $PATH_TO_MAIL/MAIL_alerters.sh -M $RECEIVER -P $torun -B $BCC -S $OUT_exitcode -O "$lastoutput"
        fi   #Mail alerters
    fi

    if [ $DEBUG -gt 0 ]; then echo ""; fi
    unset performance_array # Vide le tableau pour laisser la place aux prochain compteur.

done
IFS=$SAVEIFS # Restauration du separateur d'origine.

