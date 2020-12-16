#' A function to generate a nice looking Elevation colour map.
#'
#' @param n integer value specifying the number of breaks to be used for the colour palette
#' @return A colour ramp to make sexy raster maps
#'@export
night_sky <- function(n=255){

  pal <-colorRampPalette(c('#33366A', '#7478AB','#95DAFC', '#FDA3DA', '#FFDA5C', '#FFF6DC'))

  return(pal(n))
}


