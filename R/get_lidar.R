
compose_url <- function(res, os.tile){

  if (res == 1 || res == 2){
    res.str <- sprintf('%sM',res)
  } else if (res == 0.25 || res == 0.5){
    res.str <- sprintf('%sCM',res)
  } else {
    stop('The resolution requested is not available options are: 0.25, 0.5, 1 and 2')
  }

  sprintf('https://environment.data.gov.uk/UserDownloads/interactive/979e74aadea94482871f8baf7028c65225520/LIDARCOMP/LIDAR-DSM-%s-%s.zip', res.str, os.tile)
}

compose_zip_path <- function(save.folder, web.add){
  file.name <- basename(web.add)
  file.path(save.folder, file.name)
}

read_raster <- function(ras.path){
  ras <- raster::raster(ras.path)
  raster::crs(ras) <- sp::CRS('+init=EPSG:27700') #'+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +units=m +no_defs'
  return(ras)
}

join_paths <- function(p1, p2){
  file.path(p2, p1)
}


#' @export
merge.ostiles <- function(ras.folder){
  ras.list <- list.files(ras.folder)
  ras.list <- lapply(ras.list, join_paths, p2=ras.folder)
  ras.list <- lapply(ras.list, read_raster)
  ras.merge <- do.call(raster::merge, ras.list)
  raster::crs(ras.merge)<- sp::CRS('+init=EPSG:27700')   #'+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +units=m +no_defs'
  return(ras.merge)
}


#' @export
get_tile <- function(resolution, os.tile.name, dest.folder, unzip.file, merge.tiles, save.tile, ras.format){

  if (missing(dest.folder)) {
    dest.folder <- tempdir()
    message('No destination folder provided - saving to temp directory...')
  }

  if (missing(unzip.file)){
    unzip.file <- TRUE
  }

  if (missing(merge.tiles)){
    merge.tiles <- TRUE
  }

  if (merge.tiles == TRUE & unzip.file == FALSE){
    warning('unzip.file arg set to false but mosaic.tiles set as TRUE. Setting unzip.file to TRUE by default')
    unzip.file <- TRUE
  }

  if (missing(save.tile)){
    save.tile <- FALSE
  }
  if (missing(ras.format)){
    ras.format <- "GTiff"
  }

  web.url <- compose_url(res=resolution, os.tile = os.tile.name)
  dest.path <- compose_zip_path(save.folder = dest.folder, web.add = web.url)
  download.file(url=web.url, destfile=dest.path, method='auto', quiet = FALSE)

  if (unzip.file == TRUE){
    exp.fold <- tools::file_path_sans_ext(dest.path)
    unzip(zipfile = dest.path, overwrite = TRUE, exdir = exp.fold)
    unlink(dest.path, recursive = TRUE, force=TRUE)
    dest.path <- exp.fold
  }

  if (merge.tiles == TRUE){
    ras.obj <- merge.ostiles(dest.path)
    if (save.tile == TRUE){
      raster::writeRaster(ras.obj, file.path(dest.folder, os.tile.name), format=ras.format, overwrite=TRUE, options = c("COMPRESS=LZW", "TFW=YES"))

    }
    return(ras.obj)
  }

  return(dest.path)
}
