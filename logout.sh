#!/bin/bash
USERNAME=$(basename $"$PWD") # returneaza doar numele ultimului director din cale
cd ..//..
sed -i "/^$USERNAME$/d" loggedUsers.txt
echo "Te ai delogat cu succes , $USERNAME!"
exit

