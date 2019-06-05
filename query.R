# Libraries and functions loaded ------------------------------------------
library(googleAuthR)
library(openxlsx)
library(dplyr)
source("R/functions/api_data.R")
source("R/functions/gtm_api.R")
source("R/functions/var_types_table.R")

# Basic input for project -------------------------------------------------
projectName <- 'INSERT_PROJECT_OR_COMPANYNAME'
Sys.Date() -> date
xlsXFileName <- paste0(projectName, '_gtmDocumentation_',date,'.xlsx')

# Authenticate API --------------------------------------------------------
googleAuthR::gar_auth()

# Choose account_id -------------------------------------------------------
account_id <- "INSERT_GTM_ACCOUNT_ID"

# Run account_id specific queries -----------------------------------------
gtm_container_list(account_id) -> container_list
gtm_account_list() -> account_list

# Choose container from container_list ------------------------------------
container_id <- "INSERT_CONTAINER_NAME"
container_name <- container_list$container.name

# Get Environment list ----------------------------------------------------
gtm_environment_list(account_id, container_id) -> environment_list

gtm_container_version(account_id, container_id) -> latest_version

# Get Builtin Variable list ----------------------------------------------------
gtm_builtin_list(account_id, container_id) -> builtinvar_list
builtinvar_list[,c("name", "type")] -> builtinvar_list

# tag list ----------------------------------------------------------------
gtm_tag_list(account_id, container_id) -> tag_list
tag_list[,c(5:7,11,15,16)] -> tag_list
colnames(tag_list)[c(4,6)] <- c("folderId", "tag.enabled")
!tag_list$tag.enabled -> tag_list$tag.enabled
tag_list %>% mutate_each(funs(replace(., is.na(.), TRUE)), tag.enabled) -> tag_list

# variable list -----------------------------------------------------------
gtm_var_list(account_id, container_id) -> variable_list
variable_list$variable.parameter <- NULL 
colnames(variable_list)[10] <- "folderId"

transform(variable_list, description=do.call(rbind, strsplit(variable.notes, 'EXAMPLE:', fixed=TRUE)), stringsAsFactors=F) -> variable_list

transform(variable_list, type=do.call(rbind, strsplit(description.2, 'TYPE:', fixed=TRUE)), stringsAsFactors=F) -> variable_list
left_join(variable_list, var_trans, by = "variable.type") -> variable_list # get the GTM variable full names list

names(variable_list)[names(variable_list) == "description.1"] <-"description"
names(variable_list)[names(variable_list) == "type.1"] <-"example"
names(variable_list)[names(variable_list) == "type.2"] <-"variable_setting"
variable_list$variable.notes <- NULL
variable_list$variable.formatValue <- NULL

# trigger list -------------------------------------------------------
gtm_trigger_list(account_id, container_id) -> trigger_list
trigger_list$triggers.filter <- NULL
colnames(trigger_list)[10] <- "folderId"
trigger_list[c(8,9,11,12,14:21)] <- NULL

# Permissions list --------------------------------------------------------
gtm_user_list(account_id) -> permissions_list
permissions_list$userPermission.containerAccess <- NULL
permissions_list$userPermission.accountAccess[,1] -> permissions_list$userPermission.accountAccess
permissions_list[,c("userPermission.emailAddress", "userPermission.accountAccess")] -> permissions_list_clean

# Folders list ------------------------------------------------------------
gtm_folder_list(account_id, container_id) -> folders_list
colnames(folders_list)[5] <- "folderId"

folders_list[,c("folderId", "folder.name")] -> folder_list_clean

# join folders with tags and variables --------------------------------------------------
left_join(tag_list, folders_list, by="folderId") -> tag_list
left_join(variable_list, folders_list, by="folderId") -> variable_list
left_join(trigger_list, folders_list, by="folderId") -> trigger_list

tag_list[,c("tag.tagId","tag.name","tag.type","folder.name","tag.enabled")] -> tag_list_clean
variable_list[,c("variable.variableId", "variable.name", "variable_type", "folder.name", "example","variable_setting", "description")] -> variable_list_clean
trigger_list[,c("trigger.triggerId","trigger.name","trigger.type","folder.name","trigger.notes")] -> trigger_list_clean

# no NA values in data.frames anymore -------------------------------------
tag_list[is.na(tag_list)] <- 0
variable_list[is.na(variable_list)] <- 0

