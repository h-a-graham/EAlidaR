

get_arc_id <- function(tile.string){
  req_tile <- stringr::str_to_upper(tile.string)

  tiles_10km <- readRDS('data/coverage_10km_sf.rds')

  tiles_5km <- readRDS('data/tile_within10km.rds')

  sf::st_agr(tiles_10km) = "constant"
  sf::st_agr(tiles_5km) = "constant"

  tile_id <- tiles_5km %>%
    dplyr::filter(TILE_NAME == req_tile) %>%
    sf::st_buffer(., -100)%>%
    sf::st_intersection(tiles_10km) %>%
    dplyr::pull(arc_code)

  return(tile_id)

}


compose_url <- function(res, os.tile, mod.type){

  if (res == 1 || res == 2){
    res.str <- sprintf('%sM',res)
  } else if (res == 0.25 || res == res_cm){
    res_cm <- res * 100
    res.str <- sprintf('%sCM',res_cm)
  } else {
    stop('The resolution requested is not available options are: 0.25, 0.5, 1 and 2')
  }

  arc_web_id <- get_arc_id(os.tile)

  if (mod.type == 'DTM'){
    download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DTM-%s-2019-%s.zip', arc_web_id, res.str, os.tile)
  } else if (mod.type == 'DSM') {
    download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DSM-%s-%s.zip', arc_web_id, res.str, os.tile)
  }

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
merge_ostiles <- function(ras.folder){
  ras.list <- list.files(ras.folder)
  ras.list <- purrr::discard(ras.list , grepl(".tif.xml|.tfw|index", ras.list ))

  ras.list <- lapply(ras.list, join_paths, p2=ras.folder)

  if (length(ras.list) > 1){
    ras.list <- lapply(ras.list, read_raster)
    ras.merge <- do.call(raster::merge, ras.list)
  } else if(length(ras.list) == 1){

    ras.merge <- raster::raster(file.path(ras.list[[1]]))

  }

  raster::crs(ras.merge)<- sp::CRS('+init=EPSG:27700')


  return(ras.merge)
}


#' @export
get_tile <- function(os.tile.name, resolution, model.type, dest.folder, merge.tiles, ras.format){

  TempRasDir <- tempdir()


  if(!(model.type == 'DTM' || model.type == 'DSM')){
    stop('Only DTM and DSM model types are supported at present.')
  }

  if (missing(dest.folder)) {
    dest.folder <- tempdir()
    save.tile <- FALSE
  } else {
    save.tile <- TRUE
  }

  if (missing(merge.tiles)){
    merge.tiles <- TRUE
  }

  if (missing(ras.format)){
    ras.format <- "GTiff"
  }

  rasformats <- raster::writeFormats()[,1]
  if (!(ras.format %in% rasformats)){
    stop('Requested Raster format not supported. Use raster::writeFormats() to view supported drivers')
  }

  web.url <- compose_url(res=resolution, os.tile = os.tile.name, mod.type = model.type)
  dest.path <- compose_zip_path(save.folder = TempRasDir, web.add = web.url)

  tryCatch({
  download.file(url=web.url, destfile=dest.path, method='auto', quiet = FALSE)
  },
  error=function(cond) {
    message("Requested tile is not available!!! \n
            Either: (1) No data is availale in this tile or \n
            (2) try a different resolution... \n ")
    # message("Original error message:")
    # message(cond)
    # Choose a return value in case of error
    return()
  })


  exp.fold <- tools::file_path_sans_ext(dest.path)
  zip::unzip(zipfile = dest.path, overwrite = TRUE, exdir = exp.fold)
  unlink(dest.path, recursive = TRUE, force=TRUE)
  dest.path <- exp.fold


  if (merge.tiles == TRUE){
    ras.obj <- merge_ostiles(dest.path)
    if (save.tile == TRUE){
      ras.obj <- raster::writeRaster(ras.obj, file.path(dest.folder, os.tile.name), format=ras.format, overwrite=TRUE, options = c("COMPRESS=LZW"))
      unlink(dest.path, recursive = TRUE, force=TRUE)
    }

    return(ras.obj)
  }

  return(dest.path)
}


resave_rasters <- function(ras, folder, ras_format){
  print('B')
  save_name <- tools::file_path_sans_ext(basename(ras[[2]]@file@name))
  print(save_name)
  out_ras <- raster::writeRaster(ras, file.path(folder, save_name), format=ras_format, overwrite=TRUE, options = c("COMPRESS=LZW"))
  return(out_ras)
}


#' @export
get_area <- function(poly_area, resolution, model.type, merge.tiles, crop, dest.folder, out.name, ras.format){

  if (merge.tiles == TRUE & !missing(dest.folder) & missing(out.name)){
    stop('When saving a merged raster (merged.tiles = TRUE) you must also provide a name (i.e out.name = "MyArea)"')
  }

  if(!(model.type == 'DTM' || model.type == 'DSM')){
    stop('Only "DTM" and "DSM" model types are supported at present.')
  }

  if (class(poly_area)[1] == "sf"){
    sf_geom <- poly_area
  } else {
    sf_geom <- sf::read_sf(poly_area)
  }

  if (sf::st_crs(sf_geom)$epsg != 27700){
    sf_geom <- sf_geom %>%
      sf::st_transform(27700)
  }


  if (missing(dest.folder)) {
    save.tile <- FALSE
    dest.folder <- tempdir()
    message('No destination folder provided - saving to temp directory...')
  }else {
    save.tile <- TRUE
  }

  if (missing(merge.tiles)){
    merge.tiles <- TRUE
  }

  if (missing(crop)){
    crop <- FALSE
  }

  if (crop == TRUE & merge.tiles == FALSE){
    crop==FALSE
    message(' "crop" arg. ignored - crop only applies when "merge.tiles" is TRUE')
  }

  if (missing(ras.format)){
    ras.format <- "GTiff"
  }

  tiles_5km <- readRDS('data/tile_within10km.rds')

  sf::st_agr(sf_geom) = "constant"
  sf::st_agr(tiles_5km) = "constant"

  tile_5km_inter <- tiles_5km %>%
    sf::st_intersection(sf_geom)%>%
    dplyr::pull(TILE_NAME) %>%
    gsub("([0-9]\\D+)", "\\L\\1",.,perl=TRUE)


  collect_tiles_safe <- function(x) {
    f = purrr::possibly(function() get_tile(os.tile.name = x, resolution = resolution, model.type = model.type), otherwise = NA_real_)
    f()
  }


  ras_list <- tile_5km_inter %>%
    purrr::map( ~ collect_tiles_safe(.))

  # remove any NA values produced  by missing tiles
  ras_list <- ras_list[!is.na(ras_list)]

  if (merge.tiles ==TRUE){
    if (length(ras_list) > 1){
      ras.merge <- do.call(raster::merge, ras_list)
    } else if(length(ras_list) == 1){

      ras.merge <- ras_list[[1]]

    }

    if (crop==TRUE){
      ras.merge <- raster::crop(ras.merge, sf_geom)
    }

    if (save.tile == TRUE){
      ras.merge <- raster::writeRaster(ras.merge, file.path(dest.folder, out.name), format=ras.format, overwrite=TRUE, options = c("COMPRESS=LZW"))
    }
    return(ras.merge)
  } else {
    if (save.tile == TRUE){
      print('B1')
      ras_list <- ras_list %>%
        purrr::map(~ resave_rasters(ras=., folder = dest.folder, ras_format = ras.format))
      print('B2')
      return(ras_list)
    }
    return(ras_list)
  }




  return(ras_list)
}

