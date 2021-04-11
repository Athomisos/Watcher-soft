#!/bin/bash

#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               | For: Watcher-Soft             ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   Mail alerters of Watcher-Soft                                   ****#
#*******************************************************************************************#


# '''
# DESCRIPTION :
#   * Watcher-Soft mail alerters".
# '''


PROGNAME=$(basename $0)
RELEASE="Revision 1.0"
AUTHOR="(c) 2021 Aubertin Emmanuel / Twitter : @BlenderAubertin"

# Functions plugin usage
print_release() {
    echo "$RELEASE $AUTHOR"
}

print_usage() {
        echo ""
        echo "$PROGNAME"
        echo ""
        echo "Usage: $PROGNAME [options] | [-h | --help] | [-v | --version] | [-M] | [-B] | [-P] | [-S] | [-O]"
        echo ""
        echo "          -h  Aide"
        echo "          -v  Version"
        echo "          -M  Liste de mail en destinataire separe par des virgules"
        echo "          -B  Liste de mail en copie caché separe par des virgules"
        echo "          -P  Nom de la probe"
        echo "          -S  Etat de la probe"
        echo "          -O  Sortit de la probe"
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
        -M)
                shift
                Receivers=$1
                ;;
        -B)
               shift
               HideReceivers=$1
               ;;
        -P)
                shift
                ProbeName=$1
                ;;         
        -S)
                shift
                StateProbe=$1
                ;;  
        -O)
                shift
                ProbeOutput=$1
                ;; 

        *)  echo "Argument inconnu: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

if [ "$(dirname ${0})" == "." ]; then
    DIR_TEMPLATE=templates/mail.txt
else
    DIR_TEMPLATE=$(dirname ${0})/templates/mail.txt
fi

if [ $(id -u) -gt 0 ]; then
    echo "Ce programme nécéssite les droits root"
    exit
fi

if [[ -z "$ProbeName" ]] || [[ -z "$Receivers" ]] || [[ -z "$ProbeOutput" ]] || [[ -z "$StateProbe" ]]
then 
    print_usage
    exit 2
fi

if [ "$StateProbe" == "2" ]
then
    StateProbe="CRITICAL"
else
    StateProbe="WARNING"
fi

curl -s --location --request POST 'localhost:5000/mail' \
--header 'Content-Type: application/json' \
--data-raw "{
    \"title\": \"$StateProbe $ProbeName\",
    \"body\": \"$(cat $DIR_TEMPLATE | sed "s;||sonde||;$ProbeName;g" | sed "s;||state||;$StateProbe;g")\n$ProbeOutput\",
    \"bcc\": [\"$HideReceivers\"],
    \"MAIL_REPORT\": \"$Receivers\"
}"