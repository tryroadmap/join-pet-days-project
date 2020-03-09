library(RSQLite)

# Connects to and reads from the SQLite DB 
read_data <- function() {
    # list required tables/views
    tables <- c("dimPets",
                "dimTests",
                "viewVisitsPets",
                "viewRoutineMedHistTimeline",
                "viewMedHistTimeline",
                "viewVisitsVets",
                "viewVisitsTests",
                "viewVisitsMeds",
                "viewMedsPetsVets",
                "viewVisitsPetsVets",
                "viewVaccineHistTimeline")
    con <- dbConnect(SQLite(), "PetRecords.sqlite")
    tryCatch(
        pet_records <- setNames(map(tables, function(.) {
            dbReadTable(con, .)
          }), tables),
        error = function(e) {
            print(paste(e, "Make sure you run setup_db.R first to propagate data from the csv files into the SQLite db"))
        },
        finally = dbDisconnect(con)
    )
    return(pet_records)
}

prettyDate <- function(d) {
  str_extract(d, "\\d{4}-\\d{2}-\\d{2}")
}
