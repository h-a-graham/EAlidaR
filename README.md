
# EAlidaR

<div style="text-align:center"><img src="/man/figures/ScarfellHQ.png" width="60%"></div>

**After a brief hiatus, {EAlidar} is back and now (theoretically) able
to handle the dynamic URL download requests of the DEFRA portal. No
doubt problems will crop up so please start up a
[discussion](https://github.com/h-a-graham/EAlidaR/discussions) or
[submit and issue](https://github.com/h-a-graham/EAlidaR/issues)**

An R package to download EA LiDAR composite data for England. So you’re
aware, Data downloaded with this package is licensed under the [Open
Government License
v 3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/)

### Background:

The Environment Agency (EA) provide wonderful high resolution, open
source elevation datasets for much of England. At present, the best way
to download this data is via the [ESRI-based web map portal](https://environment.data.gov.uk/DefraDataDownload/?Mode=survey).
This has numerous drawbacks - there are limits to the number of files
that can be extracted at any given time, the spatial join between the
requested area and available tiles is very slow and the data is provided
in zipped files of varying raster formats (mainly ASCII and GeoTiff).

The purpose of this package is to provide a clean and easy way to
download and interact directly with these excellent data in R. The
challange here is that the download URLs for LiDAR tiles are not static.
This package uses [{RSelenium}](https://github.com/ropensci/RSelenium) to automate the
uploading of Ordnance Survey tiles that intersect a requested area. At
present, {EAlidar} only supports the chrome driver; you will
therefore need to have Google Chrome installed on your machine to run
this package. The Chrome driver should be automatically detected the correct version; 
the automated version detection for Linux has not
been tested - if this fails, the user can provide the correct version as
an argument.

Right now, this package only supports the most recent LiDAR data
available. This includes the National LiDAR Programme (NLP) and
Composite data. If 1m resolution is chosen, NLP data will be requested
if available before searching composite data. If 0.25, 0.5 or 1m
resolution is chosen, Composite data will be requested. I intend to add
support for the time series data in the near future.


### Installation

`devtools::install_github('h-a-graham/EAlidaR')`

### Checking for available data

You can check the availability of data for your region by using
`check_coverage` which returns a ggplot of the available coverage. To
see national scale coverage use `national_covaerage`. However, at present
these functions only display the Composite data, and don't include NLP 
extents. For more information on data coverage see this [web portal](https://environment.maps.arcgis.com/apps/webappviewer/index.html?id=f765c2a97d644f08927d5cd5abe58d87)

### Examples:

Here is a simple use case where we download the available 2m DTM data
for one of the example regions provided with the package `Ashop_sf`.
Using the `get_area` function, we retrieve a single raster as ‘merge_tiles’ is
TRUE. We can save this data in a desired location with ‘dest_folder’,
‘out_name’ and ‘ras_format’ arguments but, in this case, rasters are
stored in the `tempfile()` location and will be available only during
the active R session (unless subsequently saved with
`raster::writeRaster`).

    library(EAlidaR)
    
    
    # national_coverage(model_type = 'DSM', resolution = 2) # quite slow by the way...
    check_coverage(poly_area = Ashop_sf, model_type = 'DTM', resolution = 2)
    
    Ashop_Ras <- get_area(poly_area = Ashop_sf, resolution = 2, model_type = 'DTM', 
                          merge_tiles=TRUE, crop=TRUE)
    
    raster::plot(Ashop_Ras, col=sun_rise())
    plot(Ashop_sf, add = TRUE)

<p float="left">

<img src="/man/figures/AshopCover.png" width="49%" />
<img src="/man/figures/AshopMap.png" width="49%" />

</p>

Alternatively, the functions `get_OS_tile_5km()` and `get_OS_tile_10km()` 
allow the users to specify 5 or 10m OS tile name(s) as a vector:

    NY20nw <- get_OS_tile_5km(os_tile_name = 'NY20nw', resolution = 1, model_type = 'DTM')

    NY20 <- get_OS_tile_10km(os_tile_name = 'NY20', resolution = 1, model_type = 'DTM')

And the a final option to download data is with `get_from_xy()`. For now the XY coordinates must
be provided in OSGB/British National Grid format:

    Scafell_Peak <- get_from_xy(xy=c(321555, 507208), radius = 500, resolution = 1, model_type = 'DSM')

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

Now for a smaller example; the code below uses the built in
`UniOfExeter_sf` polygon to download 1m DSM data for the Streatham
campus region and then visualise with rayshader…

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

![Exeter Uni Example](/man/figures/UoeRayshade.png)

If you really want to melt your computer ;) why not build a 3d model of
Exeter City with the `Exeter_sf` dataset:

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

![Exeter City Example](/man/figures/ExeterRayshade.png)

And finally…In some parts of England you can download \<1m resolution
data - here is an example using the `city_of_london_sf`

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

![City of London Example](/man/figures/CoLRayshade.png)
