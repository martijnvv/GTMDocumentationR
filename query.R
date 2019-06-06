# Libraries and functions loaded ------------------------------------------
library(googleAuthR)
library(openxlsx)
source("R/functions/api_data.R")
source("R/functions/gtm_api.R")

# Basic input for project -------------------------------------------------
projectName <- 'Dummy inc' #insert company name here for Excel output
Sys.Date() -> date
xlsXFileName <- paste0(projectName, '_gtmDocumentation_',date,'.xlsx')

# Authenticate API --------------------------------------------------------
googleAuthR::gar_auth()

# Choose account_id -------------------------------------------------------
account_id <- "INSERT_ACCOUNT_ID"

# Run account_id specific queries -----------------------------------------
gtm_container_list(account_id) -> container_list
gtm_account_list() -> account_list

# Choose container from container_list ------------------------------------
container_id <- "INSERT_CONTAINER_ID"

# Get workspace and environment data ----------------------------------------------------
gtm_environment_list(account_id, container_id) -> environment_list
gtm_workspace_list(account_id, container_id) -> workspace_list
gtm_workspace_id(account_id, container_id) -> workspace_id

# Get Builtin Variable list ----------------------------------------------------
gtm_builtin_list(account_id, container_id) -> builtinvar_list

# tag list ----------------------------------------------------------------
gtm_tag_list(account_id, container_id) -> tag_list
colnames(tag_list)[c(4,5)] <- c("folderId", "tag.enabled")
tag_list$tag.enabled[is.na(tag_list$tag.enabled)] <- FALSE

# variable list -----------------------------------------------------------
gtm_var_list(account_id, container_id) -> variable_list
colnames(variable_list)[5] <- "folderId"

# optional to split the notes column in multiple columns
transform(variable_list, description=do.call(rbind, strsplit(variable.notes, 'EXAMPLE:', fixed=TRUE)), stringsAsFactors=F) -> variable_list
transform(variable_list, type=do.call(rbind, strsplit(description.2, 'TYPE:', fixed=TRUE)), stringsAsFactors=F) -> variable_list
names(variable_list)[names(variable_list) == "description.1"] <-"description"
names(variable_list)[names(variable_list) == "type.1"] <-"example"
names(variable_list)[names(variable_list) == "type.2"] <-"variable_setting"

# Optional. rename the variable types to readable format
variable.type <- c("k","v","u","jsm","gas","remm","j","c","aev","smm","ctv","dbg","d","f","r")
variable_type <- c("1st-Party Cookie", "Data Layer Variable", "URL", "Custom JavaScript", "	Google Analytics settings", "RegEx Table","Javascript Variable","Constant","Auto-Event Variable","Lookup Table","Container Version Number","Debug Mode","DOM Element","HTTP Referrer","Random Number")
var_trans <- data.frame(variable.type,variable_type)

merge(variable_list, var_trans, by = "variable.type", all.x = TRUE) -> variable_list

# trigger list -------------------------------------------------------
gtm_trigger_list(account_id, container_id) -> trigger_list
colnames(trigger_list)[4] <- "folderId"

# Permissions list --------------------------------------------------------
gtm_user_list(account_id) -> permissions_list

# Folders list ------------------------------------------------------------
gtm_folder_list(account_id, container_id) -> folders_list
colnames(folders_list)[1] <- "folderId"

# join folders with tags and variables --------------------------------------------------
merge(tag_list, folders_list, by = "folderId", all.x = TRUE) -> tag_list
merge(variable_list, folders_list, by = "folderId", all.x = TRUE) -> variable_list
merge(trigger_list, folders_list, by = "folderId", all.x = TRUE) -> trigger_list

tag_list[,c("tag.tagId","tag.name","tag.type","folder.name","tag.enabled")] -> tag_list
variable_list[,c("variable.variableId", "variable.name", "variable_type", "folder.name", "example","variable_setting", "description")] -> variable_list
trigger_list[,c("trigger.triggerId","trigger.name","trigger.type","folder.name","trigger.notes")] -> trigger_list

# Summary info ------------------------------------------------------------
NumberTags <- nrow(tag_list)
NumberVars <- nrow(variable_list)
NumberTriggers <- nrow(trigger_list)
gtm_tag_id <- container_list$container.publicId[1]
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
  writeDataTable(wb, "Folders", folders_list, startCol = 1, startRow = 1, xy = NULL,
            colNames = TRUE, rowNames = FALSE, headerStyle = hs1,
            withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Folders", cols = 1:5, widths = c(15,25))
  
  writeDataTable(wb, "Users", permissions_list, startCol = 1, startRow = 1, xy = NULL,
            colNames = TRUE, rowNames = FALSE, headerStyle = hs1,
            withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Users", cols = 1:4, widths = c(40,40,40,40))
  
  writeDataTable(wb, "Variables", variable_list, startCol = 1, startRow = 1, xy = NULL, colNames = TRUE, rowNames = FALSE, headerStyle = hs1, withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Variables", cols = 1:7, widths = c(20,40,25,25,35,30,150))

  writeDataTable(wb, "Built-in Variables", builtinvar_list, startCol = 1, startRow = 1, xy = NULL, colNames = TRUE, rowNames = FALSE, headerStyle = hs1, withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Built-in Variables", cols = 1:2, widths = c(25,25))
  
  writeDataTable(wb, "Tags", tag_list, startCol = 1, startRow = 1, xy = NULL,
            colNames = TRUE, rowNames = FALSE, headerStyle = hs1,
            withFilter = TRUE, keepNA = FALSE)
  setColWidths(wb, sheet = "Tags", cols = 1:10, widths = c(15,40,20,25,20,20,20,20,20,20))
  
  writeDataTable(wb, "Triggers", trigger_list, startCol = 1, startRow = 1, xy = NULL,
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
