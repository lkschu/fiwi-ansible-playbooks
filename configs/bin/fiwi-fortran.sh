#!/bin/bash
# Author: Lukas K. Schumann
# Mail:   lukas_kilian.schumann@stud-mail.uni-wuerzburg.de

# Newest Version available at https://10.106.242.102





# should normally point to fiwi-coordinator: 10.106.242.102
IPADDRESS="10.106.242.102"
# your user account, i.e. lkschu
REMOTEHOST="test02"

NODEBUG="gfortran-8 -O3"
DEBUG="gfortran-8 -g -Og"
DETACH=true
GPU=false







# get 'actual' working directory, not home, when run interacively on macos
cd -- "$(dirname "$0")"

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
ssh $REMOTEHOST@$IPADDRESS "mkdir web_html/data/$timestamp" || error

# send over source and config
echo "Sending files to target."
scp ./source.tar.gz $REMOTEHOST@$IPADDRESS:"web_html/data/$timestamp"\
&& echo "Done." || error
echo "--------------------------------"

# local garbage collection
rm source.tar.gz; rm config.cfg

# execute the code on the server
if [ "$DETACH" = true ]; then
    ssh $REMOTEHOST@$IPADDRESS "delegate-build --ts=$timestamp"\
    && echo "Check the website https://$IPADDRESS/~$REMOTEHOST for progress."\
    && echo "Program ID is $timestamp."\
    && read -r -n 1 -s -p "Press any key to close this window..."\
    && echo "" \
    || error
else
    ssh $REMOTEHOST@$IPADDRESS "delegate-build --local --ts=$timestamp"\
    && read -r -n 1 -s -p "Press any key to close this window..."\
    && echo "" \
    || error
fi


