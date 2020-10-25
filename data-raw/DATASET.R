## code to prepare `DATASET` dataset goes here
devtools::load_all()
library(sf)
library(ggplot2)
library(dplyr)

# Exeter City feature load
EngCities <- system.file("extdata", "Major_Towns_and_Cities__December_2015__Boundaries.shp", package = "EAlidaR")

EngCities_sf <- read_sf(EngCities) #
unique(EngCities_sf$tcity15nm)

Exeter_sf <- EngCities_sf %>%
  filter(tcity15nm == 'Exeter') %>%
  st_transform(crs = st_crs(27700))

ggplot(Exeter_sf) +
  geom_sf() +
  theme_bw()

usethis::use_data(Exeter_sf, overwrite = TRUE)

# UNi of exeter feature load
UniOfExe <- system.file("extdata", "UniOfExe.gpkg", package = "EAlidaR")

UniOfExeter_sf <- read_sf(UniOfExe)

ggplot(UniOfExeter_sf) +
  geom_sf() +
  theme_bw()

usethis::use_data(UniOfExeter_sf, overwrite = TRUE)

#Ashop valley feature load
Ashop_gpkg <- system.file("extdata", "Test_Area2.gpkg", package = "EAlidaR")

Ashop_sf <- read_sf(Ashop_gpkg)

ggplot(Ashop_sf) +
  geom_sf() +
  theme_bw()

usethis::use_data(Ashop_sf, overwrite = TRUE)

# city of london feature load
city_of_london_gpkg <- system.file("extdata", "city_of_london.gpkg", package = "EAlidaR")

city_of_london_sf <- read_sf(city_of_london_gpkg)

ggplot(city_of_london_sf) +
  geom_sf() +
  theme_bw()

usethis::use_data(city_of_london_sf, overwrite = TRUE)



