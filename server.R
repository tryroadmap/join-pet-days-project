# Web app to display pet records and keep track of visits, test results, vaccines, etc.

library(shiny)
library(dplyr)
library(stringr)
library(purrr)
library(tibble)
library(timevis)
library(DT)
library(sparkline)
library(RSQLite)
library(lubridate)
library(fs)

source("utils.R")

# getting the data outside of server, so data is created once 
# and shared across all user sessions (within the same R process)
pet_records <- read_data("PetRecords.sqlite")
data_dir <- file.path("assets", "data")

function(input, output, session) {
  # create options for pet selection radio button ####
  output$all_pets <- renderUI({
    pets <- pet_records$dimPets %>% 
      pull(pet_name)
    
    radioButtons(inputId = "pet",
                 label = "Select pet:",
                 choices = pets,
                 selected = "Mylov")
  })
  
  # get pet image to be displayed in sidepanel ####
  output$pet_image <- renderImage({
    req(input$pet)
    
    tmpfile <- paste0("www/images/", input$pet,".png")
    
    list(src = tmpfile,
         height = "150px",
         contentType = "image/png")
  }, deleteFile = FALSE)
  
  # create pet info to be displayed in sidepanel ####
  output$pet_info <- renderText({
    req(input$pet)
    pet_details <- pet_records$dimPets %>% 
      filter(pet_name %in% input$pet)
    dob <- paste(strong("DOB:"), pet_details %>% 
                   mutate(pet_dob = format(as.Date(pet_dob), format = "%m-%d-%Y")) %>% 
                   pull(pet_dob))
    species <- paste(strong("Species:"), pet_details %>% 
                       pull(pet_species))
    breed <- paste(strong("Breed:"), pet_details %>% 
                     pull(pet_breed))
    sex <- paste(strong("Sex:"), pet_details %>% 
                   pull(pet_sex))
    color <- paste(strong("Color:"), pet_details %>% 
                     pull(pet_color))
    
    paste(dob, species, breed, sex, color, sep = "<br>")
  })
  
  # create pet weight history sparkline ####
  output$pet_weight <- renderSparkline({
    req(input$pet)
    
    pet_records$viewVisitsPets %>% 
      select(pet_name, visit_date, visit_weight) %>% 
      filter(pet_name == input$pet, !is.na(visit_weight)) %>% 
      arrange(visit_date) %>% 
      pull(visit_weight) %>% 
      sparkline(width = "98%", 
                height = "100px", 
                spotRadius = 7,
                spotColor = FALSE,
                highlightSpotColor = "#999", 
                fillColor = FALSE, 
                lineColor = "#999", 
                highlightLineColor = "#333",
                lineWidth = 3,
                maxSpotColor = "#fd7e14",
                minSpotColor = "#fd7e14")
  })
  
  output$pet_weight_table <- renderTable({
    req(input$pet)
    
    pet_records$viewVisitsPets %>%
      filter(pet_name == input$pet, !is.na(visit_weight)) %>% 
      select(visit_date, visit_weight) %>% 
      arrange(desc(visit_date)) %>% 
      mutate_at(vars(visit_date), funs(format(as.Date(.), format = "%m-%d-%Y"))) %>% 
      mutate(Weight = formatC(visit_weight, format = "f", digits = 1)) %>%
      select(Date = visit_date, Weight)
  })
  
  # create date selections for med timeline date range input ####
  output$med_tl_dates <- renderUI({
    min_date <- pet_records$viewRoutineMedHistTimeline %>% 
      select(start) %>%
      summarize(min(start)) %>% 
      pull()
    
    dateRangeInput(inputId = "med_tl_date_range", 
                   label = "Select Date Range:", 
                   start = Sys.Date() %m-% months(18), 
                   end = Sys.Date() %m+% months(1), 
                   min = ymd(min_date) %m-% months(2),
                   format = "mm-dd-yyyy",
                   startview = "years",
                   width = "75%")
  })
  
  # create medical and tests history timeline ####
  output$med_history_timeline <- renderTimevis({
    req(input$pet)
    
    config <- list(
      zoomKey = "ctrlKey",
      start = input$med_tl_date_range[1],
      end = input$med_tl_date_range[2]
    )
    
    if (input$routine_visits) {
      grouped_data <- pet_records$viewRoutineMedHistTimeline %>% 
        filter(pet_name %in% input$pet) %>% 
        mutate(className = group,
               title = paste("Date:", format(as.Date(start), format = "%m-%d-%Y")))
      
      groups <- data.frame(
        id = c("routine", "med", "test"),
        content = c("Routine", "Medical History", "Test History")
      )
    } else {
      grouped_data <- pet_records$viewMedHistTimeline %>% 
        filter(pet_name %in% input$pet) %>% 
        mutate(className = group,
               title = paste("Date:", format(as.Date(start), format = "%m-%d-%Y")))
      
      groups <- data.frame(
        id = c("med", "test"),
        content = c("Medical History", "Test History")
        )
    }
    timevis(grouped_data, groups = groups, options = config)
  })
  
  # update med timeline date range based on user input and button pushes ####

  # fit all items on timeline on button push
  observeEvent(input$med_fit, {
    fitWindow("med_history_timeline")
  })
  
  # change timeline back to default window
  observeEvent(input$med_default, {
    setWindow("med_history_timeline", Sys.Date() %m-% months(18), Sys.Date() %m+% months(1))
    
    # updateCheckboxInput(session, inputId = "routine_visits", value = FALSE) for some reason adding this doesn't change timeline window and 
    # is in conflict with the updateDateRangeInput below
  })
  
  observeEvent(input$med_history_timeline_window, {
    updateDateRangeInput(session, inputId = "med_tl_date_range",
                         start = prettyDate(input$med_history_timeline_window[1]),
                         end = prettyDate(input$med_history_timeline_window[2]))
  })
  
  # define reactiveValues to prevent errors when user has an item selected in a timeline 
  # and then changes the pet filter or routine visits checkbox
  # reactive values ####
  values <- reactiveValues(med_tl_selected = NULL, vacc_tl_selected = NULL )
  
  # pass value of input$med_history_timeline_selected to reactive value
  observe({
    values$med_tl_selected <- input$med_history_timeline_selected
  })
  
  # clear selection if different pet is chosen or routine visits is checked or unchecked
  observeEvent(c(input$pet, input$routine_visits), {
    values$med_tl_selected <- NULL
  })
  
  # display text to help user know to scroll down
  output$helpful_text <- renderText({
    if (!is.null(values$med_tl_selected)) {
      "Scroll down to view details"
    }
  })
  
  # create reactive variables for use in med timeline render functions ####
  get_group <- reactive({
    if (!is.null(values$med_tl_selected)) {
      input$med_history_timeline_data %>%
        filter(id == values$med_tl_selected) %>%
        pull(group)
    }
  })
  
  show_routine_fun <- reactive({
    !is.null(values$med_tl_selected) && get_group() == "routine"
  })
  
  show_visit_details_fun <- reactive({
    !is.null(values$med_tl_selected) && get_group() == "med"
  })
  
  show_test_results_fun <- reactive({
    !is.null(values$med_tl_selected) && get_group() == "test"
  })
  
  id <- reactive({
    if (!is.null(values$med_tl_selected)) {
      values$med_tl_selected %>% 
        str_extract("\\d+") %>% 
        as.integer()
    }
  })    
  
  test_result <- reactive({
    if (show_test_results_fun()) {
      pet_records$dimTests %>% 
        filter(test_id == id()) %>%
        pull(test_result_doc)
    }
  })
  
  exam <- reactive({
    if (show_visit_details_fun() | show_routine_fun()) {
      pet_records$viewVisitsPets %>% 
        filter(visit_id == id()) %>%
        pull(visit_exam_doc)
    }
  })
  
  # create server to ui variables for conditional panels ####
  # create server to ui variable for routine info conditional panel
  output$show_routine_details <- reactive({
    show_routine_fun()
  })
  outputOptions(output, "show_routine_details", suspendWhenHidden = FALSE)
  
  # create server to ui variable for visit details conditional panel
  output$show_visit_details <- reactive({
    show_visit_details_fun()
  })
  outputOptions(output, "show_visit_details", suspendWhenHidden = FALSE)
  
  # create server to ui variable for test results conditional panel
  output$show_test_results <- reactive({
    show_test_results_fun() && !is.na(test_result())
  })
  outputOptions(output, "show_test_results", suspendWhenHidden = FALSE)
  
  # create server to ui variable for exam conditional panel
  output$show_exam <- reactive({
    (show_visit_details_fun() | show_routine_fun()) && !is.na(exam())
  })
  outputOptions(output, "show_exam", suspendWhenHidden = FALSE)
  
  # get routine details ####
  output$routine_visit_info <- renderText({
    if (show_routine_fun()) {
      visit_details <- pet_records$viewVisitsVets %>% 
        filter(visit_id == id())
      date <- paste(strong("Visit Date:"), visit_details %>%
                      mutate(visit_date = format(as.Date(visit_date), format = "%m-%d-%Y")) %>% 
                      pull(visit_date))
      vet <- paste(strong("Vet:"), visit_details %>%
                     pull(vet_name))
      doctor <- paste(strong("Doctor:"), visit_details %>%
                        pull(visit_doctor))
      vet_phone <- paste(strong("Vet Phone:"), visit_details %>%
                           pull(vet_phone))
      visit_category <- visit_details %>%
        pull(visit_category)
      # notes for visits tagged as medical and routine are shown when clicking medical item
      if (str_detect(visit_category, "medical")) {
        notes <- NA
      } else {
        notes <- paste(strong("Visit Information:"), visit_details %>%
                         pull(visit_notes))
      }
      
      paste(date, vet, doctor, vet_phone, notes, sep = "<br>")
    }
  })
  
  output$routine_test_info <- renderTable({
    if (show_routine_fun()) {
      tests <- pet_records$viewVisitsTests %>%
        filter(visit_id == id(), test_category %in% "routine") %>% 
        mutate_at(vars(test_name, test_result), funs(replace(., is.na(.), "None"))) %>% 
        select(Name = test_name, Result = test_result) 
      if (nrow(tests) == 0) {
        tibble(Name = "None",
               Result = "None")
      } else {
        tests
      }
    }
  })
  
  output$routine_medication_info <- renderText({
    if (show_routine_fun()) {
      meds <- pet_records$viewVisitsMeds %>%
        filter(visit_id == id(), med_category %in% c("flea and tick", "heartworm")) %>% 
        select(med_name) %>% 
        mutate_at(vars(med_name), funs(replace(., is.na(.), "None"))) %>% 
        distinct() %>% 
        pull() %>% 
        paste(collapse  = "<br>")
      
      if (meds == "") {
        "None"
      } else {
        meds
      }
    }
  })
  
  
  # get visit details ####
  output$visit_info <- renderText({
    if (show_visit_details_fun()) {
      visit_details <- pet_records$viewVisitsVets %>% 
        filter(visit_id == id())
      date <- paste(strong("Visit Date:"), visit_details %>%
                      mutate(visit_date = format(as.Date(visit_date), format = "%m-%d-%Y")) %>% 
                      pull(visit_date))
      vet <- paste(strong("Vet:"), visit_details %>%
                     pull(vet_name))
      doctor <- paste(strong("Doctor:"), visit_details %>%
                        pull(visit_doctor))
      vet_phone <- paste(strong("Vet Phone:"), visit_details %>%
                           pull(vet_phone))
      notes <- paste(strong("Visit Information:"), visit_details %>%
                       pull(visit_notes))
      
      paste(date, vet, doctor, vet_phone, notes, sep = "<br>")
    }
  })
  
  output$test_info <- renderTable({
    if (show_visit_details_fun()) {
      pet_records$viewVisitsTests %>%
        filter(visit_id == id(), !(test_category %in% "routine")) %>% 
        mutate_at(vars(test_name, test_result), funs(replace(., is.na(.), "None"))) %>% 
        select(Name = test_name, Result = test_result) 
    }
  })
  
  output$medication_info <- renderText({
    if (show_visit_details_fun()) {
      pet_records$viewVisitsMeds %>%
        filter(visit_id == id(), !(med_category %in% c("flea and tick", "heartworm"))) %>% 
        select(med_name) %>% 
        mutate_at(vars(med_name), funs(replace(., is.na(.), "None"))) %>% 
        distinct() %>% 
        pull() %>% 
        paste(collapse  = "<br>")
    }
  })
  
  # show exam file if visit is selected in timeline ####
  output$exam <- renderUI({
    if (show_visit_details_fun() | show_routine_fun()) {
      if (!is.na(exam())) {
        tags$iframe(style = "height:1400px; width:100%", src = file.path(data_dir, exam()))
      } else {
        h3("No Exam Notes Available")
        }
    }
  })
  
  # download exam results ####
  output$download_exam <- downloadHandler(
    filename = function() {
      "exam.pdf"
    },
    content = function(file) {
      file.copy(file.path(data_dir, exam()), file)
    }
  )
  
  # show test results file if test is selected in timeline ####
  output$test_results <- renderUI({
    if (show_test_results_fun()) {
      if (!is.na(test_result())) {
        tags$iframe(style = "height:1400px; width:100%", src = file.path(data_dir, test_result()))
      } else {
        h3("No Test Results Available")
        }
    }
  })
  
  # download test results ####
  output$download_test_results <- downloadHandler(
    filename = function() {
      "test_result.pdf"
    },
    content = function(file) {
      file.copy(file.path(data_dir, test_result()), file)
    },
    contentType = NA
  )
  
  # create vaccine timeline ####
  output$vaccine_history_timeline <- renderTimevis({
    req(input$pet, input$vacc)
    
    config <- list(
      zoomKey = "ctrlKey"
    )
    
    if (length(input$vacc) == 1 && input$vacc == "Y") {
      pet_records$viewVaccineHistTimeline %>%
        rowid_to_column(var = "id") %>% 
        filter(pet_name %in% input$pet, current_flag %in% input$vacc) %>% 
        mutate(content = paste0("<b>",content, "</b>", "&nbsp;&nbsp;&nbsp;<i>expires in ", days_to_expiration," days</i>"),
               title = paste("Date Given: ", format(as.Date(start), format = "%m-%d-%Y"), "\n", "Date Expires: ", format(as.Date(end), format = "%m-%d-%Y"), "\n" ,"Vet: ", vet_name, sep = "")) %>% 
        timevis(options = config)
    } else {
      vacc_data <- pet_records$viewVaccineHistTimeline %>% 
        rowid_to_column(var = "id") %>% 
        filter(pet_name %in% input$pet, current_flag %in% input$vacc) %>% 
        mutate(title = paste("Date Given: ", format(as.Date(start), format = "%m-%d-%Y"), "\n", "Date Expires: ", format(as.Date(end), format = "%m-%d-%Y"), "\n" ,"Vet: ", vet_name, sep = ""),
               group = content)
      
      groups <- data.frame(
        id = unique(pet_records$viewVaccineHistTimeline$content),
        content = unique(pet_records$viewVaccineHistTimeline$content)
      )
      timevis(vacc_data, groups = groups, options = config)
      }
  })
  
  # reset timeline view on button push
  observeEvent(input$vaccinefit, {
    fitWindow("vaccine_history_timeline")
  })
  
  # pass value of input$vaccine_history_timeline_selected to reactive value ####
  observe({
    values$vacc_tl_selected <- input$vaccine_history_timeline_selected
  })
  
  # clear selection if different pet or current vs. past vaccine history is chosen
  observeEvent(c(input$pet, input$vacc), {
    values$vacc_tl_selected <- NULL
  })
  
  # display text to help user know to scroll down
  output$more_helpful_text <- renderText({
    if (!is.null(values$vacc_tl_selected)) {
      "Scroll down to view details"
    }
  })
  
  cert <- reactive({
    # get doc not found error if data is filtered and all values in the column are NA
    # timeline data deletes column if all values in a column are NA
    if (!is.null(values$vacc_tl_selected)) {
      input$vaccine_history_timeline_data %>%
        filter(id == values$vacc_tl_selected) %>%  
        pull(doc)
    }
  })  
  
  # create server to ui variable for vaccine certificate conditional panel ####
  output$show_vaccine_cert <- reactive({
    !is.null(values$vacc_tl_selected) && !is.na(cert())
  })
  outputOptions(output, "show_vaccine_cert", suspendWhenHidden = FALSE)
  
  # show vaccine cert if vaccine is selected in timeline ####
  output$vaccine_cert <- renderUI({
    if (!is.null(values$vacc_tl_selected)) {
      if (!is.na(cert())) {
        tags$iframe(style = "height:1400px; width:100%", src = file.path(data_dir, cert()))
      } else {
        h3("No Vaccine Certificate Available")
        }
    }
  })
  
  # download vaccine certificate ####
  output$download_vacc <- downloadHandler(
    filename = function() {
      "vaccine_cert.pdf"
    },
    content = function(file) {
      file.copy(file.path(data_dir, cert()), file)
    }
  )
  
  # delete session files when the application exits (when runApp exits) -- no session files
  # or after each user session ends
  # onStop(function()
  #   unlink(c(test_result_path, exam_path, vaccine_cert_path)))
  
}