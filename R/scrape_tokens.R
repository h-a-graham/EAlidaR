#Notes:
# Okay - had some issues with the rsDriver set up. Problem seemed to be caused by an issue with JAVA paths:
# followed advice here: https://stackoverflow.com/questions/6362037/java-error-opening-registry-key
# Basically deleted the Oracle folder in 'C:\ProgramData\' and then reinstalled Java - now seems to work okay...

# The above is probably not an issue now if we use chrome. We can ask the user to provide a chrome version
# as discussed here: https://github.com/ropensci/RSelenium/issues/203 and then if they can select a version from:
# binman::list_versions("chromedriver") that best matches their chrome version...


# define chrome options
# devtools::install_github("ropensci/RSelenium")
# remotes::install_github("ropensci/wdman")

# alternative to Rselenium implicit time out: https://github.com/ropensci/RSelenium/issues/212
timeouts <- function (driver, milliseconds)
{
  qpath <- sprintf("%s/session/%s/timeouts", driver$serverURL,
                   driver$sessionInfo[["id"]])
  driver$queryRD(qpath, method = "POST", qdata = jsonlite::toJSON(list(type = "implicit", ms = milliseconds),
                                                                  auto_unbox = TRUE))
}

# function to wait max of 50s until loading screen disappears.
wait_for_load <- function(driver){
  start_time <- Sys.time()
    loading_el1  <- driver$findElement(using = 'css selector', '#dojox_widget_Standby_0 > img:nth-child(2)')
    while(isTRUE(loading_el1$isElementDisplayed()[[1]])){
      if (as.numeric(start_time-Sys.time())>50){
        stop('Time out on loading screen!')
      }
    }


}

# function to scrape arc tokens
scrape_token <- function(tile, chrome.version, remDr) {

  webElem <- remDr$findElement(using = 'css selector', "#fileid")

  #upload file
  webElem$sendKeysToElement(list(tile))



  wait_for_load(remDr)

  # click 'Get Tiles' button
  getTiles <- remDr$findElement(using = 'css selector', ".grid-item-container")
  getTiles$clickElement()

  wait_for_load(remDr)

  prodElem  <- remDr$findElement(using = 'css selector', '#productSelect')


  desiredProds <- c("LIDAR Composite DSM", "LIDAR Composite DTM", "LIDAR Point Cloud", "LIDAR Tiles DSM", "LIDAR Tiles DTM", "National LIDAR Programme DSM",
                    "National LIDAR Programme DTM", "National LIDAR Programme First Return DSM", "National LIDAR Programme Point Cloud" )

  prodList <- unique(prodElem$selectTag()$text)
  prodsIndex <- which(prodList %in% desiredProds)

  if (length(prodsIndex) == 0){
    message("No Data available for this tile...")
    arc_id <- 'NO_DATA'
  } else {

    xP <- paste0('//*[@id="productSelect"]/option[',prodsIndex[1],']')
    webElem <- remDr$findElement(using = 'xpath',
                                 value = xP)

    webElem$clickElement()
    webElem$getElementText()

    download_el <- remDr$findElement(using = 'css selector','.data-ready-container > a:nth-child(1)')
    down_link <- download_el$getElementAttribute("href")

    arc_id <- stringr::str_split(down_link, "/")[[1]][6]

  }

  reset_el <- remDr$findElement(using = 'css selector', 'div.result-options:nth-child(7) > input:nth-child(1)')
  reset_el$clickElement()
  return(arc_id)

}

# function to initiate the chrome driver with selenium.
start_selenium <- function(zipped_shps, chrome_v){
  eCaps <- list(chromeOptions = list(
    args = c(
      '--disable-gpu'
      ,'--headless',
      '--window-size=1280,800'
    )
  ))
  rD <- RSelenium::rsDriver(browser = "chrome",
                            chromever = chrome_v,
                            extraCapabilities = eCaps,
                            port =
                              as.integer(base::sample(seq(32768,65535, by=1),1)),
                            verbose = FALSE)


  # start the browser
  driver <- rD[["client"]]

  # set an implicit timeout of 20s
  timeouts(driver, 20000)

  driver$navigate("https://environment.data.gov.uk/DefraDataDownload/?Mode=survey")

  # map each group of 10 files to the scrape function.
  tokens <- zipped_shps %>%
    purrr::map(., ~scrape_token(tile = ., chrome.version = chrome_v, remDr = driver))

  driver$close()

  return(tokens)

}


compose_zip_paths <- function(save.folder, web.add){
  file.name <- basename(web.add)
  file.path(save.folder, file.name)
}


download_data <- function(web_url, dest_dir, os_tile_name, resolution, quiet=TRUE){
  dest_path <- compose_zip_paths(dest_dir, web_url)
    download.file(url=web_url, destfile=dest_path, method='auto', quiet = T) # change quiet to true after testing
    return(dest_path)

}

unzip_files <- function(dest_path){
  exp.fold <- tools::file_path_sans_ext(dest_path)
  zip::unzip(zipfile = dest_path, overwrite = TRUE, exdir = exp.fold)
  unlink(dest_path, recursive = TRUE, force=TRUE)
  dest_path <- exp.fold
  return(dest_path)
}


