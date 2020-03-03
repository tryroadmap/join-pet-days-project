#! /bin/sh

reqfile=${1}

while read line
do
Rscript -e 'install.packages("'$line'", repos = "https://cloud.r-project.org/")' 
done < $reqfile

# run the fontawesome package from github till suitable replacement found
Rscript -e 'devtools::install_github("rstudio/fontawesome")'
