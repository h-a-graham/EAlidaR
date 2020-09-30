library(tidyverse)
library(rvest)
# library(splashr)
# library(stevedore)
# library(reticulate)
# library(wdman)


library(RSelenium)
rD <- RSelenium::rsDriver(
  port = 4444L,
  browser = c("firefox"),
  version = "latest"
)

driver <- RSelenium::rsDriver(browser = "chrome",
                              chromever =
                                system2(command = "wmic",
                                        args = 'datafile where name="C:\\\\Program Files (x86)\\\\Google\\\\Chrome\\\\Application\\\\chrome.exe" get Version /value',
                                        stdout = TRUE,
                                        stderr = TRUE) %>%
                                stringr::str_extract(pattern = "(?<=Version=)\\d+\\.\\d+\\.\\d+\\.") %>%
                                magrittr::extract(!is.na(.)) %>%
                                stringr::str_replace_all(pattern = "\\.",
                                                         replacement = "\\\\.") %>%
                                paste0("^",  .) %>%
                                stringr::str_subset(string =
                                                      binman::list_versions(appname = "chromedriver") %>%
                                                      dplyr::last()) %>%
                                as.numeric_version() %>%
                                max() %>%
                                as.character())

remote_driver <- driver[["client"]]





driver <- rsDriver(browser=c("chrome"))
remote_driver <- driver[["client"]]
remote_driver$open()



link <- 'https://environment.data.gov.uk/DefraDataDownload/?Mode=survey'



# use_condaenv(condaenv = "reticulate_env", conda = file.path('C:/Users/hg340/AppData/Local/Continuum/miniconda3'))
# install_splash()
# splash_container <- start_splash()
#
#









defra_page <- read_html('https://environment.data.gov.uk/DefraDataDownload/?Mode=survey')

defra_page$doc


rating <- defra_page %>%
  html_nodes('map_graphics_layer') %>%
  html_text()
rating


html_session('https://environment.data.gov.uk/DefraDataDownload/?Mode=survey')


all_nodes <- defra_page %>%
  html_nodes("*")
