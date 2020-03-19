library(testthat)
# Tests if packages installed sucessfully and libraries can load

context("Library Loading")

pkgs <- readLines("../requirements.txt")

expect_installed <- function(pkg) {
    expect_false(!requireNamespace(pkg, quietly = TRUE))
    ifelse(requireNamespace(pkg, quietly = TRUE), NA, print(paste("failed package", pkg)))
}

test_that("required libraries are installed", {
    sapply(pkgs, function(pkg) {expect_installed(pkg)})
})
