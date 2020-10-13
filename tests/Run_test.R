
# library(ggplot2)
# library(ggspatial)

devtools::document()
# devtools::uninstall()
devtools::load_all() # loads package functions

#create the zipped files for uploading to the defra portal:

# create_zip_tiles()


## Scraping the required tile Arc Web Map IDs

#conda env paths
# conda.p <- 'C:/Users/hughg/Miniconda3/envs/R_python'
conda.p <- 'C:/Users/hg340/AppData/Local/Continuum/miniconda3/envs/R_python'

#conda env name
env.n <- 'R_python'

# Download Gecko Driver from here: https://github.com/mozilla/geckodriver/releases
# gecko.e <- 'C:/install_files/gecko/geckodriver-v0.27.0-win64/geckodriver.exe'
gecko.e <- 'C:/Installation_Files/gecko/geckodriver-v0.27.0-win64/geckodriver.exe'

# py_out <- scrape_tile_IDs(conda_path = conda.p, env_name = env.n, gecko_exe = gecko.e)

# # Check results
# py_out$error_log
# py_out$arc_ids
# review_scrape <- check_tiles(py_out)

# review_scrape$tile_plot
# review_scrape$missing_tile_df
#
# # run again to mop up where errors ahve occured - use 'previous' arg to include last output...
# py_out2 <- scrape_tile_IDs(conda_path = conda.p, env_name = env.n, gecko_exe = gecko.e, previous=py_out)
#
# py_out3 <- scrape_tile_IDs(conda_path = conda.p, env_name = env.n, gecko_exe = gecko.e, previous=py_out2)

# review_scrape <- check_tiles(py_out3)
#
# review_scrape$tile_plot
# save_arc_IDs(py_out3)
#
#
# sf_save_obj <- scrape_to_sf(py_out3)




# cover_save <- 'C:/HG_Projects/SideProjects/EA_Lidar_Check/vectors/10km_coverage.gpkg'
#
# sf::write_sf(sf_save_obj$cover_sf, cover_save)
#
# km5inkm10 <- sf::read_sf('C:/HG_Projects/SideProjects/EA_Lidar_Check/vectors/5km_within10km.gpkg') %>%
#   dplyr::select(TILE_NAME, geom) %>%
#   saveRDS(., 'data/tile_within10km.rds')

library(ggplot2)
library(ggspatial)

devtools::load_all()
save_folder <- 'C:/HG_Projects/SideProjects/EALidarCheck/EADownloadTEST'

rasOB <- get_tile(resolution = 2, model.type = 'DTM' , os.tile.name = 'SU66nw', dest.folder = save_folder)
rasOB2 <- get_tile(resolution = 2, model.type = 'DSM' , os.tile.name = 'SK36ne')

# out <- raster::writeRaster(rasOB, 'C:/HG_Projects/SideProjects/EALidarCheck/EADownloadTEST/testingagain', format = 'GTiff', overwrite=TRUE)


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
poly_sf <- sf::read_sf('tests/Test_Area2.gpkg')

rasAreaTest <- get_area(poly_area = poly_sf, resolution = 2, model.type = 'DTM', merge.tiles=FALSE, crop=FALSE, dest.folder = save_folder, out.name = 'TestArea') #, dest.folder, out.name, ras.format



ggplot() +
  # loads background map tiles from a tile source - rosm::osm.types() for osm options
  annotation_map_tile(type = "hillshade", zoomin = -1) +

  annotation_spatial(poly_sf, size = 2, col = "black") +
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



devtools::install_github("tylermorganwall/rayshader")

