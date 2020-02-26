### setup
```
git clone https://github.com/lotusxai/pet-days.git
cd pet-days/

```

#### short story
As a digital nomad traveling with 2 dogs, keeping track of all their medical and vaccine records has been challenging. Especially since one of my dogs has had some recent health issues. I needed a way to keep track of all the vet visits, test results, vaccine certificates, etc. as well as be able to share them with new vets and our home base vet back in Colorado. Thus, an R shiny app was born.

#### refactor steps
- [ ] Setup R/RStudio
```
export RSTUDIO_WHICH_R=/usr/local/bin/R
```
- [ ] runApp()
- [ ] install required libraries, update a requirement.txt file to keep track
- [ ] Run MySQL locally
- [ ] update requirement.txt
- [ ] add run bash for requirements.txt in setup
```
Error in library(aws.s3) : there is no package called ‘aws.s3’
the stable library does not have a pass build.
```
- [ ] add .gitignore for DSStore mac OS and R. (.DS_Store)
- [ ] from scheme setup dummy values for csv files in asset/data
- [ ] convert tasks to issues for the repo
- [ ] add Continue Integration badge.  [![Build Status](https://travis-ci.org/)](https://travis-ci.org/) - "*build passing*"
- [ ] add Test/Code Coverage badge.  [![codecov.io Code Coverage](https://img.shields.io/codecov/c/github/)](https://codecov.io/github/)
- [ ] add CodeClimate badge.  [![codecov.io Code Coverage](https://img.shields.io/codecov/c/github/)](https://codecov.io/github/)
