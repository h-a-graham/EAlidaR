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

#' @export
create_zip_tiles <- function(){
direc <- file.path('data/grid_shp_zip')
dir.create(direc, showWarnings = FALSE)

grid_5km.path <- 'data/5km_Grid_LiDAR_inter.gpkg'

grid_5km <- sf::read_sf(grid_5km.path) %>%
  dplyr::select(grid_id, geom)

sf::st_geometry(grid_5km)%>%
  purrr::map(~ zip_shp(.val = ., .path = direc, .sfObj = grid_5km))

}
