library(testthat)
# Tests if data loaded into SQLite (setup_db.R), and checks data reading from SQLite (utils.R)

source("../utils.R") 
context("Data loading")

test_that("connection to sqlite doable", {
    tcon <- dbConnect(SQLite(), "../PetRecords.sqlite")
    expect_true(attributes(tcon)$class[1] == "SQLiteConnection")
    DBI::dbDisconnect(tcon)
})

test_that("all sqlite db tables and views exist", {
    tcon <- dbConnect(SQLite(), "../PetRecords.sqlite")
    expect_gt(nrow(dbListObjects(tcon)), 11)
    DBI::dbDisconnect(tcon)
})

test_that("atleast the pets table is populated", {
    tcon <- dbConnect(SQLite(), "../PetRecords.sqlite")
    expect_gt(nrow(dbGetQuery(tcon, "SELECT * FROM dimPets")), 1)
    DBI::dbDisconnect(tcon)
})

test_that("data reads successfully from sqlite db", {
    expect_type(read_data("../PetRecords.sqlite"), "list")
})
