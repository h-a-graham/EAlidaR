# create unique zipped shp files for all tiles to upload to the arc portal and retrieve unique ids...
# These files will be used in working/scrape_arc_ids.R to generate a tibble of grids and their respective
# IDs to use as input for the download url links.

zip_shp <- function(.val, .path, .sfObj){
  feature <- .val %>%
    sf::st_sfc()%>%
    sf::st_set_crs(sf::st_crs(.sfObj)) %>%
    sf::st_buffer(-500)

  cell.name <- feature %>%
    sf::st_intersection(.sfObj, .) %>%
    dplyr::pull(TILE_NAME)

  sf::write_sf(feature, file.path(.path, stringr::str_c(cell.name, '.shp')))
  filelist <- Sys.glob(file.path(.path, stringr::str_c(cell.name, '*')))

  zip_path <- file.path(.path, stringr::str_c('Tile_',cell.name, '.zip'))
  zip::zipr(zip_path, files = filelist)

  purrr::map(filelist, file.remove)

  return(zip_path)
}


# Generate Zipped ESRI shapefiles (.shp) for all 10km OS grids that intersect any lidar data
create_zip_tiles <- function(tile_names, out_path){
  oldw <- getOption("warn")
  options(warn = -1)
  datadirec <- system.file('data', package = "EAlidaR")
  # direc <- file.path(out_path, 'grid_shp_zip')
  # dir.create(direc, showWarnings = FALSE)

  grid_10km <- grid_10km_sf %>%
    dplyr::filter(TILE_NAME %in% tile_names )

  shp_list <- sf::st_geometry(grid_10km)%>%
    purrr::map(~ zip_shp(.val = ., .path = out_path, .sfObj = grid_10km))
  options(warn = oldw)
  return(shp_list)
}

