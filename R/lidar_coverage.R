
#' Check the availble coverage for LiDAR mosaics for a given area
#'
#' This function checks the amount of coverage offered by the LiDAR mosaic of a given resolution for an area of interest
#'
#' @param poly_area Either an sf object or an sf-readable file. See sf::st_drivers() for available drivers
#' @param resolution a numeric value (in meters) of either: 0.25, 0.5, 1 or 2.
#' @return A ggplot object - map of coverage requested and subtitle detailing % cover.
#' @export
check_coverage <- function(poly_area, resolution){
  oldw <- getOption("warn")
  options(warn = -1)
  #check resolution and import the relevant coverage sf
  if (resolution == 0.25){
    cover_sf <- lidar_25cm
  } else if(resolution == 0.5){
    cover_sf <- lidar_50cm
  } else if(resolution == 1){
    cover_sf <- lidar_1m
  } else if(resolution == 2){
    cover_sf <- lidar_2m
  } else {
    stop('The resolution requested is not available options are: 0.25, 0.5, 1 and 2')
  }

  # check if in polygon in sf obj or path to vector file
  if (class(poly_area)[1] == "sf"){
    sf_geom <- poly_area
  } else {
    sf_geom <- sf::read_sf(poly_area)
  }

  #check and transform CRS of in polygon
  in_poly_crs <- sf::st_crs(sf_geom)$epsg
  if (in_poly_crs != 27700){
    message(sprintf('Warning: The polygon feature CRS provided is not British National Grid (EPSG:27700)\
         Polygon will be transformed from EPSG:%s to EPSG:27700', in_poly_crs))
    sf_geom <- sf_geom %>%
      sf::st_transform(27700)

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

  cover_plot <- ggplot2::ggplot() +
    ggspatial::annotation_map_tile(type = "cartolight", zoomin = -1, ) +
    ggspatial::layer_spatial(cover_int, ggplot2::aes(fill='Available Data'), alpha = 0.5, colour=NA)+
    ggspatial::layer_spatial(sf_geom, ggplot2::aes(colour ='Requested Area'),alpha = 0.5, fill=NA)+

    ggplot2::scale_fill_manual(values = c("#09D517")) +

    ggplot2::scale_colour_manual(values = c('black')) +

    ggplot2::coord_sf(crs = 27700, datum = sf::st_crs(27700)) +

    ggplot2::labs(subtitle = stringr::str_c(perc_cover, '% LiDAR coverage for requested are with resoltion of ', resolution, ' m')) +
    ggplot2::theme(legend.title=ggplot2::element_blank())

  options(warn = oldw) # reset old warning settings

  return(cover_plot)

}

#' Show the availble coverage for LiDAR mosaics Nationally
#'
#' This function plots the coverage available for the LiDAR mosaic of a given resolution for England
#'
#' @param resolution a numeric value (in meters) of either: 0.25, 0.5, 1 or 2
#' @return A ggplot object - map of coverage requested and subtitle detailing % cover.
#' @export
national_coverage <- function(resolution){
  oldw <- getOption("warn")
  options(warn = -1)

  #check resolution and import the relevant coverage sf
  if (resolution == 0.25){
    cover_sf <- lidar_25cm
  } else if(resolution == 0.5){
    cover_sf <- lidar_50cm
  } else if(resolution == 1){
    cover_sf <- lidar_1m
  } else if(resolution == 2){
    cover_sf <- lidar_2m
  } else {
    stop('The resolution requested is not available options are: 0.25, 0.5, 1 and 2')
  }

  fill_lab <- sprintf('Available %s m Data', resolution)
  cover_plot <- ggplot2::ggplot() +
    ggspatial::annotation_map_tile(type = "cartolight", zoomin = -1, ) +
    ggspatial::layer_spatial(cover_sf, ggplot2::aes(fill=fill_lab), alpha = 0.5, colour=NA)+

    ggplot2::scale_fill_manual(values = c("#09D517")) +

    ggplot2::scale_colour_manual(values = c('black')) +

    ggplot2::coord_sf(crs = 27700, datum = sf::st_crs(27700)) +

    ggplot2::labs(subtitle = sprintf('Extent of Available LiDAR composite data at a resolution of %s m', resolution)) +
    ggplot2::theme(legend.title=ggplot2::element_blank())

  options(warn = oldw) # reset old warning settings

  return(cover_plot)
}
