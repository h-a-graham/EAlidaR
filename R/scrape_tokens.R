
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
    message(sprintf("No Data available for: %s", stringr::str_sub(basename(tile),1, -5)))
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
start_selenium <- function(zipped_shps, chrome_v, headless, check_s){
  eCaps <- list(chromeOptions = list(
    args = c("--disable-gpu",
             "--window-size=1920,1200",
             "--ignore-certificate-errors",
             "--disable-extensions",
             "--no-sandbox",
             "--disable-dev-shm-usage"
    )
  ))

  if (isTRUE(headless)){
    eCaps$chromeOptions$args <- c("--headless", eCaps$chromeOptions$args)
  }

  rD <- RSelenium::rsDriver(browser = "chrome",
                            chromever = chrome_v,
                            extraCapabilities = eCaps,
                            port =
                              as.integer(base::sample(seq(32768,65535, by=1),1)),
                            verbose = FALSE, geckover=NULL, iedrver=NULL,
                            phantomver=NULL, check=check_s)


  # start the browser
  driver <- rD[["client"]]

  # set an implicit timeout of 20s
  timeouts(driver, 30000)

  driver$navigate("https://environment.data.gov.uk/DefraDataDownload/?Mode=survey")

  # map each group of 10 files to the scrape function.
  tokens <- zipped_shps %>%
    purrr::map(., ~scrape_token(tile = ., chrome.version = chrome_v, remDr = driver))

  driver$close()
  rD$server$stop()

  return(tokens)

}


compose_zip_paths <- function(save.folder, web.add){
  file.name <- basename(web.add)
  file.path(save.folder, file.name)
}


download_data <- function(web_url, dest_dir, os_tile_name, resolution, quiet=TRUE){
  dest_path <- compose_zip_paths(dest_dir, web_url)
  download.file(url=web_url, destfile=dest_path, method='auto', quiet = T)
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
  # functions required for tile merging...
  read_raster <- function(ras.path){
    suppressWarnings(ras <- raster::raster(ras.path))
    suppressWarnings(raster::crs(ras) <- sf::st_crs(27700)$wkt)
    return(ras)
  }

  join_paths <- function(p1, p2){
    file.path(p2, p1)
  }

  ras.list <- list.files(ras.folder) %>%
    purrr::discard(. , grepl(".tif.xml|.tfw|index|lidar_used_in_merging_process",
                             . )) %>%
    lapply(., join_paths, p2=ras.folder)

  if (length(ras.list) > 1){
    ras.list <- lapply(ras.list, read_raster)
    suppressWarnings(ras.merge <- do.call(raster::merge, ras.list))
  } else if(length(ras.list) == 1){
    suppressWarnings(ras.merge <- raster::raster(file.path(ras.list[[1]])))
  }
  suppressWarnings(raster::crs(ras.merge)<- sf::st_crs(27700)$wkt)

  return(ras.merge)
}

get_data <- function(token_df, res, mod.type, save_dir){

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
      if (is.null(tile_data)){
        download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DTM-%s-2020-%s.zip', arc_web_id, res.str, os.tile)
        suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
      }
      st_year <- 2020
      while(is.null(tile_data)){
        if (st_year == 2016) break;
        download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/NLP/National-LIDAR-Programme-DTM-%s-%s.zip', arc_web_id, st_year, os.tile)
        st_year <- st_year-1
        suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
      }

    } else if (res == 2) {
      download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DTM-%s-2020-%s.zip', arc_web_id, res.str, os.tile)
      suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
    } else if (res == 0.25 || res == 0.5){
      download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DTM-%s-%s.zip', arc_web_id, res.str, os.tile)
      suppressWarnings(try(tile_data <- download_data(web_url=download_url, dest_dir=save_dir, os_tile_name=os.tile, resolution=res), silent=TRUE))
    }
  } else if (mod.type == 'DSM') {
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
    stop(os.tile)
  }

  dest_path <- (unzip_files(tile_data))

  ras.obj <- merge_ostiles(dest_path)

  ras.obj@title <- os.tile

  return(ras.obj)
}



get_tiles <- function(tile_list10km, tile_list5km, chrome_ver, resolution,
                      mod_type, merge_tiles = TRUE, ras_format = "GTiff",
                      headless_chrome, check_selenium){


  dest_folder <- tempdir()

  temp_shp_dir <- tempdir()
  temp_ras_dir <- tempdir()
  #chunk tiles in to groups no more than 10
  zip_shp_list <- tile_list10km %>%
    create_zip_tiles(., temp_shp_dir) %>%
    split(., ceiling(seq_along(.)/10))

  message('Scraping web portal tile tokens...')
  arc_tokens <- zip_shp_list %>%
    purrr::map(., ~ start_selenium(zipped_shps = ., chrome_v = chrome_ver, headless = headless_chrome, check_s=check_selenium))

  token_df <- tibble::as_tibble(tile_list10km) %>%
    dplyr::rename(grid_name10km = value) %>%
    dplyr::bind_cols(tibble::as_tibble(unlist(purrr::map(arc_tokens, ~unlist(.))))) %>%
    dplyr::rename(arc_tokens = value)

  # set up progress bar for download
  pb <- progress::progress_bar$new(total = length(tile_list5km), clear = FALSE)

  # function to control download safely - logging errors
  collect_data_safe <- function(x) {
    f = purrr::safely(function() get_data(token_df = x, res=resolution, mod.type=mod_type, save_dir=temp_ras_dir))
    pb$tick()
    f()
  }

  # prep dataframe and map tile download function
  message('Downloading tiles...')
  rasters <- tibble::as_tibble(tile_list5km) %>%
    dplyr::rename(grid_name_5km = value) %>%
    dplyr::mutate(grid_name10km = substr(grid_name_5km,1,4)) %>%
    dplyr::left_join(., token_df, by = "grid_name10km") %>%
    dplyr::mutate(id = dplyr::row_number()) %>%
    dplyr::group_by(id) %>%
    dplyr::group_split() %>%
    purrr::map(., ~ collect_data_safe(.))

  return(rasters)

}

