#check resolution and import the relevant coverage sf
model_res_check <- function(.model, .res){

  if (.model == 'DTM'){
    if (.res == 0.25){
      cover_sf <- lidar_25cm
    } else if(.res == 0.5){
      cover_sf <- lidar_50cm
    } else if(.res == 1){
      cover_sf <- lidar_1m
    } else if(.res == 2){
      cover_sf <- lidar_2m
    } else {
      stop('The resolution requested is not available options are: 0.25, 0.5, 1 and 2')
    }
  } else if (.model == 'DSM'){
    if (.res == 0.25){
      cover_sf <- lidar_25cm
    } else if(.res == 0.5){
      cover_sf <- lidar_50cm
    } else if(.res == 1){
      cover_sf <- lidar_1m_DSM
    } else if(.res == 2){
      cover_sf <- lidar_2m_DSM
    } else {
      stop('The resolution requested is not available options are: 0.25, 0.5, 1 and 2')
    }
  } else {
    stop('Only "DTM" and "DSM" model types are supported at present.')
  }
  return(cover_sf)
}



#' Check the availble coverage for LiDAR mosaics for a given area
#'
#' This function checks the amount of coverage offered by the LiDAR mosaic of a given resolution for an area of interest
#'
#' @param poly_area Either an sf object or an sf-readable file. See sf::st_drivers() for available drivers
#' @param model_type A character of either 'DTM' or 'DSM' referring to Digital Terrain Model and Digital Surface Model respectively.
#' @param resolution a numeric value (in meters) of either: 0.25, 0.5, 1 or 2.
#' @return A ggplot object - map of coverage requested and subtitle detailing proportion of cover.
#' @export

check_coverage <- function(poly_area, model_type, resolution){
  oldw <- getOption("warn")
  options(warn = -1)
  #check resolution and import the relevant coverage sf
  cover_sf <- model_res_check(.model = model_type, .res = resolution)


  # check if in polygon in sf obj or path to vector file
  if (class(poly_area)[1] == "sf"){
    sf_geom <- poly_area
  } else {
    sf_geom <- sf::read_sf(poly_area)
  }

  #transform and check CRS of in polygon #  possible solution to %epsg returning 'NA'
  in_poly_crs <- sf::st_crs(sf_geom)

  sf_geom <- sf_geom %>%
    sf::st_transform(st_crs(cover_sf))

  if (in_poly_crs != sf::st_crs(sf_geom)){
    message('Warning: The polygon feature CRS provided is not British National Grid (EPSG:27700)\
         Polygon will be transformed to EPSG:27700 \
         Rasters will be returned in EPSG:27700\n')
  }

  cover_int <- sf::st_intersection(cover_sf, sf_geom) %>%
    sf::st_union()

  if (length(cover_int) == 0){
    cover_int_area <- 0
  } else {
    cover_int_area <- sf::st_area(cover_int)
  }
  requested_area <- sf::st_area(sf_geom)
  perc_cover <- round(cover_int_area/requested_area*100, 1)

  options(warn = oldw) # reset old warning settings

  plot(sf::st_geometry(sf_geom), border='#d95f02', axes=T, lwd=2,
       sub=sprintf('%s %% LiDAR %s m %s coverage for requested area', perc_cover, resolution, model_type))
  plot(sf::st_geometry(cover_int), col=scales::alpha('#1b9e77',0.9), border='grey', axes=T, alpha=1, add=T)
  legend("bottomleft", inset=.02, c('Requested Area', 'Available Data'), fill=c('#d95f02', '#1b9e77'), horiz=TRUE, cex=0.8)

}

#' Show the availble coverage for LiDAR mosaics Nationally
#'
#' This function plots the coverage available for the LiDAR mosaic of a given resolution for England
#'
#' @param model_type A character of either 'DTM' or 'DSM' referring to Digital Terrain Model and Digital Surface Model respectively.
#' @param resolution a numeric value (in meters) of either: 0.25, 0.5, 1 or 2
#' @return A ggplot object - map of coverage requested and subtitle detailing % cover.
#' @export

national_coverage <- function(model_type, resolution){
  oldw <- getOption("warn")
  options(warn = -1)

  #check resolution and import the relevant coverage sf
  cover_sf <- model_res_check(.model = model_type, .res = resolution)
  options(warn = oldw) # reset old warning settings

  plot(sf::st_geometry(cover_sf), col='#7570b3', axes=T,border = 'grey', lwd=0.1,
       sub=sprintf('Extent of Available LiDAR %s m %s composite data', resolution, model_type))
}
