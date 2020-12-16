is_absolute_path <- function(path) {
  grepl("^(/|[A-Za-z]:|\\\\|~)", path)
}


resave_rasters <- function(ras, folder, ras_format){
  save_name <- tools::file_path_sans_ext(basename(ras@file@name))
  out_ras <- raster::writeRaster(ras, file.path(folder, save_name), format=ras_format, overwrite=TRUE, options = c("COMPRESS=LZW"))
  return(out_ras)
}

missing_tiles_warn <- function(mod_type, res, tile_str){
  warning(sprintf('Coverage incomplete! No %s data was available at a %s m resolution for the following tiles: \
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
#' @param chrome_version The chrome version that best matches your own chrome installation version. Choose from binman::list_versions("chromedriver")
#' @param merge_tiles Boolean with default TRUE. If TRUE a single raster object is returned else a list of raster is produced.
#' @param crop Boolean with default FALSE. If TRUE data outside the bounds of the requested polygon area are discarded.
#' @param dest_folder Optional character string for output save folder. If not provided rasters will be stored in tempfile()
#' @param out_name Character required when saving merged raster to dest.folder.
#' @param ras_format Character for Raster format. Default is 'GTiff'. for available formats run raster::writeFormats()
#' @return A Raster object when merge.tiles = TRUE or a list of rasters when merge.tiles = FALSE
#' @export
get_area <- function(poly_area, resolution, model_type, chrome_version, merge_tiles, crop, dest_folder, out_name, ras_format){

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
      dest_folder <- normalizePath(file.path(dest_folder))
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


  sf::st_agr(sf_geom) = "constant"

  tiles_5km <- grid_5km_sf
  sf::st_agr(tiles_5km) = "constant"

  tiles_10km <- grid_10km_sf
    sf::st_agr(tiles_10km) = "constant"

  tile_5km_inter <- tiles_5km %>%
    sf::st_intersection(sf_geom)%>%
    dplyr::pull(TILE_NAME) %>%
    gsub("([0-9]\\D+)", "\\L\\1",.,perl=TRUE)

  tile_10km_inter <- tiles_10km %>%
    sf::st_intersection(sf_geom)%>%
    dplyr::pull(TILE_NAME) %>%
    gsub("([0-9]\\D+)", "\\L\\1",.,perl=TRUE)

  ras_list <- get_tiles(tile_list10km = tile_10km_inter, tile_list5km = tile_5km_inter, chrome_ver = chrome_version,
                        resolution = resolution, mod_type=model_type)

  # remove any NA values produced  by missing tiles
  error_list <- unlist(purrr::map(ras_list, purrr::pluck, "error", "message"))
  errs_flagged <- FALSE
  if (!is.null(error_list)){
    error_list <- paste(error_list, collapse=', ' )
    errs_flagged <- TRUE
  }

  # error_list <- error_list[!is.null(error_list)] # not needed now??
  ras_list <- unlist(purrr::map(ras_list, purrr::pluck, "result"))
  # ras_list <- ras_list[!is.null(ras_list)] # not needed now??

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

