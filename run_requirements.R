# create logs dir
logs_dir <- file.path("assets","log")
dir.create(logs_dir)
logfile <- file(file.path(logs_dir, "run_requirements.log"), open = "at")
sink(logfile, append = TRUE, split = TRUE, type ="output")
sink(logfile, append = TRUE, type="message")
cat(paste0("-------- Run Log ", Sys.time(), " --------\n"))

pkgs <- readLines("requirements.txt")

# installs packages only if not present  
install_missing <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        cat(paste(Sys.time(), "Installing package:", pkg, "\n"))
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
cat(paste(Sys.time(), "\t-- Database setup --\n"))

try(source("setup_db.R"))

#run tests to check above steps
cat(paste(Sys.time(), "\t-- Unit tests --\n"))
testthat::test_dir("tests")
sink()
cat(paste("LOG DIRECTORY:", logs_dir))

