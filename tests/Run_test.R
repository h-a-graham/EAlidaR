devtools::document()
devtools::load_all()

# library(EAlidaR)
library(ggplot2)
library(ggspatial)
library(sf)
library(rayshader)


# ---------- Ashop download and map example ------------------
# save_folder <- 'C:/HG_Projects/SideProjects/EALidarCheck/EADownloadTEST/test2'

# DW_newCRS <- st_transform(Ashop_sf, crs = st_crs(4326))

# area_withfail <- read_sf('tests/Test_Area3.gpkg')

Ashop_Ras <- get_area(poly_area = Ashop_sf, resolution = 2, model_type = 'DTM', merge_tiles=TRUE, crop=TRUE) #, dest.folder = save_folder, out.name = 'TESTAREA'



ggplot() +
  # loads background map tiles from a tile source - rosm::osm.types() for osm options
  annotation_map_tile(type = "osm", zoomin = -1) +
  # requested area
  annotation_spatial(Ashop_sf, size = 2, col = "black", fill = NA) +
  # raster layer
  layer_spatial(Ashop_Ras, alpha = 0.8) +
  # make no data values transparent
  scale_fill_distiller(na.value = NA, name='Elevation (m)') +
  # get real coords
  coord_sf(crs = 27700, datum = sf::st_crs(27700)) +
  theme_bw()

ggsave(filename = 'man/figures/AshopMap.png', dpi = 600)


# --------- Test Tile download -------------------------

rasTile <- get_tile(os_tile_name = 'SU66nw', resolution = 2, model_type = 'DTM')


# ------ Ashop Rayshade Example ---------------

# AshopRas <- get_area(poly_area = Ashop_sf, resolution = 2, model_type = 'DTM', merge_tiles=TRUE, crop=TRUE)

AshopMat = raster_to_matrix(Ashop_Ras)

AshopMat %>%
  sphere_shade(texture = "imhof1") %>%
  add_shadow(ray_shade(AshopMat, zscale = 1, multicore =TRUE), 0.3) %>%
  add_shadow(ambient_shade(AshopMat, multicore=TRUE), 0) %>%
  plot_3d(AshopMat, zscale = 1.5, fov = 60, theta = 45, phi = 15, windowsize = c(1000, 800), zoom = 0.2,
          solid = FALSE)

Sys.sleep(0.2)
render_depth(focus = 0.7, focallength = 70, clear = FALSE, filename = 'man/figures/AshopRayshade.png')




#  ------------ Exeter Uni Rayshade -------------------
ExeUniRas <- get_area(poly_area = UniOfExeter_sf, resolution = 1, model_type = 'DSM', merge_tiles=TRUE, crop=TRUE)

ExeUniMat = raster_to_matrix(ExeUniRas)

ExeUniMat %>%
  sphere_shade(texture = "bw") %>%
  add_shadow(ray_shade(ExeUniMat, zscale = 1, multicore =TRUE), 0.3) %>%
  add_shadow(ambient_shade(ExeUniMat, multicore=TRUE), 0.1) %>%
  plot_3d(ExeUniMat, zscale = 1.4, fov = 60, theta = 50, phi = 20, windowsize = c(1000, 800), zoom = 0.3,
          solid = FALSE)

Sys.sleep(0.2)
render_depth(focus = 0.7, focallength = 70, clear = FALSE, filename = 'man/figures/UoeRayshade.png')




# -------------- Exeter City Rayshade -----------------
ExeterRas <- get_area(poly_area = Exeter_sf, resolution = 1, model_type = 'DSM', merge_tiles=TRUE, crop=TRUE)

ExeterMat = raster_to_matrix(ExeterRas)

ExeterMat %>%
  sphere_shade(texture = "bw") %>%
  add_shadow(ray_shade(ExeterMat, zscale = 1, multicore =TRUE), 0.3) %>%
  add_shadow(ambient_shade(ExeterMat, multicore=TRUE), 0) %>%
  plot_3d(ExeterMat, zscale = 1.5, fov = 60, theta = 45, phi = 20, windowsize = c(1000, 800), zoom = 0.2,
          solid = FALSE)

Sys.sleep(0.2)
render_snapshot(filename = 'man/figures/ExeterRayshade.png')


