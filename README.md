
# EAlidaR

<p align="center">
<img src="/man/figures/HexLogov1.png" width="30%">
</p>

**An R package to download EA LiDAR 'National LiDAR programme' (NLP) and 
composite data for England. So you’re aware, Data downloaded with this package 
is licensed under the 
[Open Government License v 3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
This package is in a somewhat developmental state so if things aren't working 
quite right, please start up a 
[discussion](https://github.com/h-a-graham/EAlidaR/discussions) or 
[submit an issue](https://github.com/h-a-graham/EAlidaR/issues)**


### Background:

The Environment Agency (EA) provide wonderful high resolution, open 
source elevation datasets for much of England. At present, the best way 
to download this data is via the 
[ESRI-based web map portal](https://environment.data.gov.uk/DefraDataDownload/?Mode=survey). 
This has some drawbacks - there are limits to the number of files 
that can be extracted at any given time, the spatial join between the 
requested area and available tiles is very slow and the data is provided 
in zipped files of varying raster formats (mainly ASCII and GeoTiff). 

This package aims to provide a clean and easy way to download and interact 
directly with these excellent data in R. The challenge here is that the 
download URLs for LiDAR tiles are not static. 
This package uses [{RSelenium}](https://github.com/ropensci/RSelenium) 
to automate the uploading of Ordnance Survey tiles that intersect a requested 
area.

Right now, this package only supports the most recent LiDAR data 
available. This includes the National LiDAR Programme (NLP) and 
Composite data. If 1m resolution is chosen, NLP data will be requested 
if available before searching composite data. If 0.25, 0.5 or 2m 
resolution is chosen, Composite data will be requested. I intend to add 
support for the time series data in the near future.


### Dependencies
At present, {EAlidar} only supports the chrome driver; you will therefore need 
to install [Google Chrome](https://www.google.com/chrome/) to run this package.

Selenium requires java, therefore make sure to install 
[Java](https://www.java.com/en/download/) before installing {EAlidaR}.

### Installation

`devtools::install_github('h-a-graham/EAlidaR')`

### Checking for available data

You can check the availability of data for your region by using 
`check_coverage` which returns a ggplot of the available coverage. To 
see national scale coverage use `national_covaerage`. However, at present 
these functions only display the Composite data, and don't include NLP 
extents. For more information on data coverage see this 
[web portal](https://environment.maps.arcgis.com/apps/webappviewer/index.html?id=f765c2a97d644f08927d5cd5abe58d87).
At present composite data coverage for 1 m and 2 m resolutions is 87% and 81% 
respectively. With the inclusion of NLP data this is even higher! 
[More info here](https://experience.arcgis.com/experience/753ad2ebd3554fa696885b8c366c3049/page/page_16/?views=view_23)

### A note on Selenium, JAVA and the Chrome driver...

So, this package uses the `RSelenium::rsDriver()` function to open and manage 
the chrome driver. If you are getting errors relating to 
[{Rselenium}](https://github.com/ropensci/RSelenium) then you may have to 
update/reinstall Java. 

In windows, remove the folder 'C:/ProgramData/Oracle', remove references to 
javapath in your Path Environment and then 
[reinstall java](https://www.java.com/en/download/). 

For Debian/Ubuntu the standard 
[Java install](https://ubuntu.com/tutorials/install-jre#2-installing-openjre) 
steps should be sufficient.

The function `find_chrome_v()` can be used to retrieve your system's version of 
Chrome;This function is the default value of the 'chrome_version' argument in 
all the download functions. If this function does not work on your OS (only 
tested on Windows and Ubuntu) or returns an incorrect value, you can manually 
specify the version using the 'chrome_version' argument. To do this simply open 
chrome > menu button > help > About Google Chrome. Then inspect the version 
number and then run `binman::list_versions('chromedriver')`. Select the driver 
version which most closely matches your machine's Google Chrome version and 
include it as a character string in the 'chrome_version' argument. Some issues 
still remain for OSX and MacOS...


### Examples:

Here is a simple use case where we download the available 2m DTM data
for one of the example regions provided with the package `Ashop_sf`.
Using the `get_area()` function, we retrieve a single raster as ‘merge_tiles’ is
TRUE. We can save this data in a desired location with ‘dest_folder’,
‘out_name’ and ‘ras_format’ arguments but, in this case, rasters are
stored in the `tempfile()` location and will be available only during
the active R session (unless subsequently saved with
`raster::writeRaster`).

    library(EAlidaR)

    # national_coverage(model_type = 'DSM', resolution = 2) # quite slow by the way...
    # check_coverage(poly_area = Ashop_sf, model_type = 'DTM', resolution = 2) 
    
    Ashop_Ras <- get_area(poly_area = Ashop_sf, resolution = 2, model_type = 'DTM', 
                          merge_tiles=TRUE, crop=TRUE)
    
    raster::plot(Ashop_Ras, col=sun_rise())
    plot(Ashop_sf, add = TRUE)

<p float="centre">
<img src="/man/figures/AshopMap.png" width="65%" />
</p>

Alternatively, the functions `get_OS_tile_5km()` and `get_OS_tile_10km()` allow 
the users to specify 5 or 10m Ordnance Survey (OS) tile name(s) as a vector:

    NY20nw <- get_OS_tile_5km(OS_5km_tile = c('NY20nw','NY10ne)', resolution = 1, model_type = 'DTM')

    NY20 <- get_OS_tile_10km(OS_10km_tile = 'NY20', resolution = 1, model_type = 'DTM')

To download data around a specific location use `get_from_xy()`. The XY 
coordinates must be provided in OSGB/British National Grid (Lat, Long) format:

    Scafell_Peak <- get_from_xy(xy=c(321555, 507208), radius = 500, resolution = 1, model_type = 'DSM')

## Some Extras...

And just to really show off how great this data is, here are some 3D
examples with the brilliant [{rayshader} package](https://github.com/tylermorganwall/rayshader). 

First let’s try out the Ashop Valley data we downloaded previously. Note that multicore is set
to TRUE, in these examples, as they are quite large rasters - set to
FALSE if you don’t want to use multiprocessing.

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

![Ashop Rayshader Example](/man/figures/AshopRayshade.png)


In some parts of England you can download \<1m resolution data - here is an 
example using the for the City of London using the `get_from_xy()` function

    CoL <- get_from_xy(xy=c(532489 , 181358), radius = 500, resolution=0.5, model_type = 'DSM')

    CoL_Mat = raster_to_matrix(CoL)
    
    CoL_Mat %>%
      sphere_shade(texture = "bw") %>%
      add_shadow(ray_shade(CoL_Mat, zscale = 1, multicore =TRUE), 0.3) %>%
      add_shadow(ambient_shade(CoL_Mat, multicore=TRUE), 0.1) %>%
      plot_3d(CoL_Mat, zscale = 1, fov = 60, theta = 20, phi = 30, windowsize = c(1000, 800), zoom = 0.3,
              solid = FALSE)
    
    Sys.sleep(0.2)
    render_depth(focus = 0.7, focallength = 70, clear = TRUE)

![City of London Example](/man/figures/CoLRayshade.png)
