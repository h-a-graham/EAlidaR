
#' @importFrom magrittr %>%


string_match <- function(string){
  as.integer(stringr::str_match(string, 'Tile_\\s*(.*?)\\s*.zip')[,2])
}

#' Scrape Arc Web Map object IDs for 10km OS tiles using python Selenium WebDriver
#'
#' This function should not be required by the user. It is here for completeness given the development state of this package.
#' It uses the reticulate package to run Python's selenium webdriver module and upload the zipped shape files produced in create_zip_tiles.
#' Python and resticulate are not required to run the downlaod functions of this package. required python packages are: Selenium, pyautgui and pandas.
#' everything seems to work well when istalled from the conda forge channel. Whilst I have limited this execution to conda only it could be adapted to
#' other python set ups but why would you not just use conda ;)
#'
#' @param conda_path A character string for the filepath to the appropriate Conda environment.
#' @param env_name character - the name of that conda environment.
#' @param gecko_exe file path to the gecko executable - download from here: \url{https://github.com/mozilla/geckodriver/releases}
#' @param previous This function never works first time for many reasons so this allows for the inclusion of outputs from previous attempts so
#' they don't need to be re run.
#' @return A named list containing two data frames $error_log and $arc_ids.
#' @export
scrape_tile_IDs <- function(conda_path, env_name, gecko_exe, previous){
  options(warn=1)

  #  Warning section to make sure the user doesn't run function unless required...
  warning("This function shouldn't be necessary aslo it takes a long time, will prevent the use of your machine during the run,
  requires reticulate and an associated conda environment with the following packages installed: selenium, pyautogui, pandas")

  question1 <- readline("Are you sure you want to run this? (Y/N)")

  if(regexpr(question1, 'y', ignore.case = TRUE) == 1){
    message("Running 'scrape_tile_IDs' - this may take a while...")
  }else{
    message("Execution of 'scrape_tile_IDs' cancelled")
    return()
  }

  # section to select tiles to run - removing previously completed tiles where supplied....
  if (missing(previous)){
    previous <- NULL
  }

  #create glob here:
  glob_fold <- system.file('data', 'grid_shp_zip', package = "EAlidaR")

  tile_glob <- Sys.glob(file.path(glob_fold, 'Tile_*.zip'))%>%
    purrr::map(., normalizePath)

  if (!is.null(previous) == TRUE){
    # remove successful tiles from glob

    print("previously completed tiles supplied - run for remaining...")

    fin_list <- list(previous$arc_ids$tile_n)

    tile_n_list <- purrr::map(tile_glob, string_match) %>%
      unlist() %>%
      list()

    match1 <- match(tile_n_list[[1]], fin_list[[1]])

    match2 <- which(match1 %in% NA)

    length(match2)

    tile_glob <- tile_glob[match2]

  }

  #set up python...
  reticulate::use_condaenv(condaenv =conda_path, env_name, required = TRUE) # add glob as arg...

  # Source python functions...
  pyscript <- system.file('python', 'EA_scrape_functions.py', package = "EAlidaR")
  reticulate::source_python(pyscript)
  py_out <- scrapestuff(gecko_exe, tile_glob)

  if (!is.null(previous) == TRUE){
    arc_id_df <- dplyr::bind_rows(previous$arc_ids, py_out[[1]])
  } else{
    arc_id_df <- py_out[[1]]
  }

  # organise outputs from python as list
  py_returns <- list(arc_ids= arc_id_df, error_log = py_out[[2]])

  return(py_returns)

}


#' Check the coverage of Arc Web IDs retrieved from scrape_tile_IDs()
#'
#' This function should not be required by the user. It plots the coverage of tiles IDs retrieved.
#'
#' @param .scrape_out The object produced from scrape_tile_IDs()
#' @return A named list containing $tile_plot - a ggplot object and $missing_tile_df a data frame of missing tiles.
#' @export
check_tiles <- function(.scrape_out){

  # gridpath <- system.file('data', '10km_Grid_LiDAR_inter.gpkg', package = "EAlidaR")

  grid_sf <- km10_Grid_LiDAR_inter %>%
    # tibble::rownames_to_column(var = "grid_id") %>%
    dplyr::mutate(grid_id = as.numeric(grid_id))%>%
    dplyr::left_join(., .scrape_out$arc_ids, by = c("grid_id"= "tile_n")) %>%
    dplyr::mutate(Retrieved = ifelse(is.na(arc_code), "False", "True"))%>%
    dplyr::mutate(Retrieved = ifelse(arc_code=='NO_DTM_COMP', "No 2019 Data", Retrieved))%>%
    dplyr::mutate(Retrieved = forcats::fct_relevel(Retrieved, 'True'))

  n_nodata <- nrow(dplyr::filter(grid_sf, Retrieved == 'No 2019 Data' ))
  n_return <- nrow(dplyr::filter(grid_sf, Retrieved != 'False' )) - n_nodata
  n_tot <- nrow(grid_sf) - n_nodata
  perc_ret <- round(n_return/n_tot*100, 2)

  t_plot <- ggplot2::ggplot() +
    # loads background map tiles from a tile source - rosm::osm.types() for osm options
    ggspatial::annotation_map_tile(type = "cartolight", zoomin = -1, ) +

    # raster layers train scales and get projected automatically
    ggspatial::layer_spatial(grid_sf, ggplot2::aes(fill = Retrieved), alpha = 0.5, colour="#BAC0BC")+

    ggplot2::scale_fill_manual(values=c("#49F585", "#BAC0BC", '#EA6337')) +

    ggplot2::coord_sf(crs = 27700, datum = sf::st_crs(27700)) +

    ggplot2::labs(subtitle = stringr::str_c('n tile codes returned = ',n_return, '/', n_tot,' (', perc_ret, '%)'))

  missing_tiles <- as.data.frame(grid_sf) %>%
    dplyr::filter(is.na(arc_code)) %>%
    dplyr::select(-c(geom, arc_code))

  return(list(tile_plot = t_plot, missing_tile_df = missing_tiles))

}



#' Save the output of scrape_tile_IDs()
#'
#' This function should not be required by the user. It saves the scrape_tile_IDs() in case you need to pick it up again later...
#'
#' @param scrape.obj The object produced from scrape_tile_IDs()
#' @param out.path the save path for the file - use a .rds extension
#' @export
save_arc_IDs <- function(scrape.obj, out.path){
save_path <- paste(tools::file_path_sans_ext(out.path), '.rds',sep="")
saveRDS(scrape.obj, file = save_path)
}

#' Save the output of scrape_tile_IDs()
#'
#' This function should not be required by the user. When all tile IDs have been retrieved the results are saved as an sf object.
#' This object will then be used in download function to carry out spatial joins. Also provides a plot denoting the coverage that is
#' available.
#'
#' @param scrape.obj The object produced from scrape_tile_IDs()
#' @param out.path the save path for the file - use a .rds extension
#' @return named list containing $coverplot a ggplot object and $cover_sf the sf object with joined arc ID values.
#' @export
scrape_to_sf <- function(scrape.obj, out.path){


  arc_id_df <- scrape.obj$arc_ids %>%
    dplyr::filter(arc_code != 'False' | arc_code != 'No 2019 Data')

  grid_sf <- sf::read_sf('data/10km_Grid_LiDAR_inter.gpkg') %>%
    dplyr::right_join(., arc_id_df, by = c("grid_id"= "tile_n"))

  coverage_plot <- ggplot2::ggplot() +
    # loads background map tiles from a tile source - rosm::osm.types() for osm options
    ggspatial::annotation_map_tile(type = "cartolight", zoomin = -1, ) +

    # raster layers train scales and get projected automatically
    ggspatial::layer_spatial(grid_sf, ggplot2::aes(fill = Retrieved), alpha = 0.5, fill = '#366BF7', colour="#BAC0BC")+

    ggplot2::coord_sf(crs = 27700, datum = sf::st_crs(27700)) +

    ggplot2::labs(subtitle = stringr::str_c('10km Tile Coverage'))

  # save_path <- system.file('data', 'coverage_10km_sf.rds', package = "EAlidaR")
  save_path <- paste(tools::file_path_sans_ext(out.path), '.rds',sep="")

  saveRDS(grid_sf, file = save_path)

  return(list(cover_plot = coverage_plot, cover_sf = readRDS(save_path)))
}



