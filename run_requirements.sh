#! /bin/sh

reqfile=${1}

while read line
do 
echo $line | R --no-save
done < $reqfile
