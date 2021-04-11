#!/bin/bash

#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               |  For: Watcher-Soft            ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   HDD probe for Watcher-Soft                                      ****#
#*******************************************************************************************#

# '''
# DESCRIPTION :
#   * Watcher-Soft plugin used to return machine "HDD occupation by users".
# '''

#DEFAULT_OPTIONS=" -W 2000 -C 2500"
#La ligne si dessus permet l'option 4 du point 2 (autoconfig des sondes)

if [ "$(dirname ${0})" == "." ]; then # Handle relative path
    source ../lib/lib_probes.sh   # import all function who give User info
else
    source $(dirname ${0})/../lib/lib_probes.sh
fi

PROGNAME=$(basename $0)
RELEASE="Revision 1.0"
AUTHOR="(c) 2021 Aubertin Emmanuel / Twitter : @BlenderAubertin"

# Functions plugin usage
print_release() {
    echo "$RELEASE $AUTHOR"
}

print_usage() {
        echo ""
        echo "HDD_probe.sh"
        echo ""
        echo "Usage: HDD_probe [options] | [-h | --help] | [-v | --version]"
        echo ""
        echo "          -h  Aide"
        echo "          -v  Version"
        echo "    -W  Seuil maximum en megaoctet d'occupation d'espace"
        echo "    -C  Seuil critique en megaoctet d'occupation d'espace"
        echo ""
        echo ""
}

print_help() {
                print_usage
        echo ""
        print_release $PROGNAME $RELEASE
        echo ""
        echo ""
                exit 0
}

if [ $# -lt 4 ]; then
    print_usage
    exit $STATE_UNKNOWN
fi

while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit $STATE_OK
            ;;
        -v | --version)
                print_release
                exit $STATE_OK
                ;;
        -W | --max-warning)
               shift
               MaxWarning=$1
               ;;
        -C | --max-critical)
               shift
               MaxCritical=$1
               ;;                                     
        *)  echo "Argument inconnu: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

if [ $(id -u) -gt 0 ]; then
    echo "Ce programme nécéssite les droits root"
    exit
fi

# Verifie que les arguments sont bien fournit pas paire
if [ -n "$MaxCritical" ] || [ -n "$MaxWarning" ]; then
    if [ -z "$MaxWarning" ] || [ -z "$MaxCritical" ]; then
        print_usage
        echo ""
        echo "Il manque un argument warning ou critique."
        echo " Il est nécéssaire de spécifier au moins un couple de valeur d'alerte"
        echo "Exemple: ./HDD_probe.sh -W 10 -C 20"
        exit $STATE_UNKNOWN
    fi
fi

if [ -n "$MaxCritical" ] || [ -n "$MaxWarning" ]; then
    if [ $MaxCritical -lt $MaxWarning ]; then
        print_usage
        echo ""
        echo "La valeur maximum critique ne peut pas etre plus petite que warning."
        echo ""
        exit $STATE_UNKNOWN
    fi
fi

UserList=$(getUserList)
EXITCODE=$STATE_OK
FLAG="OK:"
OUT=""
PERFDATA=""

for user in $UserList; do
    Current_Out="$(UserDiskCheck $user)"
    if [ $Current_Out -gt 0 ]; then #Le repertoire exist, on check
        if [ $Current_Out -gt $MaxCritical ]; then
            EXITCODE=$STATE_CRITIQUE
            FLAG="CRITICAL:"
        fi
        if [ $Current_Out -gt $MaxWarning ]; then
            if [ $EXITCODE -lt 1 ]; then
                EXITCODE=$STATE_WARNING
                FLAG="WARNING:"
            fi
        fi
        if [ -n "$OUT" ]; then # Gestion de la 1ier ligne
            OUT="L'utilisateur $user consome ${Current_Out}Mo, $OUT"
        else
            OUT="L'utilisateur $user consome ${Current_Out}Mo"
        fi

        PERFDATA="$PERFDATA home_$user=$Current_Out;$MaxWarning;$MaxCritical"
    fi
done

echo "${FLAG} $OUT |$PERFDATA"
exit $EXITCODE
