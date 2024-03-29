devtools::document()
devtools::load_all()

# library(EAlidaR)
library(sf)
library(rayshader)
library(terra)
# -------------- check cover example --------------
check_coverage(poly_area = Ashop_sf, model_type = 'DTM', resolution = 1)
check_coverage(poly_area = Ashop_sf, model_type = 'DSM', resolution = 2)

check_coverage(poly_area = city_of_london_sf, model_type = 'DSM', resolution = 1)
check_coverage(poly_area = city_of_london_sf, model_type = 'DSM', resolution = 0.25)
check_coverage(poly_area = city_of_london_sf, model_type = 'DSM', resolution = 0.5)
# ggsave(filename = 'man/figures/AshopCover.png', dpi = 600)

national_coverage(model_type = 'DTM', resolution = 2)
national_coverage(model_type = 'DSM', resolution = 1)
# ---------- Ashop download and map example ------------------
save_folder <- 'C:/HG_Projects/SideProjects/EALidarCheck/EADownloadTEST/test2'
save_folder2 <- 'tests/save_tests'
# DW_newCRS <- st_transform(Ashop_sf, crs = st_crs(4326))

# area_withfail <- read_sf(system.file("extdata", "Test_Area3.gpkg", package = "EAlidaR"))
Ashop_Ras <- get_area(poly_area = Ashop_sf, resolution = 2, model_type = 'DTM',
                      merge_tiles=TRUE, crop=T)

Ashop_Ras <- get_area(poly_area = Ashop_sf, resolution = 2, model_type = 'DSM', merge_tiles=TRUE, crop=TRUE)
                      # dest_folder = save_folder2, out_name = 'test1') #, dest.folder = save_folder, out.name = 'TESTAREA'


png(filename='man/figures/AshopMap.png')
terra::plot(Ashop_Ras, col=night_sky())
plot(Ashop_sf,
     add = TRUE)
dev.off()

# --------- Test Tile download -------------------------

rasTile <- get_tile(os_tile_name = 'SK09se', resolution = 2, model_type = 'DTM')


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



# --------------- City of London Rayshade ----------------------------

CoL_Ras <- get_area(poly_area = city_of_london_sf, resolution = 1, model_type = 'DSM', merge_tiles=TRUE, crop=TRUE)


CoL_Mat = raster_to_matrix(CoL_Ras)

CoL_Mat %>%
  sphere_shade(texture = "bw") %>%
  add_shadow(ray_shade(CoL_Mat, zscale = 1, multicore =TRUE), 0.3) %>%
  add_shadow(ambient_shade(CoL_Mat, multicore=TRUE), 0.1) %>%
  plot_3d(CoL_Mat, zscale = 1, fov = 60, theta = 20, phi = 30, windowsize = c(1000, 800), zoom = 0.3,
          solid = FALSE)

Sys.sleep(0.2)
render_depth(focus = 0.7, focallength = 70, clear = FALSE, filename = 'man/figures/CoLRayshade.png')
