# devtools::document()
devtools::load_all() # loads package functions
# library(EAlidaR)
#create the zipped files for uploading to the defra portal:
contain_direc<- system.file("data-raw", package = "EAlidaR")
grid_zip_folder<- system.file("data-raw", "grid_shp_zip", package = "EAlidaR")

# create_zip_tiles(out.path = contain_direc)


## Scraping the required tile Arc Web Map IDs

#conda env paths
conda.p <- 'C:/Users/hughg/Miniconda3/envs/R_python'
# conda.p <- 'C:/Users/hg340/AppData/Local/Continuum/miniconda3/envs/R_python'

#conda env name
env.n <- 'R_python'

# Download Gecko Driver from here: https://github.com/mozilla/geckodriver/releases
gecko.e <- 'C:/install_files/gecko/geckodriver-v0.27.0-win64/geckodriver.exe'
# gecko.e <- 'C:/Installation_Files/gecko/geckodriver-v0.27.0-win64/geckodriver.exe'

py_out <- scrape_tile_IDs(conda_path = conda.p, env_name = env.n, zip_shp_folder = grid_zip_folder, gecko_exe = gecko.e)

# # Check results
py_out$error_log
py_out$arc_ids
review_scrape <- check_tiles(py_out)

review_scrape$tile_plot
review_scrape$missing_tile_df
#
# # run again to mop up where errors have occurred - use 'previous' arg to include last output...
py_out2 <- scrape_tile_IDs(conda_path = conda.p, env_name = env.n, zip_shp_folder = grid_zip_folder, gecko_exe = gecko.e, previous=py_out)

# py_out3 <- scrape_tile_IDs(conda_path = conda.p, env_name = env.n, zip_shp_folder = grid_zip_folder, gecko_exe = gecko.e, previous=py_out2)

review_scrape <- check_tiles(py_out2)
review_scrape$tile_plot
review_scrape$missing_tile_df
# review_scrape$tile_plot

int_direc<- system.file("data-raw", "int_files", package = "EAlidaR")

save_arc_IDs(py_out2, out.path = file.path(int_direc,'py_scrape_out.rds'))
#
sf_save_obj <- scrape_to_sf(py_out2, out.path = file.path(int_direc,'sf_grid_ids.rds'))

coverage_10km_sf <- sf_save_obj$cover_sf

usethis::use_data(coverage_10km_sf, tile_within10km, internal=TRUE, overwrite = TRUE)
