#!/bin/bash

################################################################################################################
# Copyright (C) 2013 Darshit Shah
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# A small utility to login to Cyberoam Client.
# Author: Darshit Shah <darnir@gmail.com>
##################################################################################################################

# List of things todo on this script:

# TODO: Use --post-file option to send data. This adds some security since the passwords will no longer be visible
#       through ps. However, they are still sent in plaintext and canbe intercepted by any packet sniffer.
# TODO: Make PORT and PAGE variables optional.
# TODO: Convert sed statements to awk and read $3 when reading $FILE.
# TODO: Add test to check $PORT in $FILE is Numeric ONLY.


# Some Basic Variables that store location of important files. 
LOGFILE=$(echo ${HOME})/.crlog
OUTPUT=/tmp/.crout
FILE=client.conf

# Other Variables in use in this script. List all here and initialize for ease of maintenance.
ACTION=NULL
MODE=0
RETCODE=0
MESSAGE_LOGIN="You have successfully logged in"


# Server config variables, defined with default values
USERNAME=Username
PASS=Password
SERVER=Server
PORT=Port
PAGE=Page

# Function Declarations for later use in code.

error() {
    echo -n "Error: "
    case $RETCODE in
        1) echo "Something went wrong. Wget Failed.";;
        2) echo "Parse error in Wget command. Please test check command options.";;
        3) echo "File I/O Error in Wget. Please ensure that the script has R/W permissions in $HOME and /tmp";;
        4) echo 'Network Failure. Could not connect to the Server';;
        5) echo "SSL Verifification Failure. Why are you trying to use SSL anyways?";;
        6) echo "Useraname/Password Authentication Failure. If you get this message, you managed to send authentication tokens separately apart from     a POST Request. Please contact me with your patch!";;
        7) echo "Unknown Protocol Error.";;
        8) echo "Server returned an error.";;
        201) echo ${RESPONSE};;
        205) echo "Could not locate Wget on your system. Please ensure that you have Wget installed.";;
        *) echo "Unknown error. Please send your $LOGFILE to <darnir@gmail.com> for analysis";;
    esac
    rm ${OUTPUT} 2> /dev/null
    exit $RETCODE
}

# Action and Mode are two hidden fields in the Cyberoam Login page. The values in use here were pulled through packet sniffing and reading the headers. 
login_c() {
    ACTION=Login
    MODE=191
    wget --timeout=5 --tries=2 -d --post-data="username=${USERNAME}&password=${PASS}&mode=${MODE}&btnSubmit=${ACTION}" ${SERVER}:${PORT}/${PAGE} -O ${OUTPUT} -o ${LOGFILE} 2> /dev/null
    RETCODE=$?
    if [ "$RETCODE" -gt 0 ]
    then
        error
    fi
    RESPONSE=`cat ${OUTPUT} | sed 's/<message>/&\n/;s/.*\n//;s/<\/message>/\n&/;s/\n.*//'`
    if [ "$RESPONSE" == "${MESSAGE_LOGIN}" ]
    then
           echo "Logged In"
    else
        RETCODE=201
        error
    fi
}

logout_c() {
    ACTION=Logout
    MODE=193
    wget --timeout=5 --tries=2 -d --post-data="username=${USERNAME}&password=${PASS}&mode=${MODE}&btnSubmit=${ACTION}" ${SERVER}:${PORT}/${PAGE} -O ${OUTPUT} -o ${LOGFILE} 2> /dev/null
    RETCODE=$?
    if [ "$RETCODE" -gt 0 ]
    then
        error
    fi
    echo "Logged Out"
    rm ${OUTPUT} 2> /dev/null
}

input_conf() {
    echo -n "Username: "
    read USERNAME
    read -s -p "Password: " PASS
    echo                               #read -p does not add a newline
    echo -n "Server: "
    read -e -i "172.16.0.0" SERVER
    echo -n "Port: "
    read -e -i "8090" PORT
    echo -n "Page: "
    read -e -i "httpclient.html" PAGE
}

write_conf() {
    echo "USERNAME=${USERNAME}" > ${HOME}/${FILE}
    echo "PASS=${PASS}" >> ${HOME}/${FILE}
    echo "SERVER=${SERVER}" >> ${HOME}/${FILE}
    echo "PORT=${PORT}" >> ${HOME}/${FILE}
    echo "PAGE=${PAGE}" >> ${HOME}/${FILE}
}

read_conf() {
    #Assumes syntax of file is PERFECT. Does not accept comments either.
    USERNAME=`cat ${HOME}/${FILE} | sed 's/USERNAME=/&\n/;s/.*\n//;s/PASS\*/\n&/;s/\n.*//' | head -1`
    PASS=`cat ${HOME}/${FILE} | sed 's/PASS=/&\n/;s/.*\n//;s/SERVER\*/\n&/;s/\n.*//' | head -2 | tail -1`
    SERVER=`cat ${HOME}/${FILE} | sed 's/SERVER=/&\n/;s/.*\n//;s/PORT\*/\n&/;s/\n.*//' | head -3 | tail -1`
    PORT=`cat ${HOME}/${FILE} | sed 's/PORT=/&\n/;s/.*\n//;s/PAGE\*/\n&/;s/\n.*//' | tail -2 | head -1`
    PAGE=`cat ${HOME}/${FILE} | sed 's/PAGE=/&\n/;s/.*\n//;s/\*/\n&/;s/\n.*//' | tail -1`
}

###################### END OF FUNCTION DECLARATIONS ######################################################

if [ ! -f ${HOME}/${FILE} ]
then
    input_conf
    write_conf
else
    read_conf
fi

if [ ! $(which wget 2> /dev/null) ]
then
    RETCODE=205
    error
fi

if [ ! -f $OUTPUT ]
then 
    login_c

else
    logout_c
fi

exit 0
