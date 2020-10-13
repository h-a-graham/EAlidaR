
#' @importFrom magrittr %>%


string_match <- function(string){
  as.integer(stringr::str_match(string, 'Tile_\\s*(.*?)\\s*.zip')[,2])
}


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
  tile_glob <- Sys.glob(file.path('data/grid_shp_zip/Tile_*.zip'))%>%
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
  reticulate::source_python("python/EA_scrape_functions.py")
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



#' @export
check_tiles <- function(.scrape_out){

  grid_sf <- sf::read_sf('data/10km_Grid_LiDAR_inter.gpkg') %>%
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



#' @export
save_arc_IDs <- function(scrape.obj){
# option to save scrape objectect (including error log - allowing for repeat runs)
save_path <- file.path('data/arc_ids_10km.rds')
saveRDS(scrape.obj, file = save_path)
# return(readRDS(save_path))
}


scrape_to_sf <- function(scrape.obj){


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

  save_path <- file.path('data/coverage_10km_sf.rds')
  saveRDS(grid_sf, file = save_path)

  return(list(cover_plot = coverage_plot, cover_sf = readRDS(save_path)))
}



