# Create the SQLite db and tables, inserts data from csv files, and creates Views and triggers for the shiny app
library(RSQLite)

## DB setup
mydb <- dbConnect(SQLite(), "PetRecords.sqlite")


# read csv
fpath <- file.path("assets","data", "pet_records.RData")
load(fpath, verbose = TRUE)

# create tables
rs <- dbSendStatement(mydb, "CREATE TABLE `dimPets` (
  `pet_id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  `pet_name` varchar(250) NOT NULL,
  `pet_dob` date,
  `pet_species` varchar(200),
  `pet_breed` varchar(200),
  `pet_sex` varchar(50),
  `pet_color` varchar(100),
  `pet_picture` varchar(5000),
  `created_date` datetime NOT NULL DEFAULT (DATETIME('NOW')),
  `updated_date` datetime
)")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE TABLE `dimVets` (
  `vet_id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  `vet_name` varchar(250) NOT NULL,
  `vet_address` varchar(250),
  `vet_city` varchar(250),
  `vet_state` varchar(2),
  `vet_zip` varchar(20),
  `vet_phone` varchar(20),
  `vet_website` varchar(500),
  `vet_email` varchar(500),
  `vet_med_rec_site` varchar(500),
  `created_date` datetime NOT NULL DEFAULT (DATETIME('NOW')),
  `updated_date` datetime
)")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE TABLE `dimVisits` (
  `visit_id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  `visit_date` date NOT NULL,
  `visit_weight` float,
  `visit_receipt` varchar(5000),
  `visit_notes` varchar(5000),
  `med_visit_summary` varchar(2000),
  `routine_visit_summary` varchar(2000),
  `visit_category` varchar(200) NOT NULL,
  `visit_doctor` varchar(200),
  `visit_exam_doc` varchar(5000),
  `created_date` datetime NOT NULL DEFAULT (DATETIME('NOW')),
  `updated_date` datetime,
  `pet_id` smallint(6) NOT NULL,
  `vet_id` int(11) NOT NULL
)")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE TABLE `dimVaccines` (
  `vaccine_id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  `vaccine_name` varchar(200) NOT NULL,
  `vaccine_description` varchar(500),
  `vaccine_series_num` smallint(6),
  `vaccine_date_given` date NOT NULL,
  `vaccine_date_expires` date,
  `vaccine_notes` varchar(5000),
  `vaccine_current_flag` varchar(45) NOT NULL,
  `vaccine_certificate` varchar(5000),
  `created_date` datetime NOT NULL DEFAULT (DATETIME('NOW')),
  `updated_date` datetime,
  `pet_id` smallint(6) NOT NULL,
  `vet_id` int(11) NOT NULL,
  `visit_id` int(11) NOT NULL
)")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE TABLE `dimTests` (
  `test_id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  `test_name` varchar(200) NOT NULL,
  `test_description` varchar(500),
  `test_result` varchar(200),
  `test_series_num` smallint(6),
  `test_date_performed` date NOT NULL,
  `test_date_expires` date,
  `test_current_flag` varchar(1),
  `test_category` varchar(200) NOT NULL,
  `test_result_doc` varchar(5000),
  `created_date` datetime NOT NULL DEFAULT (DATETIME('NOW')),
  `updated_date` datetime,
  `pet_id` smallint(6) NOT NULL,
  `vet_id` int(11) NOT NULL,
  `visit_id` int(11) NOT NULL
)")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE TABLE `dimMeds` (
  `med_id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  `med_name` varchar(200) NOT NULL,
  `med_description` varchar(500),
  `med_dosage` varchar(200),
  `med_dosage_freq` varchar(500),
  `med_start_date` date,
  `med_end_date` date,
  `med_category` varchar(200),
  `med_current_flag` varchar(1) NOT NULL,
  `med_prescription` varchar(5000),
  `created_date` datetime NOT NULL DEFAULT (DATETIME('NOW')),
  `updated_date` datetime,
  `pet_id` smallint(6) NOT NULL,
  `vet_id` int(11) NOT NULL,
  `visit_id` int(11) NOT NULL
)")

dbClearResult(rs)

# insert data from csv files
dbWriteTable(mydb, "dimPets", dimPets, append = TRUE)
dbWriteTable(mydb, "dimVets", dimVets, append = TRUE)
dbWriteTable(mydb, "dimMeds", dimMeds, append = TRUE)
dbWriteTable(mydb, "dimTests", dimTests, append = TRUE)
dbWriteTable(mydb, "dimVaccines", dimVaccines, append = TRUE)
dbWriteTable(mydb, "dimVisits", dimVisits, append = TRUE)

