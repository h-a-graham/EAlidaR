library(raster)
library(ggplot2)
library(ggspatial)
source("./R/get_lidar.R")


save_folder <- 'C:/HG_Projects/SideProjects/EA_Lidar_Check/EA_Download_TEST'

rasOB <- get_tile(resolution = 2, os.tile.name = 'SX69se', dest.folder = save_folder, save.tile=TRUE)


ggplot() +
  # loads background map tiles from a tile source - rosm::osm.types() for osm options
  annotation_map_tile(type = "osm", zoomin = -1) +

  # raster layers train scales and get projected automatically
  layer_spatial(rasOB, aes(colour = stat(band1)), alpha = 0.5) +
  # make no data values transparent
  scale_fill_viridis_c(na.value = NA) +

  # spatial-aware automagic scale bar
  annotation_scale(location = "tl") +

  # spatial-aware automagic north arrow
  annotation_north_arrow(location = "br", which_north = "true") +
  theme_bw() +
  labs(fill='Elevation (m)')

ggsave('C:/HG_Projects/SideProjects/EA_Lidar_Check/maps/SX69se.jpg')
