# EAlidaR
Package to download EA liDAR data


So this package is very much in development...

### Background:

THe Environment Agency provide high resolution, open source elevation datasets for much of England. At present the best (only?) way to download this data is via the ESRI-based web map portal (https://environment.data.gov.uk/DefraDataDownload/?Mode=survey). This has numerous drawbacks - there are limits to the number of files that can be extracted at any given time, the spatial join between the requested area and available tiles is very slow and the data is provided in zipped files of varying raster formats (mainly ASCII and GeoTiff). 

The purpose of this package is to provide a clean and easy way to download and interact directly with these excellent data in R. For completeness, given the development state of this package there are two main sections if you like:  (1) A front end which provides the main function needed to download the data namely 'EAlidaR::get_area' and 'EAlidaR::get_tile' - more on these below. (2) Then there is the behind the scenes section which provides the fundamentals of building the database required to access the data. Here the main function of concern is 'EAlidaR::scrape_tile_IDs' which uses Reticulate to utilise python's selenium web driver library. This allows for the automated upload of xipped 10km grid .shp files to the portal and then scrape the Arc Web Map object IDs from the download URL (no actual data is downloaded in this step). To be honest, I have no idea if these codes will last forever so I'll leave the functions here in case they need to be re-run or if new data becomes available etc.


### Installation

`devtools::install_github`


### Download some data

The most useful function will, for most people, be 'EAlidaR::get_area' which allows for the retrieval of data from a given area, defined by either an sf object or a sf readable format (`sf::st_drivers()`). 

`EA_raster <- get_area(poly_area = poly_sf, resolution = 2, model.type = 'DTM', merge.tiles=TRUE, crop=TRUE, dest.folder = save_folder, out.name = 'TESTAREA')`


### Use Examples
