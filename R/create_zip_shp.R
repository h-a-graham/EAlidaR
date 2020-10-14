# create unique zipped shp files for all tiles to upload to the arc portal and retrieve unique ids...
# These files will be used in working/scrape_arc_ids.R to generate a tibble of grids and their respective
# IDs to use as input for the download url links.

#' @importFrom magrittr %>%

zip_shp <- function(.val, .path, .sfObj){
  feature <- .val %>%
    sf::st_sfc()%>%
    sf::st_set_crs(sf::st_crs(.sfObj)) %>%
    sf::st_buffer(-500)

  cell.name <- feature %>%
    sf::st_intersection(.sfObj, .) %>%
    dplyr::pull(grid_id)

  sf::write_sf(feature, file.path(.path, stringr::str_c(cell.name, '.shp')))
  filelist <- Sys.glob(file.path(.path, stringr::str_c(cell.name, '*')))
  zip::zipr(file.path(.path, stringr::str_c('Tile_',cell.name, '.zip')), files = filelist)
  purrr::map(filelist, file.remove)
}


#' Generate Zipped ESRI shapefiles (.shp) for all 10km OS grids that intersect any lidar data
#'
#' This function should not be required by the user. It generates the numerous >1500 zipped shp files that need to be uploaded
#' to the DEFRA portal in order to scrape the Arc Web IDs in scrape_tile_IDs().
#'
#' @return A list the zipped paths.
#' @export
create_zip_tiles <- function(){
  datadirec <- system.file('data', package = "EAlidaR")
  direc <- file.path(datadirec, 'grid_shp_zip')
  dir.create(direc, showWarnings = FALSE)

  grid_10km.path <- system.file('data', '10km_Grid_LiDAR_inter.gpkg', package = "EAlidaR")

  grid_10km <- sf::read_sf(grid_10km.path) %>%
    dplyr::select(grid_id, geom)

  sf::st_geometry(grid_10km)%>%
    purrr::map(~ zip_shp(.val = ., .path = direc, .sfObj = grid_10km))

}

