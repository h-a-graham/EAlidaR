library(tidyverse)
library(rvest)
library(splashr)
library(stevedore)
library(reticulate)

library(RSelenium)
library(wdman)

selServ <- selenium(verbose = FALSE)
selServ$process

rD <- rsDriver()


use_condaenv(condaenv = "reticulate_env", conda = file.path('C:/Users/hg340/AppData/Local/Continuum/miniconda3'))
install_splash()
splash_container <- start_splash()











defra_page <- read_html('https://environment.data.gov.uk/DefraDataDownload/?Mode=survey')

defra_page$doc


rating <- defra_page %>%
  html_nodes('map_graphics_layer') %>%
  html_text()
rating


html_session('https://environment.data.gov.uk/DefraDataDownload/?Mode=survey')


all_nodes <- defra_page %>%
  html_nodes("*")
