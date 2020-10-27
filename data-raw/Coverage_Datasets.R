
devtools::load_all()
library(sf)
library(ggplot2)
library(ggspatial)
library(dplyr)
library(magrittr)

Coverage_gpkg <- system.file("extdata", "LiDAR_extents.gpkg", package = "EAlidaR")
grid50km <- read_sf(system.file("data-raw", "50km_grid.gpkg", package = "EAlidaR"))


lidar_25cm <- read_sf(Coverage_gpkg, layer='LiDAR_extent_25cm') %>%
  st_join(grid50km) %>%
  group_by(TILE_NAME)%>%
  summarise()%>%
  select(geom)


lidar_50cm <- read_sf(Coverage_gpkg, layer='LiDAR_extent_50cm') %>%
  st_join(grid50km) %>%
  group_by(TILE_NAME)%>%
  summarise()%>%
  select(geom)

lidar_1m <- read_sf(Coverage_gpkg, layer='LiDAR_extent_1m') %>%
  st_join(grid50km) %>%
  group_by(TILE_NAME)%>%
  summarise()%>%
  select(geom)

lidar_2m <- read_sf(Coverage_gpkg, layer='LiDAR_extent_2m') %>%
  st_join(grid50km) %>%
  group_by(TILE_NAME)%>%
  summarise()%>%
  select(geom)

lidar_1m_DSM <- read_sf(Coverage_gpkg, layer='LiDAR_extent_DSM') %>%
  filter(resolution != 2)%>%
  st_join(grid50km) %>%
  group_by(TILE_NAME)%>%
  summarise()%>%
  select(geom)

object.size(lidar_1m_DSM)


lidar_2m_DSM <- read_sf(Coverage_gpkg, layer='LiDAR_extent_DSM') %>%
  st_join(grid50km) %>%
  group_by(TILE_NAME)%>%
  summarise()%>%
  select(geom)

object.size(lidar_2m_DSM)


usethis::use_data(lidar_25cm, overwrite = TRUE)
usethis::use_data(lidar_50cm, overwrite = TRUE)
usethis::use_data(lidar_1m, overwrite = TRUE)
usethis::use_data(lidar_2m, overwrite = TRUE)
usethis::use_data(lidar_1m_DSM, overwrite = TRUE)
usethis::use_data(lidar_2m_DSM, overwrite = TRUE)


# check datesets with plots...
show_cover <-  function(sf_obj) {
  ggplot() +
    annotation_map_tile(type = "cartolight", zoomin = -1, ) +
    layer_spatial(sf_obj, alpha = 0.8, fill = '#FF5733', colour="#FF5733")+
    ggplot2::coord_sf(crs = 27700, datum = sf::st_crs(27700)) +
    theme_bw()

}

show_cover(lidar_25cm)
show_cover(lidar_50cm)
show_cover(lidar_1m)
show_cover(lidar_2m)
show_cover(lidar_1m_DSM)
show_cover(lidar_2m_DSM)
