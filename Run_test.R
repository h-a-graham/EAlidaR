library(raster)

source("./R/get_lidar.R")


save_folder <- 'C:/HG_Projects/SideProjects/EA_Lidar_Check/EA_Download_TEST'

rasOB <- get_tile(resolution = 2, os.tile.name = 'TQ33sw', dest.folder = save_folder, save.tile=TRUE)


# ras <- raster(file.path(save_folder, 'tq3525_DSM_2M.asc'))
plot(rasOB)


# raster::writeRaster(rasOB, filename = file.path(save_folder, 'TQ33sw'), format="GTiff")

rasOB
