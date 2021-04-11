#!/bin/bash

#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               | For: Watcher-Soft             ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   Get all user of the server                                      ****#
#*******************************************************************************************#


# '''
# DESCRIPTION :
#   * Watcher-Soft plugin de surveillance du nombre d'utilisateur connecté".
# '''

#DEFAULT_OPTIONS=" -W 2 -C 15"
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
        echo "USER_probe.sh"
        echo ""
        echo "Usage: USER_probe.sh [options] | [-h | --help] | [-v | --version]"
        echo ""
        echo "          -h  Aide"
        echo "          -v  Version"
        echo "    -w  Nombre minimal d'utilisateurs connectes"
        echo "    -W  Nombre maximal d'utilisateurs connectes"
        echo "    -c  Nombre minimal critique d'utilisateurs connectes"
        echo "    -C  Nombre maximal critique d'utilisateurs connectes"
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
        -w | --min-warning)
                shift
                MinWarning=$1
                ;;
        -c | --min-critical)
               shift
               MinCritical=$1
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
        echo "Exemple: ./getUser.sh -W 10 -C 20"
        exit $STATE_UNKNOWN
    fi
fi

if [ -n "$MinCritical" ] || [ -n "$MinWarning" ]; then
    if [ -z "$MinWarning" ] || [ -z "$MinCritical" ]; then
        print_usage
        echo ""
        echo "Il manque un argument warning ou critique."
        echo " Il est nécéssaire de spécifier au moins un couple de valeur d'alerte"
        echo "Exemple: ./getUser.sh -w 5 -c 2"
        exit $STATE_UNKNOWN
    fi
fi

# Verifie la qualité des valeurs de seuil
if [ -n "$MinCritical" ] || [ -n "$MinWarning" ]; then
    if [ $MinCritical -gt $MinWarning ]; then
        print_usage
        echo ""
        echo "La valeur minimum critique ne peut pas etre plus grande que warning."
        echo ""
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

UserList=$(getConnectedUserList)
UserCount=$(getConnectedUserCount)

if [ -n "$MaxCritical" ]; then
    if [ $UserCount -gt $MaxCritical ]; then
         echo "CRITIQUE: Trop d'utilisateurs connectes: $UserList | nbr_user=$UserCount;$MaxWarning;$MaxCritical;$MinWarning;$MinCritical"
         exit $STATE_CRITIQUE
    fi
    if [ $UserCount -gt $MaxWarning ]; then
         echo "WARNING: Trop d'utilisateurs connectes: $UserList | nbr_user=$UserCount;$MaxWarning;$MaxCritical;$MinWarning;$MinCritical"
         exit $STATE_WARNING
    fi
fi

if [ -n "$MinCritical" ]; then
    if [ $UserCount -lt $MinCritical ]; then
         echo "CRITIQUE: Trop peu d'utilisateurs connectes. Liste ($UserList) | nbr_user=$UserCount;$MaxWarning;$MaxCritical;$MinWarning;$MinCritical"
         exit $STATE_CRITIQUE
    fi
    if [ $UserCount -lt $MinWarning ]; then
         echo "WARNING: Trop peu d'utilisateurs connectes. Liste ($UserList) | nbr_user=$UserCount;$MaxWarning;$MaxCritical;$MinWarning;$MinCritical"
         exit $STATE_WARNING
    fi
fi

echo "OK: Utilisateurs connectes: $UserList | nbr_user=$UserCount;$MaxWarning;$MaxCritical;$MinWarning;$MinCritical"
