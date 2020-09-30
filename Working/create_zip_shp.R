# create unique zipped shp files for all tiles to upload to the arc portal and retrieve unique ids...
# These files will be used in working/scrape_arc_ids.R to generate a tibble of grids and their respective
# IDs to use as input for the download url links.

direc <- file.path('data/grid_shp_zip')
dir.create(direc, showWarnings = FALSE)

grid_25km.path <- 'data/OSGB_ENG_Grid_25km_.gpkg'

grid_25km <- sf::read_sf(grid_25km.path) %>%
  tibble::rownames_to_column(var = "grid_id") %>%
  select(grid_id, geom)

ggplot2::ggplot(grid_25km, aes(fill=grid_id)) +
  geom_sf(alpha = 0.6) +
  coord_sf(datum = st_crs(grid_25km))+
  theme_bw()+
  guides(fill=FALSE)

zip_shp <- function(.val, .path){
  feature <- .val %>%
    sf::st_sfc()%>%
    sf::st_set_crs(st_crs(grid_25km)) %>%
    sf::st_buffer(-500)

  cell.name <- feature %>%
    sf::st_intersection(grid_25km, .) %>%
    dplyr::pull(grid_id)

  sf::write_sf(feature, file.path(.path, str_c(cell.name, '.shp')))
  filelist = Sys.glob(file.path(.path, str_c(cell.name, '*')))
  zip::zipr(file.path(.path, str_c('Tile_',cell.name, '.zip')), files = filelist)
  purrr::map(filelist, file.remove)
}

st_geometry(grid_25km)%>%
  purrr::map(~ zip_shp(.val = ., .path = direc))



