# function to use gdal warp approach
warp_method <- function(ras.list){
  # wrapped with try catch - if gdal warp fails defaults to raster::merge
  out_ras <- tryCatch({

    if (is.character(class(ras.list[[1]]))) {
      src_list <- as.character(ras.list)
    } else {
      src_list <- lapply(ras.list, FUN=function(x) terra::sources(x[[1]])[,1]) %>%
        as.character()
    }

    merge_path <- tempfile(fileext = '.tif')
    sf::gdal_utils(util = "warp",
                   source = src_list,
                   destination = merge_path)

    outras <- terra::rast(merge_path)
    # message('warp worked!')
    return(outras)
  },
  error = function(e) {
    warning(
      "\nReceived error from gdalwarp.",
      "Attempting merge using terra::merge")
    read_raster <- function(ras.path){
      suppressWarnings(ras <- terra::rast(ras.path))
      suppressWarnings(terra::crs(ras) <- sf::st_crs(27700)$wkt)
      return(ras)
    }
    ras.list <- lapply(ras.list, read_raster)
    suppressWarnings(outras <- do.call(terra::merge, ras.list))
    return(outras)
  }
  )
}
