
#' @importFrom magrittr %>%

#' @export
scrape_tile_IDs <- function(conda_path, env_name, gecko_exe){
  options(warn=1)

  warning("This function shouldn't be necessary aslo it takes a long time, will prevent the use of your machine during the run,
  requires reticulate and an associated conda environment with the following packages installed: selenium, pyautogui, pandas")

  question1 <- readline("Are you sure you want to run this? (Y/N)")

  if(regexpr(question1, 'y', ignore.case = TRUE) == 1){
    print("Running 'scrape_tile_IDs' - this may take a while...")
  }else{
    print("Execution of 'scrape_tile_IDs' cancelled")
    return()
  }


  #set up python...
  reticulate::use_condaenv(condaenv =conda_path, env_name, required = TRUE)

  # Source python functions...
  reticulate::source_python("python/EA_scrape_functions.py")
  py_out <- scrapestuff(gecko_exe, work_dir=getwd())

  # organise outputs from python as list
  py_returns <- list(arc_ids= py_out[[1]], error_log = py_out[[2]])

  return(py_returns)

}



#' @export
check_tiles <- function(.scrape_out){

  grid_sf <- sf::read_sf('data/5km_Grid_LiDAR_inter.gpkg') %>%
    # tibble::rownames_to_column(var = "grid_id") %>%
    dplyr::mutate(grid_id = as.numeric(grid_id))%>%
    dplyr::left_join(., .scrape_out$arc_ids, by = c("grid_id"= "tile_n")) %>%
    dplyr::mutate(Retrieved = ifelse(is.na(arc_code), "False", "True"))%>%
    dplyr::mutate(Retrieved = forcats::fct_relevel(Retrieved, 'True'))


  n_return <- nrow(dplyr::filter(grid_sf, Retrieved == 'True'))
  n_tot <- nrow(grid_sf)
  perc_ret <- round(n_return/n_tot*100, 2)

  t_plot <- ggplot2::ggplot() +
    # loads background map tiles from a tile source - rosm::osm.types() for osm options
    ggspatial::annotation_map_tile(type = "cartolight", zoomin = -1, ) +

    # raster layers train scales and get projected automatically
    ggspatial::layer_spatial(grid_sf, ggplot2::aes(fill = Retrieved), alpha = 0.5, colour="#BAC0BC")+

    ggplot2::scale_fill_manual(values=c("#49F585", "#BAC0BC")) +

    ggplot2::coord_sf(crs = 27700, datum = sf::st_crs(27700)) +

    ggplot2::labs(subtitle = stringr::str_c('n tile codes returned = ',n_return, '/', n_tot,' (', perc_ret, '%)'))

  missing_tiles <- as.data.frame(grid_sf) %>%
    dplyr::filter(is.na(arc_code)) %>%
    dplyr::select(-c(geom, arc_code))

  return(list(tile_plot = t_plot, missing_tile_df = missing_tiles))

}



#' @export
save_arc_IDs <- function(.dataframe){
# convert the pandas DF object to R DF and save as RDS
r_df <- reticulate::py$arc_id_df
save_path <- file.path(wd, 'data', 'arc_ids_5km.rds')
saveRDS(r_df, file = save_path)
return(readRDS(save_path))
}






