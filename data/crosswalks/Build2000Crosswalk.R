rm(list = ls())

library(tidyverse)
library(sf)

# wards drawn in 2002
wards.2002 <- st_read("data/ward-shp/MilwaukeeCounty_2002.geojson")

################################################################################
# intersect 2000 blocks with 2002 wards

# here are the block polygons, retrieved from the Census API
block.shp.2000 <- tidycensus::get_decennial(geography = "block",
                                            variables = "P003001",
                                            year = 2000,
                                            state = "WI",
                                            county = "MILWAUKEE",
                                            geometry = TRUE)

# convert the polygons to centroid points
block.point.2000 <- block.shp.2000 %>%
  select(block_2000 = GEOID, total_pop = value) %>%
  st_transform(crs = st_crs(wards.2002)) %>%
  # st_point_on_surface ensures that the center point is WITHIN the polygon(s)
  mutate(geometry = st_point_on_surface(geometry))

# perform the intersection (this may take some time)
block2000.ward2002.int <- block.point.2000 %>%
  st_intersection(wards.2002) %>%
  st_drop_geometry()

# not all the blocks fell within a ward polygon
compare.block.intersections <- block.point.2000 %>%
  st_drop_geometry() %>%
  left_join(block2000.ward2002.int) %>%
  select(block_2000, ward_2002 = ward_name, pop_2000 = total_pop)

# confirm that all the unmatched blocks have a population of 0
compare.block.intersections %>%
  filter(is.na(ward_2002)) %>%
  group_by(pop_2000) %>%
  summarise(count = n())
write_csv(compare.block.intersections, "data/crosswalks/Blocks2000_with_Ward2002.csv")
