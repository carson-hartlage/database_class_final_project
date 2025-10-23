library(dplyr)
library(sf)

d <- read.csv("Cincinnati_311_(Non-Emergency)_Service_Requests_20250821.csv") |>
  mutate(DATE = as.Date(DATE_CREATED, format = "%Y %b %d %I:%M:%S %p")
  ) 

df <- d |>
  filter(DATE >= "2016-01-01" & DATE <= "2024-12-31" & SR_STATUS_FLAG == "CLOSED") |>
  select(c(SR_NUMBER, SR_STATUS_FLAG, SR_TYPE, SR_TYPE_DESC, LATITUDE, LONGITUDE, DATE)) |>
  filter(LATITUDE != "" & LONGITUDE != "") |>
  distinct()

types <- df |>
  group_by(SR_TYPE_DESC) |>
  summarise(n = n(),
            .groups = "drop") |>
  filter(n > 200)

# HOMELESS ENCAMPMENT
# ZONING, CODE ENFORCEMENT RES
housing_health_types <- c(
  "BUILDING, HVAC HAZARD",
  "BUILDING, ILLEGAL USE RES PROP",
  "BUILDING, RESIDENTIAL",
  "BUILDING, VACANT AND OPEN RES",
  "HEAT, NO HEAT HAZARD",
  "HVAC, HEATING ISSUE(S)",
  "HVAC, COOLING ISSUE(S)",
  "MICE, BUILDING HAS MICE",
  "MOLD, BUILDING OR APARTMENT",
  "PLUMBING, DEFECTIVE",
  "RATS, IN A BUILDING",
  "RATS, OUTSIDE A BUILDING",
  "RATS, PROBLEM/INFESTATION",
  "ROACHES - BLDG OR APARTMENT",
  "SEWAGE, IN BUILDING",
  "SEWAGE, SURFACING PRIV PROP",
  "UNSANITARY LIVING CONDITIONS"
)

df <- df |>
  filter(SR_TYPE_DESC %in% housing_health_types)

cincy_tracts <- cincy::tract_tigris_2020

df <- df |>
  st_as_sf(coords = c("LONGITUDE", "LATITUDE"), crs = 4326) |>
  st_transform(st_crs(cincy_tracts)) |>
  st_join(cincy_tracts) |>
  st_drop_geometry()

library(DBI)
library(RSQLite)
con <- dbConnect(RSQLite::SQLite(), "final_project.sqlite")
dbWriteTable(con, "311_reports", df, overwrite = TRUE)
dbDisconnect(con)
