library(sf)
library(dplyr)

tracts <- cincy::tract_tigris_2020

dep_index <- 'https://github.com/geomarker-io/dep_index/raw/master/2023/data/ACS_deprivation_index_by_census_tracts.rds' %>% 
  url() %>% 
  gzcon() %>% 
  readRDS() %>% 
  as_tibble() |>
  filter(substr(census_tract_id_2020, 1, 2) == "39",
         substr(census_tract_id_2020, 3, 5) %in% c("061"))

tracts <- tracts |>
  left_join(dep_index, by = "census_tract_id_2020") |>
  st_as_sf() |>
  select(census_tract_id_2020, dep_index)

parcels <-
  dpkg::stow("gh://geomarker-io/parcel/cagis_parcels-v1.1.1") |>
  arrow::read_parquet() |>
  select(parcel_id, centroid_lat, centroid_lon) |>
  mutate(s2_geography = s2::s2_geog_point(centroid_lon, centroid_lat)) |>
  st_as_sf()
parcels <- parcels |>
  st_transform(st_crs(tracts)) |>
  st_join(tracts) 

parcels_by_tract <- parcels |>
  st_drop_geometry() |>
  group_by(census_tract_id_2020) |>
  summarise(n_parcels = n()) |>
  ungroup() |>
  filter(!is.na(census_tract_id_2020))

tracts <- tracts |>
  left_join(parcels_by_tract, by = "census_tract_id_2020") |>
  st_drop_geometry()

pop_by_tract <- tidycensus::get_decennial(
  geography = "tract",
  variables = "P1_001N",
  state = "OH",
  county = "Hamilton",
  year = 2020,
  geometry = FALSE) |>
  select(c("GEOID", "value")) |>
  rename("population" = "value")

tracts <- tracts |>
  left_join(pop_by_tract, join_by("census_tract_id_2020" == "GEOID"))


library(DBI)
library(RSQLite)
con <- dbConnect(RSQLite::SQLite(), "final_project.sqlite")
dbWriteTable(con, "tract_data", tracts, overwrite = TRUE)
dbDisconnect(con)
