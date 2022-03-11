#!/bin/bash


# A SHELL SCRIPT FOR INSTALLING THE TOOLBOX TO A UBUNTU LINUX SYSTEM
#
# This code is published under the GNU General Public License v3
#                         (https://www.gnu.org/licenses/gpl-3.0.en.html)
#
# Authors: Hans Fehr and Fabian Kindermann
#          contact@ce-fortran.com
#
# #VC# VERSION: 1.3  (21 April 2020)


cd "$( cd "$( dirname "$0" )" && pwd )"

# ASK FOR INSTALLATION CONFIRMATION
echo
echo This script installs or updates the toolbox.
echo 
read -rsp $'Do you want to continue (y/n)?' -n 1 key
echo

if [ "$key" != "y" ]; then
    exit 0
fi

# use gfortran to compile the toolbox
echo
echo ...COMPILING TOOLBOX... 
gfortran-8 -c -Werror -Wno-unused -fimplicit-none -Wall -fcheck=bound,do -ffpe-trap=invalid,zero,overflow -frecursive -g toolbox.f90 -o toolbox_debug.o
gfortran-8 -c -O3 toolbox.f90 -o toolbox.o
echo ...DONE... 
echo

# and copy the toolbox to the preferred working directory
echo
echo ...COPYING TO INCLUDE DIRECTORY...
sudo mkdir -p /usr/local/include
sudo mv toolbox.mod /usr/local/include/
sudo mv toolbox.o /usr/local/include/
sudo mv toolbox_debug.o /usr/local/include/
sudo cp toolbox_version.sh /usr/local/include/
echo ...DONE...
echo

# if everything ran correctly, at this point everything should be installed properly
echo  
echo ...TOOLBOX INSTALLATION COMPLETED.
echo 
echo
echo In case you encountered any problem, check on www.ce-fortran.com for help.
echo
echo
read -p "Press RETURN to end..."