merge_ostiles <- function(ras.folder){
  ras.list <- list.files(ras.folder)
  ras.list <- purrr::discard(ras.list , grepl(".tif.xml|.tfw|index", ras.list ))

  ras.list <- lapply(ras.list, join_paths, p2=ras.folder)

  if (length(ras.list) > 1){
    ras.list <- lapply(ras.list, read_raster)
    ras.merge <- do.call(raster::merge, ras.list)
  } else if(length(ras.list) == 1){

    ras.merge <- raster::raster(file.path(ras.list[[1]]))

  }

  raster::crs(ras.merge)<- sp::CRS('+init=EPSG:27700')


  return(ras.merge)
}

get_data <- function(token_df, res, mod.type, save_dir, merge_Tiles, save_tile){

  arc_web_id <- token_df$arc_tokens[1]
  os.tile <- token_df$grid_name_5km[1]

  if (res == 1 || res == 2){
    res.str <- sprintf('%sM',res)
  } else if (res == 0.25 || res == 0.5){
    res_cm <- res * 100
    res.str <- sprintf('%sCM',res_cm)
  } else {
    stop('The resolution requested is not available options are: 0.25, 0.5, 1 and 2')
  }


  tile_data <- NULL
  if (mod.type == 'DTM'){
    if (res == 1){

      st_year <- 2020
      while(is.null(tile_data)){
        if (st_year == 2016) break;
        download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/NLP/National-LIDAR-Programme-DTM-%s-%s.zip', arc_web_id, st_year, os.tile)
        st_year <- st_year-1
        suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
      }
      if (is.null(tile_data)){
        download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DTM-%s-2019-%s.zip', arc_web_id, res.str, os.tile)
        suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
      }
    } else if (res == 2) {
      download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DTM-%s-2019-%s.zip', arc_web_id, res.str, os.tile)
      suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
    } else if (res == 0.25 || res == 0.5){
      download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DTM-%s-%s.zip', arc_web_id, res.str, os.tile)
      suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
    }
  } else if (mod.type == 'DSM') { # NEED TO ADD NLP DSM OPTION HERE...
    if (res == 1){
      st_year <- 2020
      while(is.null(tile_data)){
        if (st_year == 2016) break;
        download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/NLP/National-LIDAR-Programme-DSM-%s-%s.zip', arc_web_id, st_year, os.tile)
        st_year <- st_year-1
        suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
      }
      if (is.null(tile_data)){
        download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DSM-%s-%s.zip', arc_web_id, res.str, os.tile)
        suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
      }
    } else {
      download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DSM-%s-%s.zip', arc_web_id, res.str, os.tile)
      suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
    }
  }


  if(is.null(tile_data)){
    tile_data <- 'NO_DATA_RETURNED'
    return(tile_data)
  }

  dest_path <- (unzip_files(tile_data))

  if (isTRUE(merge_Tiles)){
    ras.obj <- merge_ostiles(dest_path)
    if (isTRUE(save_tile)){
      ras.obj <- raster::writeRaster(ras.obj, file.path(dest_folder, os_tile_name), format=ras_format, overwrite=TRUE, options = c("COMPRESS=LZW"))
      unlink(dest_path, recursive = TRUE, force=TRUE)
    }

    return(ras.obj)
  }

  options(warn = oldw)
  return(dest_path)

}



get_tiles <- function(tile_list10km, tile_list5km, chrome_ver, resolution, mod_type, merge_tiles, dest_folder, ras_format){

  if(!(mod_type == 'DTM' || mod_type == 'DSM')){
    stop('Only DTM and DSM model types are supported at present.')
  }

  if (missing(dest_folder)) {
    dest_folder <- tempdir()
    save.tile <- FALSE
  } else {
    save.tile <- TRUE
    if (isFALSE(is_absolute_path(dest_folder))){
      dest_folder <- normalizePath(file.path(dest_folder))
    }
  }

  if (missing(merge_tiles)){
    merge_tiles <- TRUE
  }

  if (missing(ras_format)){
    ras_format <- "GTiff"
  }

  rasformats <- raster::writeFormats()[,1]
  if (!(ras_format %in% rasformats)){
    stop('Requested Raster format not supported. Use raster::writeFormats() to view supported drivers')
  }

  temp_shp_dir <- tempdir()
  temp_ras_dir <- tempdir()
  #chunk tiles in to groups no more than 10
  zip_shp_list <- tile_list10km %>%
    create_zip_tiles(., temp_shp_dir) %>%
    split(., ceiling(seq_along(.)/10))


  arc_tokens <- zip_shp_list %>%
    purrr::map(., ~ start_selenium(zipped_shps = ., chrome_v = chrome_ver))

  token_df <- tibble::as_tibble(tile_list10km) %>%
    dplyr::rename(grid_name10km = value) %>%
    dplyr::bind_cols(tibble::as_tibble(unlist(purrr::map(arc_tokens, ~unlist(.))))) %>%
    dplyr::rename(arc_tokens = value)

  rasters <- tibble::as_tibble(tile_list5km) %>%
    dplyr::rename(grid_name_5km = value) %>%
    dplyr::mutate(grid_name10km = substr(grid_name_5km,1,4)) %>%
    dplyr::left_join(., token_df, by = "grid_name10km") %>%
    dplyr::mutate(id = dplyr::row_number()) %>%
    dplyr::group_by(id) %>%
    dplyr::group_split() %>%
    purrr::map(., ~ get_data(., res=resolution, mod.type=mod_type, save_dir=temp_ras_dir, merge_Tiles = merge_tiles, save_tile = save.tile ))

  return(rasters)

}

