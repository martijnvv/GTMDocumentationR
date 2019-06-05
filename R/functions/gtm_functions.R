gtm_account_list <- function(){
  acc_url <- "https://www.googleapis.com/tagmanager/v2/accounts"
  f_acc <- gar_api_generator(acc_url,
                             "GET")
  a <- f_acc()
  as.data.frame(a$content)
}

gtm_container_list <- function(account_id){
  acc_url <- "https://www.googleapis.com/tagmanager/v2/accounts"
  f_con <- gar_api_generator(paste(acc_url, "/",account_id,"/containers", sep = ""),
                             "GET")
  c<- f_con()
  as.data.frame(c$content)
}

gtm_environment_list <- function(account_id, container_id) {
  cont_url <- paste("https://www.googleapis.com/tagmanager/v2/accounts/",account_id,"/containers", sep = "")
  env_url <- paste(cont_url,"/",container_id, "/environments", sep = "")
  f_env <- gar_api_generator(env_url, "GET")
  env <- f_env()
  as.data.frame(env$content)
}

gtm_container_version <- function(account_id, container_id){
  gtm_environment_list(account_id, container_id) -> ge
  max(as.numeric(ge$environment.containerVersionId), na.rm = TRUE)
}

gtm_workspace_id <- function(account_id, container_id){
  gtm_environment_list(account_id, container_id) -> ge
  max(as.numeric(ge$environment.workspaceId), na.rm = TRUE)
}

gtm_builtin_list <- function(account_id,container_id){
  gtm_container_version(account_id,container_id) -> v
  cont_url <- paste("https://www.googleapis.com/tagmanager/v2/accounts/",account_id,"/containers", sep = "")
  ver_url <- paste(cont_url,"/",container_id, "/versions/",v, sep = "")
  f_ver <- gar_api_generator(ver_url,
                             "GET")
  ver_list <- f_ver()
  ver_list$content$builtInVariable
  
}

gtm_tag_list <- function(account_id, container_id){
  gtm_workspace_id(account_id, container_id) -> ws
  cont_url <- paste("https://www.googleapis.com/tagmanager/v2/accounts/",account_id,"/containers", sep = "")
  f_tag <- gar_api_generator(paste(cont_url,"/",container_id, "/workspaces/",  ws,"/tags/", sep = "") ,
                             "GET")
  tag_list <- f_tag()
  as.data.frame(tag_list$content)
}

gtm_var_list <- function(account_id, container_id){
  gtm_workspace_id(account_id, container_id) -> ws
  cont_url <- paste("https://www.googleapis.com/tagmanager/v2/accounts/",account_id,"/containers", sep = "")
  var_url <- paste(cont_url,"/",container_id, "/workspaces/",  ws, "/variables", sep = "")
  f_var <- gar_api_generator(var_url,
                             "GET")
  variable_list <- f_var()
  as.data.frame(variable_list$content)
}

gtm_trigger_list <- function(account_id, container_id){
  gtm_workspace_id(account_id, container_id) -> ws
  cont_url <- paste("https://www.googleapis.com/tagmanager/v2/accounts/",account_id,"/containers", sep = "")
  tri_url <- paste(cont_url,"/",container_id, "/workspaces/",  ws, "/triggers", sep = "")
  f_tri <- gar_api_generator(tri_url,
                             "GET")
  t <- f_tri()
  as.data.frame(t$content)
}

gtm_user_list <- function(account_id){
  acc_url <- "https://www.googleapis.com/tagmanager/v2/accounts"
  user_url <- paste(acc_url, "/",account_id,"/user_permissions", sep = "")
  f_perm <- gar_api_generator(user_url,
                              "GET")
  permissions_list <- f_perm()
  permissions_list$content$userAccess$accountAccess$permission <- unlist(permissions_list$content$userAccess$accountAccess$permission)
  permissions_list$content$userAccess$accountAccess <- permissions_list$content$userAccess$accountAccess$permission
  as.data.frame(permissions_list$content)
}

gtm_folder_list <- function(account_id, container_id){
  gtm_workspace_id(account_id, container_id) -> ws
  cont_url <- paste("https://www.googleapis.com/tagmanager/v2/accounts/",account_id,"/containers", sep = "") 
  fol_url <- paste(cont_url,"/",container_id, "/workspaces/",  ws, "/folders", sep = "")
  f_fol <- gar_api_generator(fol_url, "GET")
  f <- f_fol()
  as.data.frame(f$content)
}
