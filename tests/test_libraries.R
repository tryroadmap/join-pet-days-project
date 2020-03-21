library(testthat)
# Tests if packages installed sucessfully and libraries can load

context("Library Loading")

pkgs <- readLines("../requirements.txt")

expect_installed <- function(pkg) {
    expect(requireNamespace(pkg, quietly = TRUE), paste0(pkg, " package not installed!"))
}

test_that("required packages are installed", {
    sapply(pkgs, function(pkg) expect_installed(pkg))
})