#dbGetQuery(mydb, "SELECT * FROM dimVaccines")

# create triggers
rs <- dbSendStatement(mydb, "CREATE TRIGGER update_date_pets AFTER UPDATE 
           ON dimPets
            BEGIN
            UPDATE dimPets SET updated_date = datetime('now') WHERE pet_id = new.pet_id;
            END;")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE TRIGGER update_date_vets AFTER UPDATE 
            ON dimVets
            BEGIN
            UPDATE dimVets SET updated_date = datetime('now') WHERE vet_id = new.vet_id;
            END;")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE TRIGGER update_date_meds AFTER UPDATE 
            ON dimMeds
            BEGIN
            UPDATE dimMeds SET updated_date = datetime('now') WHERE med_id = new.med_id;
            END;")

rs <- dbSendStatement(mydb, "CREATE TRIGGER update_date_tests AFTER UPDATE  
            ON dimTests
            BEGIN
            UPDATE dimTests SET updated_date = datetime('now') WHERE test_id = new.test_id;
            END;")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE TRIGGER update_date_vac AFTER UPDATE 
            ON dimVaccines
            BEGIN
            UPDATE dimVaccines SET updated_date = datetime('now') WHERE vaccine_id = new.vaccine_id;
            END;")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE TRIGGER update_date_visits AFTER UPDATE  
            ON dimVisits
            BEGIN
            UPDATE dimVisits SET updated_date = datetime('now') WHERE visit_id = new.visit_id;
            END;")
dbClearResult(rs)

# create views
rs <- dbSendStatement(mydb, "CREATE VIEW viewVisitsPets AS
  SELECT 
    dimVisits.visit_id,
    dimVisits.visit_date,
    dimVisits.visit_weight,
    dimVisits.visit_receipt,
    dimVisits.visit_notes,
    dimVisits.med_visit_summary,
    dimVisits.routine_visit_summary,
    dimVisits.visit_category,
    dimVisits.visit_doctor,
    dimVisits.visit_exam_doc,
    dimVisits.pet_id,
    dimVisits.vet_id,
    dimPets.pet_name,
    dimPets.pet_dob,
    dimPets.pet_species,
    dimPets.pet_breed,
    dimPets.pet_sex,
    dimPets.pet_color
  FROM dimVisits
  INNER JOIN dimPets
  ON dimVisits.pet_id = dimPets.pet_id")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE VIEW viewRoutineMedHistTimeline AS
  SELECT 'routine' AS 'group', 
    visit_id || '_' || 'routine' AS id,
    pet_name,
    vet_name,
    visit_date AS 'start',
    routine_visit_summary AS content,
    visit_category AS category
  FROM viewVisitsPetsVets
  WHERE visit_category like '%routine' AND routine_visit_summary not like 'Initial visit'
  UNION
  SELECT 'med' AS 'group', 
    visit_id || '_' || 'med' AS id,
    pet_name,
    vet_name,
    visit_date AS 'start',
    med_visit_summary AS content,
    visit_category AS category
  FROM viewVisitsPetsVets
  WHERE visit_category like 'medical%'
  UNION
  SELECT 'test' AS 'group', 
    test_id || '_' || 'test' AS id,
    pet_name,
    vet_name,
    test_date_performed AS 'start',
    test_name AS content,
    test_category AS category
  FROM viewTestsPetsVets
  WHERE test_category like 'medical%'")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE VIEW viewMedHistTimeline AS
  SELECT 'med' AS 'group', 
    visit_id || '_' || 'med' AS id,
    pet_name,
    vet_name,
    visit_date AS 'start',
    med_visit_summary AS content,
    visit_category AS category
    FROM viewVisitsPetsVets
    WHERE visit_category like 'medical%'
    UNION
    SELECT 'test' AS 'group', 
    test_id || '_' || 'test' AS id,
    pet_name,
    vet_name,
    test_date_performed AS 'start',
    test_name AS content,
    test_category AS category
  FROM viewTestsPetsVets
  WHERE test_category like 'medical%'")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE VIEW viewVisitsVets AS
  SELECT dimVisits.visit_id,
    dimVisits.visit_date,
    dimVisits.visit_weight,
    dimVisits.visit_receipt,
    dimVisits.visit_notes,
    dimVisits.med_visit_summary,
    dimVisits.routine_visit_summary,
    dimVisits.visit_category,
    dimVisits.visit_doctor,
    dimVisits.visit_exam_doc,
    dimVisits.pet_id,
    dimVisits.vet_id,
    dimVets.vet_name,
    dimVets.vet_address,
    dimVets.vet_city,
    dimVets.vet_state,
    dimVets.vet_zip,
    dimVets.vet_phone,
    dimVets.vet_website,
    dimVets.vet_email,
    dimVets.vet_med_rec_site
  FROM dimVisits
  INNER JOIN dimVets
  ON dimVisits.vet_id = dimVets.vet_id")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE VIEW viewVisitsTests AS
  SELECT dimVisits.visit_id,
    dimVisits.visit_date,
    dimVisits.visit_weight,
    dimVisits.visit_receipt,
    dimVisits.visit_notes,
    dimVisits.med_visit_summary,
    dimVisits.routine_visit_summary,
    dimVisits.visit_category,
    dimVisits.visit_doctor,
    dimVisits.visit_exam_doc,
    dimVisits.pet_id,
    dimVisits.vet_id,
    dimTests.test_id,
    dimTests.test_name,
    dimTests.test_description,
    dimTests.test_result,
    dimTests.test_series_num,
    dimTests.test_date_performed,
    dimTests.test_date_expires,
    dimTests.test_current_flag,
    dimTests.test_category,
    dimTests.test_result_doc
  FROM dimVisits
  LEFT JOIN dimTests
  ON dimVisits.visit_id = dimTests.visit_id")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE VIEW viewVisitsMeds AS
  SELECT dimVisits.visit_id,
     dimVisits.visit_date,
     dimVisits.visit_weight,
     dimVisits.visit_receipt,
     dimVisits.visit_notes,
     dimVisits.med_visit_summary,
     dimVisits.routine_visit_summary,
     dimVisits.visit_category,
     dimVisits.visit_doctor,
     dimVisits.visit_exam_doc,
     dimVisits.pet_id,
     dimVisits.vet_id,
     dimMeds.med_id,
     dimMeds.med_name,
     dimMeds.med_description,
     dimMeds.med_dosage,
     dimMeds.med_dosage_freq,
     dimMeds.med_start_date,
     dimMeds.med_end_date,
     dimMeds.med_category,
     dimMeds.med_current_flag,
     dimMeds.med_prescription
  FROM dimVisits
  LEFT JOIN dimMeds
  ON dimVisits.visit_id = dimMeds.visit_id")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE VIEW viewMedsPetsVets AS
  SELECT dimMeds.med_id,
     dimMeds.med_name,
     dimMeds.med_description,
     dimMeds.med_dosage,
     dimMeds.med_dosage_freq,
     dimMeds.med_start_date,
     dimMeds.med_end_date,
     dimMeds.med_category,
     dimMeds.med_current_flag,
     dimMeds.med_prescription,
     dimMeds.pet_id,
     dimMeds.vet_id,
     dimMeds.visit_id,
     dimPets.pet_name,
     dimPets.pet_dob,
     dimPets.pet_species,
     dimPets.pet_breed,
     dimPets.pet_sex,
     dimPets.pet_color,
     dimVets.vet_name,
     dimVets.vet_address,
     dimVets.vet_city,
     dimVets.vet_state,
     dimVets.vet_zip,
     dimVets.vet_phone,
     dimVets.vet_website,
     dimVets.vet_email,
     dimVets.vet_med_rec_site
  FROM dimMeds
  INNER JOIN dimPets
  ON dimMeds.pet_id = dimPets.pet_id
  LEFT JOIN dimVets
  ON dimMeds.vet_id = dimVets.vet_id")
dbClearResult(rs)

## Views used by other views:
rs <- dbSendStatement(mydb, "CREATE VIEW viewTestsPetsVets AS
  SELECT dimTests.test_id,
    dimTests.test_name,
    dimTests.test_description,
    dimTests.test_result,
    dimTests.test_series_num,
    dimTests.test_date_performed,
    dimTests.test_date_expires,
    dimTests.test_current_flag,
    dimTests.test_category,
    dimTests.test_result_doc,
    dimTests.created_date,
    dimTests.updated_date,
    dimTests.pet_id,
    dimTests.vet_id,
    dimTests.visit_id,
    dimPets.pet_name,
    dimPets.pet_dob,
    dimPets.pet_species,
    dimPets.pet_breed,
    dimPets.pet_sex,
    dimPets.pet_color,
    dimVets.vet_name,
    dimVets.vet_address,
    dimVets.vet_city,
    dimVets.vet_state,
    dimVets.vet_zip,
    dimVets.vet_phone,
    dimVets.vet_website,
    dimVets.vet_email,
    dimVets.vet_med_rec_site
  FROM dimTests
  INNER JOIN dimPets
  ON dimTests.pet_id = dimPets.pet_id
  INNER JOIN dimVets
  ON dimTests.vet_id = dimVets.vet_id")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE VIEW viewVaccinesPetsVets AS
SELECT dimVaccines.vaccine_id,
   dimVaccines.vaccine_name,
   dimVaccines.vaccine_description,
   dimVaccines.vaccine_series_num,
   dimVaccines.vaccine_date_given,
   dimVaccines.vaccine_date_expires,
   dimVaccines.vaccine_notes,
   dimVaccines.vaccine_current_flag,
   dimVaccines.vaccine_certificate,
   dimVaccines.pet_id,
   dimVaccines.vet_id,
   dimVaccines.visit_id,
   dimPets.pet_name,
   dimPets.pet_dob,
   dimPets.pet_species,
   dimPets.pet_breed,
   dimPets.pet_sex,
   dimPets.pet_color,
   dimVets.vet_name,
   dimVets.vet_address,
   dimVets.vet_city,
   dimVets.vet_state,
   dimVets.vet_zip,
   dimVets.vet_phone,
   dimVets.vet_website,
   dimVets.vet_email,
   dimVets.vet_med_rec_site,
   CAST((julianday(dimVaccines.vaccine_date_expires, 'localtime') -  julianday('now', 'localtime')) AS integer) AS days_to_expiration
FROM dimVaccines
INNER JOIN dimPets
ON dimVaccines.pet_id = dimPets.pet_id
INNER JOIN dimVets
ON dimVaccines.vet_id = dimVets.vet_id")
dbClearResult(rs)


rs <- dbSendStatement(mydb, "CREATE VIEW viewVisitsPetsVets AS
  SELECT dimVisits.visit_id,
     dimVisits.visit_date,
     dimVisits.visit_weight,
     dimVisits.visit_receipt,
     dimVisits.visit_notes,
     dimVisits.med_visit_summary,
     dimVisits.routine_visit_summary,
     dimVisits.visit_category,
     dimVisits.visit_doctor,
     dimVisits.visit_exam_doc,
     dimVisits.pet_id,
     dimVisits.vet_id,
     dimPets.pet_name,
     dimPets.pet_dob,
     dimPets.pet_species,
     dimPets.pet_breed,
     dimPets.pet_sex,
     dimPets.pet_color,
     dimVets.vet_name,
     dimVets.vet_address,
     dimVets.vet_city,
     dimVets.vet_state,
     dimVets.vet_zip,
     dimVets.vet_phone,
     dimVets.vet_website,
     dimVets.vet_email,
     dimVets.vet_med_rec_site
  FROM dimVisits
  INNER JOIN dimPets
  ON dimVisits.pet_id = dimPets.pet_id
  INNER JOIN dimVets
  ON dimVisits.vet_id = dimVets.vet_id")
dbClearResult(rs)

rs <- dbSendStatement(mydb, "CREATE VIEW viewVaccineHistTimeline AS
  SELECT pet_name,
    vaccine_name AS content,
    vaccine_date_given AS 'start',
    vaccine_date_expires AS 'end',
    vet_name,
    vaccine_current_flag AS current_flag,
    vaccine_certificate AS doc,
    CASE WHEN vaccine_current_flag = 'Y' THEN 'current'
    ELSE 'past'
    END AS className,
    days_to_expiration
  FROM viewVaccinesPetsVets
  UNION 
  SELECT pet_name,
    test_name AS content,
    test_date_performed AS 'start',
    test_date_expires AS 'end',
    vet_name,
    test_current_flag AS current_flag,
    test_result_doc AS doc,
    CASE WHEN test_current_flag = 'Y' THEN 'current'
    ELSE 'past'
    END AS className,
   CAST((JulianDay(test_date_expires, 'localtime') - JulianDay('now', 'localtime')) AS Integer) AS days_to_expiration
  FROM viewTestsPetsVets
  WHERE test_current_flag IS NOT NULL")
dbClearResult(rs)

dbDisconnect(mydb)