# Summary info ------------------------------------------------------------
NumberTags <- nrow(tag_list)
NumberVars <- nrow(variable_list)
NumberTriggers <- nrow(trigger_list)
gtm_tag_id <- container_list$container.publicId[1]
#gtm_container_notes <- curr_cont_data$containers.notes
curr_env_data <- environment_list[environment_list$environment.type == "live", ]
gtm_latest_publish <- as.numeric(curr_env_data$environment.authorizationTimestampMs)
gtm_latest_publish <- as.character(as.Date(as.POSIXct(gtm_latest_publish/1000, origin="1970-01-01")))

# Build the Excel ---------------------------------------------------------
  wb <- createWorkbook()
  addWorksheet(wb, "Summary", gridLines = FALSE)
  addWorksheet(wb, "Variables", tabColour = "#408080", gridLines = FALSE)
  addWorksheet(wb, "Built-in Variables", tabColour = "#408080", gridLines = FALSE)  
  addWorksheet(wb, "Tags", tabColour = "#408080", gridLines = FALSE)
  addWorksheet(wb, "Triggers", tabColour = "#408080", gridLines = FALSE)
  addWorksheet(wb, "Users", tabColour = "#408080", gridLines = FALSE)
  addWorksheet(wb, "Folders", tabColour = "#408080", gridLines = FALSE)  
  
  # Excel styling
  hs1 <- createStyle(fgFill = "#0f1922", halign = "CENTER", textDecoration = "bold", fontSize = 13, border = "Bottom")
  hs2 <- createStyle(halign = "CENTER", textDecoration = "bold", fontSize = 23, border = "Bottom")
  hs3 <- createStyle(halign = "CENTER", textDecoration = "bold", fontSize = 15)
  addStyle(wb, sheet = "Summary", hs3, rows = 6:14, cols = 4, gridExpand = TRUE)
  
  # Create tables in Excel
  writeDataTable(wb, "Folders", folder_list_clean, startCol = 1, startRow = 1, xy = NULL,
            colNames = TRUE, rowNames = FALSE, headerStyle = hs1,
            withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Folders", cols = 1:5, widths = c(15,25))
  
  writeDataTable(wb, "Users", permissions_list_clean, startCol = 1, startRow = 1, xy = NULL,
            colNames = TRUE, rowNames = FALSE, headerStyle = hs1,
            withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Users", cols = 1:4, widths = c(40,40,40,40))
  
  writeDataTable(wb, "Variables", variable_list_clean, startCol = 1, startRow = 1, xy = NULL, colNames = TRUE, rowNames = FALSE, headerStyle = hs1, withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Variables", cols = 1:7, widths = c(20,40,25,25,35,30,150))

  writeDataTable(wb, "Built-in Variables", builtinvar_list, startCol = 1, startRow = 1, xy = NULL, colNames = TRUE, rowNames = FALSE, headerStyle = hs1, withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Built-in Variables", cols = 1:2, widths = c(25,25))
  
  writeDataTable(wb, "Tags", tag_list_clean, startCol = 1, startRow = 1, xy = NULL,
            colNames = TRUE, rowNames = FALSE, headerStyle = hs1,
            withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Tags", cols = 1:10, widths = c(15,40,20,25,20,20,20,20,20,20))
  
  writeDataTable(wb, "Triggers", trigger_list_clean, startCol = 1, startRow = 1, xy = NULL,
            colNames = TRUE, rowNames = FALSE, headerStyle = hs1,
            withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Triggers", cols = 1:6, widths = c(20,40,20,25,100))
  
  #Write all data to summary sheets
  writeData(wb, "Summary", "Summary", startCol = 4, startRow = 4, xy = NULL,
            colNames = TRUE, rowNames = FALSE, withFilter = FALSE, keepNA = FALSE)
  addStyle(wb, sheet = "Summary", hs2, rows = 4, cols = 4, gridExpand = TRUE)
  setColWidths(wb, sheet = "Summary", cols = 4, widths = 30)
  writeData(wb, "Summary", projectName, startCol = 4, startRow = 6, keepNA = FALSE)
  writeData(wb, "Summary", gtm_tag_id, startCol = 4, startRow = 7, keepNA = FALSE)
  writeData(wb, "Summary", paste("Report built on date: ",format(Sys.time(), "%A %d %B %Y"), sep=""), startCol = 4, startRow = 8, keepNA = FALSE)
  writeData(wb, "Summary", paste(NumberTags, " tags in account", sep=""), startCol = 4, startRow = 10, keepNA = FALSE)
  writeData(wb, "Summary", paste(NumberVars, " variables in account", sep=""), startCol = 4, startRow = 11, keepNA = FALSE)
  writeData(wb, "Summary", paste(NumberTriggers, " triggers in account", sep=""), startCol = 4, startRow = 12, keepNA = FALSE)

  #create the workbook
  saveWorkbook(wb, file = paste0("output/reports/",xlsXFileName), overwrite = TRUE)
