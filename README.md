# EAlidaR
<img src="/man/figures/CoLRayshade.png" width="70%">

An R package to download EA LiDAR composite data for England.


This package is very much in development... I would really welcome any comments, suggestions, issues etc. If anything strange crops up please submit and issue here: https://github.com/h-a-graham/EAlidaR/issues 


### Background:

The Environment Agency (EA) provide high resolution, open source elevation datasets for much of England. At present, the best (only?) way to download this data is via the ESRI-based web map portal (https://environment.data.gov.uk/DefraDataDownload/?Mode=survey). This has numerous drawbacks - there are limits to the number of files that can be extracted at any given time, the spatial join between the requested area and available tiles is very slow and the data is provided in zipped files of varying raster formats (mainly ASCII and GeoTiff). 

The purpose of this package is to provide a clean and easy way to download and interact directly with these excellent data in R. For completeness, given the development state of this package, there are two main sections if you like:  (1) A front end which provides the main function needed to download the data; namely 'EAlidaR::get_area' and 'EAlidaR::get_tile' - more on these below. (2) Then there is the behind the scenes section which provides the fundamentals of building the database required to access the data. Here the main function of concern is 'EAlidaR::scrape_tile_IDs' which uses Reticulate to utilise python's selenium web driver library. This allows for the automated upload of zipped 10km grid .shp files to the portal and then scrapes the Arc Web Map object IDs from the download URL (no actual data is downloaded in this step). To be honest, I have no idea if these object ID codes will last forever so I'll leave the functions here in case they need to be re-run or if new data becomes available etc.


### Installation

`devtools::install_github('h-a-graham/EAlidaR')`


### Examples:

Here is a simple use case where we download the available 2m DTM data for one of the example regions provided with the package `Ashop_sf`. using the `get_area` function we retrieve a single raster as 'merge_tiles' is TRUE. We can save this data in a desired location with 'dest_folder', 'out_name' and 'ras_format' arguments but, in this case, rasters are stored in the `tempfile()` location and will be available only during the active R session (unless subsequently saved with `raster::writeRaster`).
We then plot the data using the excellent ggspatial package (https://github.com/paleolimbot/ggspatial)

```
library(EAlidaR)
library(ggplot2)
library(ggspatial)


check_coverage(poly_area = Ashop_sf, resolution = 2)


Ashop_Ras <- get_area(poly_area = Ashop_sf, resolution = 2, model_type = 'DTM', merge_tiles=TRUE, crop=TRUE)

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
```
<p float="left">
  <img src="/man/figures/AshopCover.png" width="45%" />
  <img src="/man/figures/AshopMap.png" width="45%" />
</p>





Alternatively, the function `get_tile` downloads data from a single 5km OS tile. Make sure the case is correct in 'os_tile_name' with the first two characters in caps and last two in lower case. 'dest_folder' can be supplied to save the raster(s) in a specified location, otherwise it will be written to tempfile(). 'ras_format'  can be used to specify the raster driver used see `raster::writeFormats()` for options - default is GeoTiff.

```
rasTile <- get_tile(os_tile_name = 'SU66nw', resolution = 2, model_type = 'DTM')

```

And just to really show off how great this data is, here are some 3D examples with the brilliant rayshader package (more info at: https://github.com/tylermorganwall/rayshader). First let's try out the Ashop Valley data we downloaded previously. Note that multicore is set to TRUE, in these examples, as they are quite large rasters - set to FALSE if you don't want to use multiprocessing.

```
library(rayshader)

AshopMat = raster_to_matrix(Ashop_Ras) 

AshopMat %>%
  sphere_shade(texture = "imhof1") %>%
  add_shadow(ray_shade(AshopMat, zscale = 1, multicore =TRUE), 0.3) %>%
  add_shadow(ambient_shade(AshopMat, multicore=TRUE), 0) %>%
  plot_3d(AshopMat, zscale = 1.5, fov = 60, theta = 45, phi = 20, windowsize = c(1000, 800), zoom = 0.2,
          solid = FALSE)

Sys.sleep(0.2)
render_depth(focus = 0.7, focallength = 70, clear = TRUE)
```
![Ashop Rayshader Example](/man/figures/AshopRayshade.png)

Now for a smaller example; the code below uses the built in `UniOfExeter_sf` polygon to download 1m DSM data for the Streatham campus region and then visualise with rayshader...

```
ExeUniRas <- get_area(poly_area = UniOfExeter_sf, resolution = 1, model_type = 'DSM', merge_tiles=TRUE, crop=TRUE)

ExeUniMat = raster_to_matrix(ExeUniRas)

ExeUniMat %>%
  sphere_shade(texture = "bw") %>%
  add_shadow(ray_shade(ExeUniMat, zscale = 1, multicore = TRUE), 0.3) %>%
  add_shadow(ambient_shade(ExeUniMat, multicore=TRUE), 0.1) %>%
  plot_3d(ExeUniMat, zscale = 1.4, fov = 60, theta = 50, phi = 20, windowsize = c(1000, 800), zoom = 0.3,
          solid = FALSE)

Sys.sleep(0.2)
render_depth(focus = 0.7, focallength = 70, clear = TRUE)
```
![Exeter Uni Example](/man/figures/UoeRayshade.png)


If you really want to melt your computer ;) why not build a 3d model of Exeter City with the `Exeter_sf` dataset:

```
ExeterRas <- get_area(poly_area = Exeter_sf, resolution = 1, model_type = 'DSM', merge_tiles=TRUE, crop=TRUE)

ExeterMat = raster_to_matrix(ExeterRas)

ExeterMat %>%
  sphere_shade(texture = "bw") %>%
  add_shadow(ray_shade(ExeterMat, zscale = 1, multicore =TRUE), 0.3) %>%
  add_shadow(ambient_shade(ExeterMat, multicore=TRUE), 0) %>%
  plot_3d(ExeterMat, zscale = 1.5, fov = 60, theta = 45, phi = 20, windowsize = c(1000, 800), zoom = 0.2,
          solid = FALSE)

Sys.sleep(0.2)
render_snapshot(clear = TRUE)
```
![Exeter City Example](/man/figures/ExeterRayshade.png)

And finally...In some parts of England you can download <1m resolution data - here is an example using the `city_of_london_sf`

```
CoL_Ras <- get_area(poly_area = city_of_london_sf, resolution = 0.5, model_type = 'DSM', merge_tiles=TRUE, crop=TRUE)


CoL_Mat = raster_to_matrix(CoL_Ras)

CoL_Mat %>%
  sphere_shade(texture = "bw") %>%
  add_shadow(ray_shade(CoL_Mat, zscale = 1, multicore =TRUE), 0.3) %>%
  add_shadow(ambient_shade(CoL_Mat, multicore=TRUE), 0.1) %>%
  plot_3d(CoL_Mat, zscale = 1, fov = 60, theta = 20, phi = 30, windowsize = c(1000, 800), zoom = 0.3,
          solid = FALSE)

Sys.sleep(0.2)
render_depth(focus = 0.7, focallength = 70, clear = TRUE)

```
![City of London Example](/man/figures/CoLRayshade.png)
