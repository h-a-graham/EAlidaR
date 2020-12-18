#' A function to generate the night_sky colour map.
#'
#' @param n integer value specifying the number of breaks to be used for the colour palette
#' @return A colour ramp to make sexy raster maps
#'@export
night_sky <- function(n=255){

  pal <-colorRampPalette(c('#33366A', '#7478AB','#95DAFC', '#FDA3DA', '#FFDA5C', '#FFF6DC'))

  return(pal(n))
}


#' A function to generate the powder_puff colour map.
#'
#' @param n integer value specifying the number of breaks to be used for the colour palette
#' @return A colour ramp to make sexy raster maps
#'@export
powder_puff <- function(n=255){

  pal <-colorRampPalette(c('#16165D', '#FFBC54'))

  return(pal(n))
}


#' A function to generate the sun_rise colour map.
#'
#' @param n integer value specifying the number of breaks to be used for the colour palette
#' @return A colour ramp to make sexy raster maps
#'@export
sun_rise <- function(n=255){

  pal <-colorRampPalette(c('#2D3C6B', '#B0FBFF', '#A179DE' ,'#F6BCFF', '#FEB653', '#FFF7BA'))

  return(pal(n))
}

#' A function to generate the fireburst colour map.
#'
#' @param n integer value specifying the number of breaks to be used for the colour palette
#' @return A colour ramp to make sexy raster maps
#'@export
fireburst <- function(n=255){

  pal <-colorRampPalette(c('#353652', '#9898B9', '#E7F7FF', '#F3AC4A', '#F3734A', '#66EAFF'))

  return(pal(n))
}
