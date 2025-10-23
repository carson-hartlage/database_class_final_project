library(sf)
library(dplyr)

dep_index <- 'https://github.com/geomarker-io/dep_index/raw/master/2023/data/ACS_deprivation_index_by_census_tracts.rds' %>% 
  url() %>% 
  gzcon() %>% 
  readRDS() %>% 
  as_tibble() |>
  filter(substr(census_tract_id_2020, 1, 2) == "39",
         substr(census_tract_id_2020, 3, 5) %in% c("061"))

cincy_tracts <- cincy::tract_tigris_2020

tracts <- cincy::tract_tigris_2020 |>
  left_join(dep_index, by = "census_tract_id_2020") |>
  st_as_sf() |>
  select(census_tract_id_2020, dep_index)

all_geo <- df |>
  st_as_sf(coords = c("LONGITUDE", "LATITUDE"), crs = 4326) |>
  st_transform(st_crs(cincy_tracts)) |>
  st_join(cincy_tracts) |>
  st_drop_geometry()



####
library(addr)
d_cagis <-
  codec::cincy_addr_geo() |>
  mutate(cagis_addr = as_addr(cagis_address)) |>
  #select(cagis_parcel_id, cagis_addr, cagis_address_type) |>
  sf::st_drop_geometry() |>
  unique() |>
  nest_by(cagis_addr, .key = "cagis_addr_data")
