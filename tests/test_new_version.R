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

# consider adding parallel functionality for scraping - will improve speed but make error handling trickier?



devtools::load_all()
devtools::document()
library(sf)

ras <- get_from_xy(xy=c(198222, 56775), radius = 1000, resolution=1, model_type = 'DSM')

st <- Sys.time()
Ashop_Ras <- get_area(poly_area = Ashop_sf, resolution = 2, model_type = 'DTM', merge_tiles=TRUE, crop=TRUE,
                      dest_folder = 'tests/save_tests', out_name = 'Ashop_DSM_2m')
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

UoEtrans <- sf::st_transform(UniOfExeter_sf, 4326)

st <- Sys.time()
ExeUniRas <-  get_area(poly_area = UoEtrans, resolution = 1, model_type = 'DSM', merge_tiles=TRUE, crop=TRUE)
print(Sys.time()-st)

raster::plot(ExeUniRas, col=sun_rise())
plot(UniOfExeter_sf,
     add = TRUE)


# testing get_OS_tile_5km

NY20nw <- get_OS_tile_5km(OS_5km_tile= c('NY20nw'), resolution = 1, model_type = 'DSM')
raster::plot(NY20nw, col=sun_rise(),)


?get_OS_tile_5km

NY <- get_OS_tile_10km(OS_10km_tile= c('NY20'), resolution = 1, model_type = 'DSM')
raster::plot(NY20nw, col=sun_rise())


CheddarGorge <- get_from_xy(xy=c(347133, 154286), radius = 500, resolution = 1, model_type = 'DSM')
raster::plot(CheddarGorge, col=fireburst())
# testing get_from_xy
# CheddarMine <- get_from_xy(xy=c(346117, 155276), radius = 500, resolution = 1, model_type = 'DSM')
# raster::plot(CheddarMine, col=fireburst())

BeachVis <- function(n=255){
  pal <-colorRampPalette(c('#edc951', '#eb6841', '#cc2a36', '#4f372d', '#00a0b0'))
  return(pal(n))
}

#plotting funciton
plot_raster <- function(df){
  data.frame(raster::rasterToPoints(df))%>%
    ggplot(., aes_string(x = 'x', y='y', fill= colnames(.)[3])) +
    geom_raster() +
    scale_fill_gradientn(colours = BeachVis()) +
    theme_void()+
    theme(legend.position = "bottom", panel.background = element_rect(fill = "#44475a", color = "#44475a"),
          panel.grid = element_blank(),
          text = element_text(color = "#8be9fd"),
          axis.line=element_blank(),
          axis.text = element_blank(),
          axis.ticks=element_blank(),
          axis.title = element_blank(),
          panel.border=element_blank(),
          panel.spacing = unit(0, "cm"),
          panel.grid.major=element_blank(),
          panel.grid.minor=element_blank(),
          plot.margin = margin(0, 0, 0, 0, "cm"),
          plot.caption = element_text(hjust=0.02, size=rel(2.2), color = "#FFFFFF"),
          plot.background = element_rect(fill = "#44475a"))+
    guides(color = FALSE, linetype = FALSE, fill = FALSE)
}
plot_raster(CheddarMine) %>%
  ggsave(filename = 'tests/save_tests/Cheddar.jpg',., width=10, height=10, dpi=300)

ScarPeak <- get_from_xy(xy=c(321555, 507208), radius = 600, resolution = 1, model_type = 'DSM')
raster::plot(ScarPeak, col=sun_rise())

library(rayshader)
ScarMat = raster_to_matrix(ScarPeak)

ScarMat %>%
  height_shade(texture = night_sky()) %>%
  add_shadow(ray_shade(ScarMat, zscale = 1, multicore =TRUE), 0.3) %>%
  add_shadow(ambient_shade(ScarMat, multicore=TRUE), 0) %>%
  plot_3d(ScarMat, zscale = 1, fov = 60, theta = 45, phi = 15, windowsize = c(1000, 800), zoom = 0.4,
          solid = FALSE)

# ScarMat %>%
#   height_shade() %>%
#   add_shadow(ray_shade(ScarMat,zscale=1),0.3) %>%
#   plot_map()

Sys.sleep(0.2)
render_depth(focus = 0.6, focallength = 60, clear = FALSE, filename = 'man/figures/Scarfell.png')
render_highquality(filename = 'man/figures/ScarfellHQ.png')



# coverage tests

check_coverage(Ashop_sf, 'DSM', 2)

national_coverage('DSM', 1)

#crs issue:

sf::st_crs(UniOfExeter_sf) == sf::st_crs(sf::st_transform(UniOfExeter_sf, 27700))

UoEwgs <- sf::st_transform(UniOfExeter_sf, 4326)

sf::st_crs(UoEwgs) == sf::st_crs(sf::st_transform(UoEwgs, 27700))

