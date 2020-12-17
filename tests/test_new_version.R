# Notes: Starting to come together nicely. some stuff to do

# Add functionality for downloading specific products.
#    i. by year - allowing for download of specific time-series data.
#    ii. by composite - to select only composite dataset
#    iii. by NLP - select only data from the NLP
#    iv. by timeseries - select all lidar for a given area for all years and generate a raster stack.


# Update check coverage function:
# I think we need to move away from ggplot - it's just too slow. let's make a simple base plot.
# Need to consider options for coverage data - it's massive - maybe compressing will solve this...
# maybe we should just direct people to either the DEFRA or EA portal to check (not super keen on
# this but loading time at present for the package is way too long.)


# Add alternative download functions:
#   i. get_tile - download specific tile by name
#   ii. get_area_from_xy - download area buffered around a given x y location.

# consider adding parallel functionality for scraping - will improve speed but make error handling trickier?



devtools::load_all()
devtools::document()
library(sf)



st <- Sys.time()
Ashop_Ras <- get_area(poly_area = Ashop_sf, resolution = 2, model_type = 'DSM', chrome_version ="87.0.4280.88", merge_tiles=TRUE, crop=TRUE)
print(Sys.time()-st)
raster::plot(Ashop_Ras, col=sun_rise())
plot(Ashop_sf,
     add = TRUE)


# scafell

Scafell_sf <- st_read('QGIS/vectors/Scafell.gpkg')


st <- Sys.time()
Scafel_ras <-  get_area(poly_area = Scafell_sf, resolution = 1, model_type = 'DTM', merge_tiles=TRUE, crop=TRUE)
print(Sys.time()-st)


raster::plot(Scafel_ras, col=night_sky())
plot(Scafell_sf,
     add = TRUE)

# library(rayshader)
# ScarMat = raster_to_matrix(Scafel_ras)
#
# ScarMat %>%
#   sphere_shade(texture = "imhof1") %>%
#   add_shadow(ray_shade(ScarMat, zscale = 1, multicore =TRUE), 0.3) %>%
#   add_shadow(ambient_shade(ScarMat, multicore=TRUE), 0) %>%
#   plot_3d(ScarMat, zscale = 1, fov = 60, theta = 45, phi = 15, windowsize = c(1000, 800), zoom = 0.2,
#           solid = FALSE)

Sys.sleep(0.2)
render_depth(focus = 0.7, focallength = 50, clear = FALSE, filename = 'man/figures/Scarfell.png')
render_highquality(filename = 'man/figures/ScarfellHQ.png')
st <- Sys.time()
ExeUniRas <-  get_area(poly_area = UniOfExeter_sf, resolution = 2, model_type = 'DSM', merge_tiles=TRUE, crop=TRUE)
print(Sys.time()-st)

raster::plot(ExeUniRas, col=night_sky())
plot(UniOfExeter_sf,
     add = TRUE)


# testing get_OS_tile_5km

NY20nw <- get_OS_tile_5km(OS_5km_tile= c('NY20nw'), resolution = 1, model_type = 'DSM')
raster::plot(NY20nw, col=sun_rise())


?get_OS_tile_5km


