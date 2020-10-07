# library(raster)
# library(ggplot2)
# library(ggspatial)
# library(sf)
# library(lwgeom)
# library(tidyverse)
# library(zip)
devtools::document()
devtools::load_all() # loads package functions

#create the zipped files for uploading to the defra portal:
# create_zip_tiles()


## Scraping the required tile Arc Web Map IDs

#conda env paths
conda.p <- 'C:/Users/hughg/Miniconda3/envs/R_python'

#conda env name
env.n <- 'R_python'

# Download Gecko Driver from here: https://github.com/mozilla/geckodriver/releases
gecko.e <- 'C:/install_files/gecko/geckodriver-v0.27.0-win64/geckodriver.exe'

py_out <- scrape_tile_IDs(conda_path = conda.p, env_name = env.n, gecko_exe = gecko.e)

py_out$error_log

review_scrape <- check_tiles(py_out)

review_scrape$tile_plot
review_scrape$missing_tile_df








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








full_grid <- sf::read_sf('data/OSGB_Grid_5km.gpkg')


plot(full_grid)

st_geohash(full_grid, precision = 0)

SX69se_grid <- full_grid %>%
  filter(TILE_NAME == 'SX69SE')

osgb_to_geohash <- function(sf.obj){
  st_transform(sf.obj, crs = sp::CRS('+init=EPSG:4326'))%>%
    st_geohash(., precision = 5)
}

geohash <- osgb_to_geohash(SX69se_grid)
geohash

bounds1 <- st_boundary(SX69se_grid)$geom
bounds1[[1]]

bounds2 <- st_boundary(st_transform(SX69se_grid, crs = sp::CRS('+init=EPSG:4326')))$geom

sf::write_sf(SX69se_grid, 'C:/HG_Projects/SideProjects/EA_Lidar_Check/vectors/SX69se.shp')



search_areas <- 'C:/HG_Projects/SideProjects/EA_Lidar_Check/vectors/OS50km_Lidar_Ext.gpkg'


sa_gdf_shrink <- sf::read_sf(search_areas) %>%
  st_buffer(., dist = -100) %>%
  select(TILE_NAME, geom)

plot(sa_gdf_shrink)


TL_test <- sa_gdf_shrink %>%
  filter(TILE_NAME == 'TLNE')

plot(TL_test)

sf::write_sf(TL_test, 'C:/HG_Projects/SideProjects/EA_Lidar_Check/vectors/TLNE.shp')
filelist = Sys.glob('C:/HG_Projects/SideProjects/EA_Lidar_Check/vectors/TLNE.*')
zip::zipr('C:/HG_Projects/SideProjects/EA_Lidar_Check/vectors/TL.zip', files = filelist)


