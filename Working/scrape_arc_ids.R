library(tidyverse)
library(rvest)
# library(splashr)
# library(stevedore)
# library(reticulate)
# library(wdman)


library(RSelenium)



#### Running  from powershell Docker:
# docker pull selenium/standalone-firefox
# docker run -d -p 4445:4444 selenium/standalone-firefox

# docker run -d  -v vm_share:C:/HG_Projects/EAlidaR/data/grid_shp_zip -p 4445:4444 selenium/standalone-firefox


# If using windows run this in the cmd.exe  to retrieve the IP address - more than one may be returned so try them out to
# find a working one...
# for /f "tokens=2 delims=:" %i  in ('ipconfig ^| findstr "IPv4" ^| findstr [0-9]') do echo %i

# 192.168.1.67


remDr <- remoteDriver(remoteServerAddr = "192.168.1.67",port = 4445L)
remDr$open()



link <- 'https://environment.data.gov.uk/DefraDataDownload/?Mode=survey'
test_tile <- tools::file_path_as_absolute(file.path('data/grid_shp_zip/Tile_10.zip'))
js_path <- tools::file_path_as_absolute(file.path('javascript/drag_and_drop_helper.js'))


#naviate to page
remDr$navigate(link)
remDr$getTitle() # check page title

# selects drag and drop area...
webElem <- remDr$findElement(using = "css", value = '.drop-area')
webElem$getElementAttribute("class")

#selects upload button
webElem <- remDr$findElement(using = "css", value = '#buttonid')
webElem$getElementAttribute("type")
# webElem$executeScript("document.addEventListener('click',function handler(event){if(event.target.type==='file')event.preventDefault()},true)")
webElem$executeScript("document.getElementById('iconFlagFile').style.display = 'block';")

webElem$clickElement()
webElem$sendKeysToElement(list(test_tile))

webElem$isElementSelected()

remDr$getActiveElement()
Sys.sleep(time=10)
webElem$screenshot(display = TRUE, useViewer = TRUE, file = NULL)

webElem$switchToWindow(windowId=NULL)
#
# webElem$sendKeysToActiveElement(list(test_tile))



webElem2 <- remDr$findElement(using = "xpath", '//*[@id="widgets_DefraDataClip_Widget_19"]/div[3]/div[2]/div[3]/div/div[1]/div/div/div/div')
# webElem$getElementAttribute("type")
webElem$clickElement()

webElem <- remDr$findElement(using = "xpath", '//*[@id="widgets_DefraDataClip_Widget_19"]/div[4]/div[2]/div[4]/div[2]')

remDr$getCurrentUrl()


webElem3 <- remDr$findElement(using = "class", value='data-ready-container')
webElem2$getElementAttribute("id")
webElem2$clickElement()

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
