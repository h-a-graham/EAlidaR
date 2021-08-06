is_absolute_path <- function(path) {
  grepl("^(/|[A-Za-z]:|\\\\|~)", path)
}


resave_rasters <- function(ras, folder, ras_format){
  save_name <- names(ras)
  out_ras <- suppressWarnings(terra::writeRaster(ras, file.path(folder, save_name), filetype=ras_format, overwrite=TRUE))
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
#' @param ras_format Character for Raster format. Default is 'GTiff'. for available formats run terra::gdal(drivers=T)
#' @param headless_chrome Boolean with default TRUE. if FALSE chrome is run with GUI activated.
#' @param check_selenium Boolean with default TRUE. If FAlSE {Rselenium} will not check for updated drivers.
#' @return A SpatRaster (from {terra}) object when merge.tiles = TRUE or a list of rasters when merge.tiles = FALSE
#' @export
get_area <- function(poly_area, resolution, model_type, chrome_version = NULL,
                     merge_tiles=TRUE, crop=FALSE, dest_folder=NULL, out_name=NULL,
                     ras_format="GTiff", headless_chrome=TRUE, check_selenium=TRUE){

  if (is.null(chrome_version)){
    chrome_version = find_chrome_v()
  }

  if (isFALSE(merge_tiles) && !is.null(dest_folder) && !is.null(out_name)){
    message('"out.name" ignored when saving multiple rasters i.e when "merge.type" = FALSE\n')
  }

  if (isTRUE(merge_tiles) && !is.null(dest_folder) && is.null(out_name)){

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

  #transform and check CRS of in polygon #  possible solution to %epsg returning 'NA'
  in_poly_crs <- sf::st_crs(sf_geom)

  sf_geom <- sf_geom %>%
    sf::st_transform(27700)

  if (in_poly_crs != sf::st_crs(sf_geom)){
    message('Warning: The polygon feature CRS provided is not British National Grid (EPSG:27700)\
         Polygon will be transformed to EPSG:27700 \
         Rasters will be returned in EPSG:27700\n')
  }


  if (is.null(dest_folder)) {
    save.tile <- FALSE
    dest_folder <- tempdir()
    message('No destination folder provided - saving to temp directory..\n')
  }else {
    save.tile <- TRUE

    if (isFALSE(is_absolute_path(dest_folder))){
      dest_folder <- normalizePath(file.path(dest_folder))
    }

  }


  if (isTRUE(crop) & isFALSE(merge_tiles)){
    crop==FALSE
    message(' "crop" arg. ignored - crop only applies when "merge.tiles" is TRUE \n')
  }


  rasformats <- terra::gdal(drivers=T)[,1]
  if (!(ras_format %in% rasformats)){
    stop('Requested Raster format not supported. Use terra::gdal(drivers=T) to view supported drivers')
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
                        resolution = resolution, mod_type=model_type, headless_chrome=headless_chrome,
                        check_selenium = check_selenium)

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
      ras_merge <- warp_method(ras_list)
      # ras_merge <- suppressWarnings(do.call(raster::merge, ras_list))
    } else if(length(ras_list) == 1){

      ras_merge <- ras_list[[1]]

    }

    if (isTRUE(crop)){
      message('Cropping Raster...')
      ras_merge <- suppressWarnings(terra::crop(ras_merge, sf_geom))
    }

    if (isTRUE(save.tile)){
      ras_merge <- suppressWarnings(terra::writeRaster(ras_merge, file.path(dest_folder, out_name), filetype=ras_format,
                                       overwrite=TRUE))
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

#' Get DTM or DSM data for a given 5km Ordnance Survey (OS) tile name(s)
#'
#' This function downloads Raster data from the DEFRA portal \url{https://environment.data.gov.uk/DefraDataDownload/?Mode=survey}.
#' It retrieves all available data within the requested area defined by OS_5km_tile and offers some additional functionality to
#' merge and crop the raster if desired. This function uses the get_area function to extract all requested tiles.
#'
#' @param OS_5km_tile A vector of type character containing the names of the desired 5km Tiles. e.g. 'NY20nw' or c('NY20nw','NY20ne').
#' @param resolution a numeric value (in meters) of either: 0.25, 0.5, 1 or 2. <1m data has generally low coverage.
#' @param model_type A character of either 'DTM' or 'DSM' referring to Digital Terrain Model and Digital Surface Model respectively.
#' @param chrome_version The chrome version that best matches your own chrome installation version. Choose from binman::list_versions("chromedriver")
#' @param merge_tiles Boolean with default TRUE. If TRUE a single raster object is returned else a list of raster is produced.
#' @param dest_folder Optional character string for output save folder. If not provided rasters will be stored in tempfile()
#' @param out_name Character required when saving merged raster to dest.folder.
#' @param ras_format Character for Raster format. Default is 'GTiff'. for available formats run terra::gdal(drivers=T)
#' @param headless_chrome Boolean with default TRUE. if FALSE chrome is run with GUI activated.
#' @param check_selenium Boolean with default TRUE. If FAlSE {Rselenium} will not check for updated drivers.
#' @return A SpatRaster (from {terra}) object when merge.tiles = TRUE or a list of rasters when merge.tiles = FALSE
#' @export
get_OS_tile_5km <- function(OS_5km_tile, resolution, model_type, chrome_version=NULL, merge_tiles=TRUE,
                            dest_folder=NULL, out_name=NULL, ras_format="GTiff", headless_chrome=TRUE, check_selenium=TRUE){

  OS_tile_name <- toupper(OS_5km_tile)

  tile_sf <- grid_5km_sf %>%
    dplyr::filter(TILE_NAME %in% OS_tile_name) %>%
    dplyr::summarise()%>%
    sf::st_buffer(-1)

  out_ras <- get_area(poly_area=tile_sf, resolution=resolution, model_type=model_type, chrome_version=chrome_version,
                      merge_tiles=merge_tiles, crop=FALSE, dest_folder=dest_folder, out_name=out_name, ras_format=ras_format,
                      headless_chrome, check_selenium)

  return(out_ras)
}


#' Get DTM or DSM data for a given 10km Ordnance Survey (OS) tile name(s)
#'
#' This function downloads Raster data from the DEFRA portal \url{https://environment.data.gov.uk/DefraDataDownload/?Mode=survey}.
#' It retrieves all available data within the requested area defined by OS_10km_tile and offers some additional functionality to
#' merge and crop the raster if desired. This function uses the get_area function to extract all requested tiles.
#'
#' @param OS_10km_tile A vector of type character containing the names of the desired 5km Tiles. e.g. 'NY20' or c('NY20','NY20').
#' @param resolution a numeric value (in meters) of either: 0.25, 0.5, 1 or 2. <1m data has generally low coverage.
#' @param model_type A character of either 'DTM' or 'DSM' referring to Digital Terrain Model and Digital Surface Model respectively.
#' @param chrome_version The chrome version that best matches your own chrome installation version. Choose from binman::list_versions("chromedriver")
#' @param merge_tiles Boolean with default TRUE. If TRUE a single raster object is returned else a list of raster is produced.
#' @param dest_folder Optional character string for output save folder. If not provided rasters will be stored in tempfile()
#' @param out_name Character required when saving merged raster to dest.folder.
#' @param ras_format Character for Raster format. Default is 'GTiff'. for available formats run terra::gdal(drivers=T)
#' @param headless_chrome Boolean with default TRUE. if FALSE chrome is run with GUI activated.
#' @param check_selenium Boolean with default TRUE. If FAlSE {Rselenium} will not check for updated drivers.
#' @return A SpatRaster (from {terra}) object when merge.tiles = TRUE or a list of rasters when merge.tiles = FALSE
#' @export
get_OS_tile_10km <- function(OS_10km_tile, resolution, model_type, chrome_version=NULL, merge_tiles=TRUE,
                            dest_folder=NULL, out_name=NULL, ras_format="GTiff", headless_chrome=TRUE, check_selenium=TRUE){

  OS_tile_name <- toupper(OS_10km_tile)

  tile_sf <- grid_10km_sf %>%
    dplyr::filter(TILE_NAME %in% OS_tile_name) %>%
    dplyr::summarise()%>%
    sf::st_buffer(-1)

  out_ras <- get_area(poly_area=tile_sf, resolution=resolution, model_type=model_type, chrome_version=chrome_version,
                      merge_tiles=merge_tiles, crop=FALSE, dest_folder=dest_folder, out_name=out_name, ras_format=ras_format,
                      headless_chrome, check_selenium)

  return(out_ras)
}


#' Get DTM or DSM data from an X Y location
#'
#' This function downloads Raster data from the DEFRA portal \url{https://environment.data.gov.uk/DefraDataDownload/?Mode=survey}.
#' It retrieves all available data within the requested area defined by 'xy' and 'radius' arguments and offers some additional functionality to
#' merge and crop the raster if desired. This function uses the get_tile function to extract all tiles that intersect the
#' desired region.
#'
#' @param xy A vector of length 2 with XY coordinates using OSGB/British National (EPSG:27700). e.g. c(321555, 507208)
#' @param radius The radius (in meters) of the buffer to be used to define the limits of the downloaded data
#' @param resolution a numeric value (in meters) of either: 0.25, 0.5, 1 or 2. <1m data has generally low coverage.
#' @param model_type A character of either 'DTM' or 'DSM' referring to Digital Terrain Model and Digital Surface Model respectively.
#' @param chrome_version The chrome version that best matches your own chrome installation version. Choose from binman::list_versions("chromedriver")
#' @param merge_tiles Boolean with default TRUE. If TRUE a single raster object is returned else a list of raster is produced.
#' @param crop Boolean with default FALSE. If TRUE data outside the bounds of the requested polygon area are discarded.
#' @param dest_folder Optional character string for output save folder. If not provided rasters will be stored in tempfile()
#' @param out_name Character required when saving merged raster to dest.folder.
#' @param ras_format Character for Raster format. Default is 'GTiff'. for available formats run terra::gdal(drivers=T)
#' @param headless_chrome Boolean with default TRUE. if FALSE chrome is run with GUI activated.
#' @param check_selenium Boolean with default TRUE. If FAlSE {Rselenium} will not check for updated drivers.
#' @return A SpatRaster (from {terra}) object when merge.tiles = TRUE or a list of rasters when merge.tiles = FALSE
#' @export
get_from_xy <- function(xy, radius, resolution, model_type, chrome_version = NULL,
                        merge_tiles=TRUE, crop=TRUE, dest_folder=NULL, out_name=NULL, ras_format="GTiff",
                        headless_chrome=TRUE, check_selenium=TRUE){

  point <- sf::st_point(xy)

  d <- data.frame(id = 1)
  d$geom <- sf::st_sfc(point)
  req_area <- sf::st_as_sf(d, crs = 27700, agr = "constant") %>%
    sf::st_buffer(., radius)

  out_ras <- get_area(poly_area=req_area, resolution=resolution, model_type=model_type, chrome_version=chrome_version,
                      merge_tiles=merge_tiles, crop=crop, dest_folder=dest_folder, out_name=out_name, ras_format=ras_format,
                      headless_chrome, check_selenium)

  return(out_ras)


}


