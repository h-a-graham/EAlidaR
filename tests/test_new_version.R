devtools::load_all()
devtools::document()
library(sf)
grid5_int <- c("SK08ne", "SK08se", "SK09se", "SK18nw", "SK18sw", "SK19sw")

grid10_int <- c("SK08", "SK09", "SK18", "SK19")
#


grid5_int <- c("SK08ne")

grid10_int <- c("SK08")


grid5_int <- c("ST10ne")

grid10_int <- c("ST10")


grid5_int <- c("SU01ne", "SU01se", "SU01nw")

grid10_int <- c("SU01")


st <- Sys.time()
l <- get_tiles(tile_list10km = grid10_int, tile_list5km = grid5_int, chrome_ver="87.0.4280.88", resolution=1, mod_type='DSM')
print(Sys.time()-st)


night_skyT <- function(n=255){

  pal <-colorRampPalette(c('#33366A', '#7478AB','#95DAFC', '#FDA3DA', '#FFDA5C', '#FFF6DC'))

  return(pal(n))
}


st <- Sys.time()
Ashop_Ras <- get_area(poly_area = Ashop_sf, resolution = 2, model_type = 'DSM', chrome_version ="87.0.4280.88", merge_tiles=TRUE, crop=TRUE)
print(Sys.time()-st)
raster::plot(Ashop_Ras, col=night_sky())
plot(Ashop_sf,
     add = TRUE)


# scafell

Scafell_sf <- st_read('QGIS/vectors/Scafell.gpkg')


st <- Sys.time()
Scafel_ras <-  get_area(poly_area = Scafell_sf, resolution = 1, model_type = 'DTM', chrome_version ="87.0.4280.88", merge_tiles=TRUE, crop=TRUE)
print(Sys.time()-st)


raster::plot(Scafel_ras, col=night_sky())
plot(Scafell_sf,
     add = TRUE)


st <- Sys.time()
ExeUniRas <-  get_area(poly_area = UniOfExeter_sf, resolution = 2, model_type = 'DSM', chrome_version ="87.0.4280.88", merge_tiles=TRUE, crop=TRUE)
print(Sys.time()-st)

raster::plot(ExeUniRas, col=night_sky())
plot(UniOfExeter_sf,
     add = TRUE)
