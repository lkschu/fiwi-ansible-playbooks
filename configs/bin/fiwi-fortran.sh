#!/bin/bash

# Author: Lukas K. schumann
# Mail: lukas_kilian.schumann@stud-mail.uni-wuerzburg.de

# Newest Version always available at https://10.106.242.102




# should normally point to fiwi-coordinator: 10.106.242.102
IPADDRESS="10.106.242.102"
# your user account, i.e. lkschu
REMOTEUSER="test02"

NODEBUG="gfortran-8 -O3"
DEBUG="gfortran-8 -g -Og"
DETACH=true
GPU=false







# get 'actual' working directory, not home, when run interacively on macos
cd -- "$(dirname "$0")"

###### Handle command arguments

if [[ "$1" == "--install" ]]; then
    scp ~/.ssh/id_rsa.pub $REMOTEUSER@$IPADDRESS:id_rsa.pub && \
    ssh $REMOTEUSER@$IPADDRESS "cat id_rsa.pub >> .ssh/authorized_keys && rm id_rsa.pub" && \
    exit 0
    echo "Installing ssh keys failed, please check internet and vpn status or contact the administrator."
    exit 1
fi

if [[ "$1" == "--ls" ]]; then
    # list all directories in archive
    echo "Listing archive:"
    ssh $REMOTEUSER@$IPADDRESS "ls archive"
    exit 0
fi

if [[ "$1" == "--get" ]]; then
    # Copy folder from ~/archive to working directory
    # Regex test for $2
    if [[ "$2" =~ ^[-_0-9]{19}$ ]]; then
        echo "Getting $2 from archive."
        scp -r $REMOTEUSER@$IPADDRESS:archive/$2 .
        exit 0
    else
        echo "ERROR"
        echo "Usage: fiwi-fortran.sh --get 2022-03-09_12-51-00"
        exit 0
    fi
fi

if [[ "$1" == "--kill" ]]; then
    # kill remote tmux session
    echo "Trying to kill $2."
    ssh $REMOTEUSER@$IPADDRESS "delegate-build --kill --ts=$2"
    exit 0
fi







###### Normal execution


# save pid to kill this script reliably from functions
trap "exit 1" TERM
export TOP_PID=$$

## config setup
# timestamp without '.' or ':' so it can be used as tmux name
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
echo "Please specify <main>.f90:"
select mainfile in ./*.f90
do
    if [ -f "$mainfile" ]; then
        mainfile="${mainfile:2}"
        echo "Picked $mainfile."
        break
    else
        echo "Invalid choice!"
    fi
done

error() {
    echo -
    echo Something went wrong! Is the vpn running?
    echo -
    ##cleanup
    rm source.tar.gz
    rm config.cfg
    read -r -n 1 -s -p "Press any key to close this window..."
    kill -s TERM $TOP_PID
}



echo "--------------------------------"
echo "main=\"$mainfile\"" > config.cfg # main program's name
while true; do
    read -p "Enable debug flags? Gives traceback but can increase runtime.(y/n) " yn
    case $yn in
        [Yy]* ) echo "compiler=\"$DEBUG\"" >> config.cfg; echo""; break;; # choose compiler
        [Nn]* ) echo "compiler=\"$NODEBUG\"" >> config.cfg; echo""; break;; # choose compiler
        * ) echo "Please answer (y)es or (n)o.";;
    esac
done

# Local or detach?
while true; do
    read -p "Detach execution to run in background?(y/n) " yn
    case $yn in
        [Yy]* )
            DETACH=true; echo""; break;;
        [Nn]* )
            DETACH=false; echo""; break;;
        * )
            echo "Please answer (y)es or (n)o.";;
    esac
done

echo "timestamp=\"$timestamp\"" >> config.cfg # timestamp to create temporary directory

# send source and config for compiler
tar -czf source.tar.gz *.f90 config.cfg

# create directory on the server
ssh $REMOTEUSER@$IPADDRESS "mkdir web_html/data/$timestamp" || error

# send over source and config
echo "Sending files to target."
scp ./source.tar.gz $REMOTEUSER@$IPADDRESS:"web_html/data/$timestamp"\
&& echo "Done." || error
echo "--------------------------------"

# local garbage collection
rm source.tar.gz; rm config.cfg

# execute the code on the server
if [ "$DETACH" = true ]; then
    ssh $REMOTEUSER@$IPADDRESS "delegate-build --ts=$timestamp"\
    && echo "Check the website https://$IPADDRESS/~$REMOTEUSER for progress."\
    && echo "Program ID is $timestamp."\
    && read -r -n 1 -s -p "Press any key to close this window..."\
    && echo "" \
    || error
else
    ssh $REMOTEUSER@$IPADDRESS "delegate-build --local --ts=$timestamp"\
    && scp -r $REMOTEUSER@$IPADDRESS:web_html/data/$timestamp/ . \
    && read -r -n 1 -s -p "Press any key to close this window..."\
    && echo "" \
    || error
fi


