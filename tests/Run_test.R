# library(EAlidaR)
library(ggplot2)
library(ggspatial)

devtools::document()

devtools::load_all()

save_folder <- 'C:/HG_Projects/SideProjects/EALidarCheck/EADownloadTEST'

rasOB <- get_tile(resolution = 2, model.type = 'DTM' , os.tile.name = 'SU66nw', dest.folder = save_folder)
rasOB2 <- get_tile(resolution = 2, model.type = 'DSM' , os.tile.name = 'SK36ne')

ggplot() +
  # loads background map tiles from a tile source - rosm::osm.types() for osm options
  annotation_map_tile(type = "hillshade", zoomin = -1) +

  # raster layers train scales and get projected automatically
  layer_spatial(rasAreaTest, alpha = 0.8) +
  # make no data values transparent
  scale_fill_viridis_c(na.value = NA) +

  # spatial-aware automagic scale bar
  annotation_scale(location = "tl") +

  # spatial-aware automagic north arrow
  annotation_north_arrow(location = "br", which_north = "true") +
  guides(fill=FALSE)+
  theme_bw() +
  labs(fill='Elevation (m)')



devtools::load_all()
save_folder <- 'C:/HG_Projects/SideProjects/EALidarCheck/EADownloadTEST/test2'

rasAreaTest <- get_area(poly_area = DerwentHeadwater, resolution = 2, model.type = 'DTM', merge.tiles=TRUE, crop=TRUE) #, dest.folder = save_folder, out.name = 'TESTAREA'

ggplot() +
  # loads background map tiles from a tile source - rosm::osm.types() for osm options
  annotation_map_tile(type = "hillshade", zoomin = -1) +
  # requested area
  annotation_spatial(DerwentHeadwater, size = 2, col = "black") +
  # raster layer
  layer_spatial(rasAreaTest, alpha = 0.6) +
  # make no data values transparent
  scale_fill_distiller(na.value = NA, name='Elevation (m)') +
  # get real coords
  coord_sf(crs = 27700, datum = sf::st_crs(27700)) +
  theme_bw()

ggsave(filename = 'man/figures/README_example.png', dpi = 600)

devtools::install_github("tylermorganwall/rayshader")

