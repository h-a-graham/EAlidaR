is_absolute_path <- function(path) {
  grepl("^(/|[A-Za-z]:|\\\\|~)", path)
}

get_arc_id <- function(tile.string){
  req_tile <- stringr::str_to_upper(tile.string)

  # print(coverage_10km_sf)
  # t10km_path <- system.file('data', 'coverage_10km_sf.rds', package = "EAlidaR")
  tiles_10km <- coverage_10km_sf

  # t5km_path <- system.file('data', 'tile_within10km.rds', package = "EAlidaR")
  tiles_5km <- tile_within10km

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
  } else if (res == 0.25 || res == 0.5){
    res_cm <- res * 100
    res.str <- sprintf('%sCM',res_cm)
  } else {
    stop('The resolution requested is not available options are: 0.25, 0.5, 1 and 2')
  }

  arc_web_id <- get_arc_id(os.tile)

  if (mod.type == 'DTM'){
    if (res == 1 || res == 2){
      download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DTM-%s-2019-%s.zip', arc_web_id, res.str, os.tile)
    } else if (res == 0.25 || res == 0.5){
      download_url <- sprintf('https://environment.data.gov.uk/UserDownloads/interactive/%s/LIDARCOMP/LIDAR-DTM-%s-%s.zip', arc_web_id, res.str, os.tile)
    }
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

#' Get DTM or DSM Data for a 5km Ordnance Survey (OS) Tile
#'
#' This function downloads Raster data from the DEFRA portal \url{https://environment.data.gov.uk/DefraDataDownload/?Mode=survey}.
#' It retrieves all available data within the requested OS tile defined by os.tile.name. This function only works across one tile;
#' if additional rasters are desired get_area() is recomended.
#'
#' @param os_tile_name A character string denoting thename of the desired OS tile with the form e.g. 'SU66nw' or 'SK36ne'. Beware this is case sensitive.
#' @param resolution a numeric value (in meters) of either: 0.25, 0.5, 1 or 2. <1m data has generally low coverage.
#' @param model_type A character of either 'DTM' or 'DSM' referring to Digital Terrain Model and Digital Surface Model respectively.
#' @param merge_tiles Boolean with default TRUE. If TRUE a single raster object is returned else a list of raster is produced.
#' @param dest_folder Optional character string for output save folder. If not provided rasters will be stored in tempfile()
#' @param ras_format Character for Raster format. Default is 'GTiff'. for available formats run raster::writeFormats()
#' @param quiet Boolean to allow silencing of Errors and return of problem OS tiles when calling from `get_area`.
#' @return A Raster object when merge.tiles = TRUE or a list of rasters when merge.tiles = FALSE
#' @export
get_tile <- function(os_tile_name, resolution, model_type, merge_tiles, dest_folder, ras_format, quiet=FALSE){
  oldw <- getOption("warn")
  options(warn = -1)

  TempRasDir <- tempdir()


  if(!(model_type == 'DTM' || model_type == 'DSM')){
    stop('Only DTM and DSM model types are supported at present.')
  }

  if (missing(dest_folder)) {
    dest_folder <- tempdir()
    save.tile <- FALSE
  } else {
    save.tile <- TRUE
  }

  if (missing(merge_tiles)){
    merge_tiles <- TRUE
  }

  if (missing(ras_format)){
    ras_format <- "GTiff"
  }

  rasformats <- raster::writeFormats()[,1]
  if (!(ras_format %in% rasformats)){
    stop('Requested Raster format not supported. Use raster::writeFormats() to view supported drivers')
  }

  web_url <- compose_url(res=resolution, os.tile = os_tile_name, mod.type = model_type)
  dest_path <- compose_zip_path(save.folder = TempRasDir, web.add = web_url)



  tryCatch({
    download.file(url=web_url, destfile=dest_path, method='auto', quiet = TRUE)
  },
  error=function(cond) {
    if (isFALSE(quiet)){
      stop(paste('No data is available for tile', os_tile_name ,'with a resolution of', resolution , 'm', sep = " "))
    }

    stop(os_tile_name)
  })

  exp.fold <- tools::file_path_sans_ext(dest_path)
  zip::unzip(zipfile = dest_path, overwrite = TRUE, exdir = exp.fold)
  unlink(dest_path, recursive = TRUE, force=TRUE)
  dest_path <- exp.fold


  if (isTRUE(merge_tiles)){
    ras.obj <- merge_ostiles(dest_path)
    if (isTRUE(save.tile)){
      ras.obj <- raster::writeRaster(ras.obj, file.path(dest_folder, os_tile_name), format=ras_format, overwrite=TRUE, options = c("COMPRESS=LZW"))
      unlink(dest_path, recursive = TRUE, force=TRUE)
    }

    return(ras.obj)
  }

  options(warn = oldw)
  return(dest_path)
}


resave_rasters <- function(ras, folder, ras_format){
  save_name <- tools::file_path_sans_ext(basename(ras@file@name))
  out_ras <- raster::writeRaster(ras, file.path(folder, save_name), format=ras_format, overwrite=TRUE, options = c("COMPRESS=LZW"))
  return(out_ras)
}

missing_tiles_warn <- function(mod_type, res, tile_str){
  message(sprintf('WARNING: Coverage incomplete! No %s data was available at a %s m resolution for the following tiles: \
         %s',mod_type, res, tile_str))
}

#' Get DTM or DSM data for an Area
#'
#' This function downloads Raster data from the DEFRA portal \url{https://environment.data.gov.uk/DefraDataDownload/?Mode=survey}.
#' It retrieves all available data within the requested area defined by poly_area and offers some additional functionality to
#' merge and crop the raster if desired. This function uses the get_tile function to extract all tiles that intersect the
#' desired region.
#'
#' @param poly_area Either an sf object or an sf-readable file. See sf::st_drivers() for available drivers
#' @param resolution a numeric value (in meters) of either: 0.25, 0.5, 1 or 2. <1m data has generally low coverage.
#' @param model_type A character of either 'DTM' or 'DSM' referring to Digital Terrain Model and Digital Surface Model respectively.
#' @param merge_tiles Boolean with default TRUE. If TRUE a single raster object is returned else a list of raster is produced.
#' @param crop Boolean with default FALSE. If TRUE data outside the bounds of the requested polygon area are discarded.
#' @param dest_folder Optional character string for output save folder. If not provided rasters will be stored in tempfile()
#' @param out_name Character required when saving merged raster to dest.folder.
#' @param ras_format Character for Raster format. Default is 'GTiff'. for available formats run raster::writeFormats()
#' @return A Raster object when merge.tiles = TRUE or a list of rasters when merge.tiles = FALSE
#' @export
get_area <- function(poly_area, resolution, model_type, merge_tiles, crop, dest_folder, out_name, ras_format){

  if (isFALSE(merge_tiles) && !missing(dest_folder) && !missing(out_name)){
    message('"out.name" ignored when saving multiple rasters i.e when "merge.type" = FALSE\n')
  }

  if (isTRUE(merge_tiles) && !missing(dest_folder) && missing(out_name)){

    stop('When saving a merged raster (merged.tiles = TRUE) you must also provide a name (i.e out.name = "MyArea")')
  }

  if(!(model_type == 'DTM' || model_type == 'DSM')){
    stop('Only "DTM" and "DSM" model types are supported at present.')
  }

  if (class(poly_area)[1] == "sf"){
    sf_geom <- poly_area
  } else {
    sf_geom <- sf::read_sf(poly_area)
  }

  #check and transform CRS of in polygon
  in_poly_crs <- sf::st_crs(sf_geom)$epsg
  if (in_poly_crs != 27700){
    message(sprintf('Warning: The polygon feature CRS provided is not British National Grid (EPSG:27700)\
         Polygon will be transformed from EPSG:%s to EPSG:27700 \
         Rasters will be returned in the original CRS - EPSG:27700\n', in_poly_crs))
    sf_geom <- sf_geom %>%
      sf::st_transform(27700)

  }


  if (missing(dest_folder)) {
    save.tile <- FALSE
    dest_folder <- tempdir()
    message('No destination folder provided - saving to temp directory..\n')
  }else {
    save.tile <- TRUE

    if (isFALSE(is_absolute_path(dest_folder))){
      wrkdir <- getwd()
      dest_folder <- file.path(wrkdir, dest_folder)
    }

  }

  if (missing(merge_tiles)){
    merge_tiles <- TRUE
  }

  if (missing(crop)){
    crop <- FALSE
  }

  if (isTRUE(crop) & isFALSE(merge_tiles)){
    crop==FALSE
    message(' "crop" arg. ignored - crop only applies when "merge.tiles" is TRUE \n')
  }

  if (missing(ras_format)){
    ras_format <- "GTiff"
  }

  rasformats <- raster::writeFormats()[,1]
  if (!(ras_format %in% rasformats)){
    stop('Requested Raster format not supported. Use raster::writeFormats() to view supported drivers')
  }

  # tiles_5km <- readRDS('data/tile_within10km.rds')
  tiles_5km <- tile_within10km

  sf::st_agr(sf_geom) = "constant"
  sf::st_agr(tiles_5km) = "constant"

  tile_5km_inter <- tiles_5km %>%
    sf::st_intersection(sf_geom)%>%
    dplyr::pull(TILE_NAME) %>%
    gsub("([0-9]\\D+)", "\\L\\1",.,perl=TRUE)

  pb <- progress::progress_bar$new(total = length(tile_5km_inter),
                                   clear = FALSE)

  collect_tiles_safe <- function(x) {
    pb$tick()
    f = purrr::safely(function() get_tile(os_tile_name = x, resolution = resolution, model_type = model_type, quiet=TRUE))
    f()
  }


  message('Downloading Tiles...')
  ras_list <- tile_5km_inter %>%
    purrr::map( ~ collect_tiles_safe(.))

  # remove any NA values produced  by missing tiles
  error_list <- unlist(purrr::map(ras_list, purrr::pluck, "error", "message"))
  errs_flagged <- FALSE
  if (!is.null(error_list)){
    error_list <- paste(error_list, collapse=', ' )
    errs_flagged <- TRUE
  }

  # error_list <- error_list[!is.null(error_list)]
  ras_list <- unlist(purrr::map(ras_list, purrr::pluck, "result"))
  # ras_list <- ras_list[!is.null(ras_list)]

  if (length(ras_list) == 0 ){
    stop(sprintf('No %s data was retrieved for the requested area! \
  The folowing tiles have no %s data at a resolution of %s m: \
  %s',model_type, model_type, resolution, error_list))
  }


  if (isTRUE(merge_tiles)){
    if (length(ras_list) > 1){
      message('Merging Rasters...')
      ras_merge <- do.call(raster::merge, ras_list)
    } else if(length(ras_list) == 1){

      ras_merge <- ras_list[[1]]

    }

    if (isTRUE(crop)){
      message('Cropping Raster...')
      ras_merge <- raster::crop(ras_merge, sf_geom)
    }

    if (isTRUE(save.tile)){
      ras_merge <- raster::writeRaster(ras_merge, file.path(dest_folder, out_name), format=ras_format,
                                       overwrite=TRUE, options = c("COMPRESS=LZW"))
    }
    if (isTRUE(errs_flagged)){
      missing_tiles_warn(mod_type=model_type, res=resolution, tile_str=error_list)
    }

    return(ras_merge)
  } else {
    if (isTRUE(save.tile)){

      ras_list <- ras_list %>%
        purrr::map(~ resave_rasters(ras=., folder = dest_folder, ras_format = ras_format))

      if (isTRUE(errs_flagged)){
        missing_tiles_warn(mod_type=model_type, res=resolution, tile_str=error_list)
      }

      return(ras_list)
    }

    if (isTRUE(errs_flagged)){
      missing_tiles_warn(mod_type=model_type, res=resolution, tile_str=error_list)
    }
    return(ras_list)
  }


  if (isTRUE(errs_flagged)){
    missing_tiles_warn(mod_type=model_type, res=resolution, tile_str=error_list)
  }

  return(ras_list)
}

