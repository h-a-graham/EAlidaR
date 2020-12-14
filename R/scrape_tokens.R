#Notes:
# Okay - had some issues with the rsDriver set up. Problem seemed to be caused by an issue with JAVA paths:
# followed advice here: https://stackoverflow.com/questions/6362037/java-error-opening-registry-key
# Basically deleted the Oracle folder in 'C:\ProgramData\' and then reinstalled Java - now seems to work okay...


# define chrome options
# devtools::install_github("ropensci/RSelenium")
# remotes::install_github("ropensci/wdman")

# library(RSelenium)

# alternative to Rselenium implicit time out: https://github.com/ropensci/RSelenium/issues/212
timeouts <- function (driver, milliseconds)
{
  qpath <- sprintf("%s/session/%s/timeouts", driver$serverURL,
                   driver$sessionInfo[["id"]])
  driver$queryRD(qpath, method = "POST", qdata = jsonlite::toJSON(list(type = "implicit", ms = milliseconds),
                                                                  auto_unbox = TRUE))
}


scrape_token <- function(tile, chrome.version) {

  eCaps <- list(chromeOptions = list(
    args = c(
      '--disable-gpu'
      ,'--headless',
      '--window-size=1280,800'
    )
  ))
  rD <- RSelenium::rsDriver(browser = "chrome",
                            chromever = chrome.version,
                            extraCapabilities = eCaps,
                            port =
                              as.integer(base::sample(seq(32768,65535, by=1),1)),
                            verbose = FALSE)



  remDr <- rD[["client"]]



  timeouts(remDr, 20000)


  remDr$navigate("https://environment.data.gov.uk/DefraDataDownload/?Mode=survey")


  webElem <- remDr$findElement(using = 'css selector', "#fileid")

  #upload file
  webElem$sendKeysToElement(list(tile))

  wait_for_load <- function(){
    loading_el1  <- remDr$findElement(using = 'css selector', '#dojox_widget_Standby_0 > img:nth-child(2)')
    while(isTRUE(loading_el1$isElementDisplayed()[[1]])){}
  }

  wait_for_load()

  # click 'Get Tiles' button
  getTiles <- remDr$findElement(using = 'css selector', ".grid-item-container")
  getTiles$clickElement()

  wait_for_load()

  prodElem  <- remDr$findElement(using = 'css selector', '#productSelect')


  desiredProds <- c("LIDAR Composite DSM", "LIDAR Composite DTM", "LIDAR Point Cloud", "LIDAR Tiles DSM", "LIDAR Tiles DTM", "National LIDAR Programme DSM",
                    "National LIDAR Programme DTM", "National LIDAR Programme First Return DSM", "National LIDAR Programme Point Cloud" )

  prodList <- unique(prodElem$selectTag()$text)
  prodsIndex <- which(prodList %in% desiredProds)

  if (length(prodsIndex) == 0){
    message("No Data available for this tile...")
  } else {

    select_item <- function(item_num){
      xP <- paste0('//*[@id="productSelect"]/option[',item_num,']')
      webElem <- remDr$findElement(using = 'xpath',
                                   value = xP)
    }
    webElem <- select_item(prodsIndex[1])
    webElem$clickElement()
    webElem$getElementText()

    download_el <- remDr$findElement(using = 'css selector','.data-ready-container > a:nth-child(1)')
    down_link <- download_el$getElementAttribute("href")

    arc_id <- stringr::str_split(down_link, "/")[[1]][6]


  }

  remDr$close()

  return(arc_id)

}


id <- scrape_token('C:\\HG_Projects\\EAlidaR\\data-raw\\grid_shp_zip_test\\Tile_1.zip', "87.0.4280.88")

id

# remDr$screenshot(display = TRUE)
#
#
# # nice idea for waiting for element...
# webElem <-NULL
# while(is.null(webElem)){
#   webElem <- tryCatch({remDr$findElement(using = 'name', value = "<value>")},
#                       error = function(e){NULL})
#   #loop until element with name <value> is found in <webpage url>
# }
#
#
#
#
# remDr$close()

