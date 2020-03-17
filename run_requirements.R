pkgs <- readLines("requirements.txt")

# installs packages only if not present  
install_missing <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        install.packages(pkg, repos = "https://cloud.r-project.org/")
    } else {
        cat(paste("Skipping already installed package:", pkg, "\n"))
    }
}

invisible(sapply(pkgs, install_missing))

# run the fontawesome package from github till suitable replacement found 
# TODO find a replacement
install_missing("devtools")
devtools::install_github("rstudio/fontawesome")

#set up the sqlite db
source("setup_db.R")

# run the shiny app
shiny::runApp(launch.browser = TRUE)

