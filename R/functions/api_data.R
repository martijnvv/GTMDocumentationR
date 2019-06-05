# API data ----------------------------------------------------------------
#Create a project in de Google API console to get a client ID and client secret: https://console.developers.google.com/flows/enableapi?apiid=tagmanager&credential=client_key&pli=1
client_id <- "ADD_CLIENT_ID"
client_secret <- "ADD_CLIENT_SECRET"

options("googleAuthR.scopes.selected" = c("https://www.googleapis.com/auth/tagmanager.edit.containerversions",
                                          "https://www.googleapis.com/auth/tagmanager.publish",
                                          "https://www.googleapis.com/auth/tagmanager.manage.users",
                                          "https://www.googleapis.com/auth/tagmanager.delete.containers",
                                          "https://www.googleapis.com/auth/tagmanager.edit.containers",
                                          "https://www.googleapis.com/auth/tagmanager.readonly"))

options("googleAuthR.client_id" = client_id)
options("googleAuthR.client_secret" = client_secret)
