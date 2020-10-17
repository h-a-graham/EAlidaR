# EAlidaR
An R package to download EA LiDAR composite data for England.


This package is very much in development... I would really welcome any comments, suggestions, issues etc. If anything strange crops up please submit and issue here: https://github.com/h-a-graham/EAlidaR/issues 


### Background:

The Environment Agency (EA) provide high resolution, open source elevation datasets for much of England. At present, the best (only?) way to download this data is via the ESRI-based web map portal (https://environment.data.gov.uk/DefraDataDownload/?Mode=survey). This has numerous drawbacks - there are limits to the number of files that can be extracted at any given time, the spatial join between the requested area and available tiles is very slow and the data is provided in zipped files of varying raster formats (mainly ASCII and GeoTiff). 

The purpose of this package is to provide a clean and easy way to download and interact directly with these excellent data in R. For completeness, given the development state of this package, there are two main sections if you like:  (1) A front end which provides the main function needed to download the data; namely 'EAlidaR::get_area' and 'EAlidaR::get_tile' - more on these below. (2) Then there is the behind the scenes section which provides the fundamentals of building the database required to access the data. Here the main function of concern is 'EAlidaR::scrape_tile_IDs' which uses Reticulate to utilise python's selenium web driver library. This allows for the automated upload of zipped 10km grid .shp files to the portal and then scrapes the Arc Web Map object IDs from the download URL (no actual data is downloaded in this step). To be honest, I have no idea if these object ID codes will last forever so I'll leave the functions here in case they need to be re-run or if new data becomes available etc.


### Installation

`devtools::install_github('h-a-graham/EAlidaR')`


### Examples:

Here is a simple use case where we download the available 2m DTM data for the example region provided with the package `DerwentHeadwater`. using the `get_area` function we retrieve a single raster as 'merge_tiles' is TRUE. We can save this data in a desired location with 'dest_folder', 'out_name' and 'ras_format' arguments but, in this case, rasters are stored in the `tempfile()` location and will be available only during the active R session (unless subsequently saved with `raster::writeRaster`).
We then plot the data using the excellent ggplot and ggspatial packages see here for more cool ideas for plotting spatial data in R here: https://github.com/paleolimbot/ggspatial 

```
library(EAlidaR)
library(ggplot2)
library(ggspatial)

rasAreaTest <- get_area(poly_area = DerwentHeadwater, resolution = 2, model_type = 'DTM', merge_tiles=TRUE, crop=TRUE)

ggplot() +
  # loads background map tiles from a tile source - rosm::osm.types() for osm options
  annotation_map_tile(type = "osm", zoomin = -1) +
  # requested area
  annotation_spatial(DerwentHeadwater, size = 2, col = "black", fill = NA) +
  # raster layer
  layer_spatial(rasAreaTest, alpha = 0.8) +
  # make no data values transparent
  scale_fill_distiller(na.value = NA, name='Elevation (m)') +
  # get real coords
  coord_sf(crs = 27700, datum = sf::st_crs(27700)) +
  theme_bw()
```
![Derwent Headwater Example](/man/figures/README_example.png)


Alternatively, the function `get_tile` offers the ability to download the data from a single 5km OS tile. Make sure the case is correct in 'os_tile_name' with the first two characters in caps and last two in lower case. 'dest.folder' can be supplied to save the raster(s) in a specified location, otherwise it will be written to tempfile(). 'ras_format' is another optional argument that can be used to specify the raster driver used see `raster::writeFormats()` for options - default is GeoTiff.

```
rasTile <- get_tile(os_tile_name = 'SU66nw', resolution = 2, model_type = 'DTM')

```
