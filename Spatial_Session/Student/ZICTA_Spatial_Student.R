###############################################################################
# ZICTA R Training Programme — Spatial Analysis Session
# Student Script: Spatial Analysis with sf and leaflet
# Fill in each ___ to complete the exercise.
# Do NOT skip the [PAUSE] markers — stop, render, check, then continue.
###############################################################################


# ============================================================
# SECTION 0 — SETUP
# Run before the session starts. Confirm nrow(coverage) == 10.
# ============================================================

# Install required packages (run once, then comment out)
install.packages(c("sf", "geodata", "leaflet", "leaflet.extras",
                   "RColorBrewer", "viridis", "tidyverse"))

# Load packages
library(tidyverse)
library(sf)
library(geodata)
library(leaflet)
library(leaflet.extras)
library(RColorBrewer)
library(viridis)

# Download Zambia administrative boundaries from GADM
# gadm() needs internet. level = 1 → provinces, level = 2 → districts.
zmb_provinces_raw <- gadm("ZMB", level = 1, path = tempdir())
zmb_districts_raw <- gadm("ZMB", level = 2, path = tempdir())

# gadm() returns a SpatVector (terra). Convert to sf for ggplot2 and leaflet.
zmb_provinces <- st_as_sf(zmb_provinces_raw)
zmb_districts <- st_as_sf(zmb_districts_raw)

# Verify: should return 10
nrow(zmb_provinces)
#> [1] 10

# Check GADM province names — must match CSV exactly
sort(zmb_provinces$NAME_1)
#> [1] "Central"       "Copperbelt"    "Eastern"       "Luapula"
#> [5] "Lusaka"        "Muchinga"      "Northern"      "North-Western"
#> [9] "Southern"      "Western"

# Load ZICTA training datasets
coverage <- read_csv("Datasets/zicta_coverage_by_province.csv")
towers   <- read_csv("Datasets/zicta_towers.csv")
usaf     <- read_csv("Datasets/zicta_usaf_projects.csv")


# ============================================================
# SECTION 1 — SPATIAL DATA FUNDAMENTALS
# [09:50 — 10:35]
# ============================================================

# ── 1.1  The sf object ───────────────────────────────────────────────────────

class(zmb_provinces)
#> [1] "sf"         "data.frame"

# sf objects behave like data frames — familiar verbs work unchanged
glimpse(zmb_provinces)

zmb_provinces %>%
  filter(NAME_1 == "Lusaka") %>%
  select(NAME_1, COUNTRY)

# [PAUSE] What is the "geometry" column? Why is it still there after select()?

# ── 1.2  Coordinate Reference Systems ────────────────────────────────────────

# Check the current CRS
st_crs(zmb_provinces)
#> User input: WGS 84    (EPSG:4326 — degrees, for DISPLAY)

# Transform to UTM Zone 35S for Zambia (EPSG:32735 — metres, for MEASURING)
zmb_provinces_utm <- zmb_provinces %>%
  st_transform(crs = ___)    # ← BLANK A: which EPSG for measuring in Zambia?

st_crs(zmb_provinces_utm)$input
#> [1] "EPSG:32735"

# Demonstrate: why CRS matters for area calculations
zmb_provinces <- zmb_provinces %>%
  mutate(
    area_wrong_units = as.numeric(st_area(geometry)) / 1e6,        # degrees² — wrong
    area_sqkm        = as.numeric(st_area(
                         st_transform(geometry, ___)               # ← BLANK B: correct EPSG
                       )) / 1e6
  )

zmb_provinces %>%
  st_drop_geometry() %>%
  select(NAME_1, area_wrong_units, area_sqkm) %>%
  arrange(desc(area_sqkm))

# [PAUSE] What is the unit of area_wrong_units? What is area_sqkm?
#         Rule: always st_transform() to EPSG:___ before measuring distances or areas.

# ── 1.3  Your first map ───────────────────────────────────────────────────────

ggplot(zmb_provinces) +
  geom_sf() +
  labs(title = "Zambia: Provincial Boundaries",
       caption = "Source: GADM") +
  theme_void()

# Add province name labels
ggplot(zmb_provinces) +
  geom_sf(fill = "#f0f0f0", colour = "grey40", linewidth = 0.4) +
  geom_sf_label(aes(label = NAME_1), size = 2.5, fill = "white",
                label.size = 0, label.padding = unit(0.1, "lines")) +
  labs(title = "Zambia — 10 Provinces") +
  theme_void()

# [PAUSE] Check your map against a reference. Does it look correct?
# [ACTIVITY — 2 min] Change fill = to a different colour.


# ============================================================
# SECTION 2 — PROVINCE CHOROPLETH WITH ggplot2 + sf
# [10:45 — 11:20]  ← resumes after 10-min break at 10:35
# ============================================================

# ── 2.1  Joining ZICTA data to the spatial layer ─────────────────────────────

# Always verify names match before joining
sort(zmb_provinces$NAME_1)
sort(coverage$province)

# Left-join: spatial object on the left, ZICTA data on the right
provinces_mapped <- zmb_provinces %>%
  left_join(coverage, by = c("___" = "province"))    # ← BLANK C: which column in zmb_provinces?

# Validate: character(0) = no mismatches. Any names printed here = fix before continuing.
provinces_mapped %>%
  st_drop_geometry() %>%
  filter(is.na(___)) %>%                             # ← BLANK D: which column to check for NAs?
  pull(NAME_1)
#> character(0)

# [PAUSE] What does character(0) mean? What would you do if you saw province names here?

# ── 2.2  Basic choropleth ─────────────────────────────────────────────────────

ggplot(provinces_mapped) +
  geom_sf(aes(fill = internet_penetration_pct)) +
  scale_fill_viridis_c(name = "Internet\npenetration (%)") +
  labs(title = "Internet Penetration by Province, Zambia 2022",
       caption = "Source: ZICTA 2022 | Boundaries: GADM") +
  theme_void()

# [PAUSE] What does this map tell us? Which provinces are highest and lowest?

# ── 2.3  Publication-ready map ────────────────────────────────────────────────

# Compute province centroids for labels (UTM for accuracy, then back to 4326)
province_labels <- zmb_provinces %>%
  st_transform(32735) %>%
  mutate(centroid = st_centroid(geometry)) %>%
  st_drop_geometry() %>%
  rename(geometry = centroid) %>%
  st_as_sf(crs = 32735) %>%
  st_transform(4326)

ggplot() +
  geom_sf(data  = provinces_mapped,
          aes(fill = internet_penetration_pct),
          colour = "white", linewidth = 0.4) +
  geom_sf_text(data  = province_labels,
               aes(label = NAME_1),
               size = 2.2, colour = "white", fontface = "bold") +
  scale_fill_viridis_c(
    name      = "Internet\npenetration (%)",
    option    = "plasma",
    direction = -1,
    labels    = function(x) paste0(x, "%")
  ) +
  labs(
    title    = "Internet Penetration by Province, Zambia 2022",
    subtitle = "Lusaka (67.8%) and Copperbelt (52.1%) far exceed rural provinces",
    caption  = "Source: ZICTA 2022 ICT Indicators | Boundaries: GADM"
  ) +
  theme_void(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14),
        legend.position = "right")

# ── 2.4  Faceted choropleth: comparing two indicators ────────────────────────

provinces_long <- provinces_mapped %>%
  select(NAME_1, internet_penetration_pct, mobile_coverage_pct, geometry) %>%
  pivot_longer(
    cols      = c(internet_penetration_pct, mobile_coverage_pct),
    names_to  = "indicator",
    values_to = "value"
  ) %>%
  mutate(indicator = recode(indicator,
    "internet_penetration_pct" = "Internet Penetration (%)",
    "mobile_coverage_pct"      = "Mobile Network Coverage (%)"
  ))

ggplot(provinces_long) +
  geom_sf(aes(fill = value), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "plasma", direction = -1, name = "Value (%)") +
  facet_wrap(~ indicator) +
  labs(title   = "Digital Connectivity Indicators by Province, Zambia 2022",
       caption = "Source: ZICTA 2022 | Boundaries: GADM") +
  theme_void(base_size = 11) +
  theme(strip.text = element_text(face = "bold"),
        legend.position = "bottom")

# [PAUSE] Mobile coverage is near-universal; internet penetration is much lower
#         in rural areas. What explains this gap?

# [IF TIME ALLOWS] Modify the faceted map to show broadband_per_100 instead
# of mobile_coverage_pct. What story does the new panel tell?


# ============================================================
# SECTION 3 — INTERACTIVE MAPS WITH leaflet
# [11:20 — 11:45]
# ============================================================

# ── 3.1  Build a colour palette and basic choropleth ─────────────────────────

# colorNumeric() is leaflet's equivalent of scale_fill_viridis_c()
pal_internet <- colorNumeric(
  palette = "___",                                  # ← BLANK E: try "plasma", "viridis", or "Blues"
  domain  = ___,                                    # ← BLANK F: which column provides the values?
  reverse = TRUE
)

leaflet(provinces_mapped) %>%
  addTiles() %>%
  addPolygons(
    fillColor   = ~pal_internet(internet_penetration_pct),
    fillOpacity = 0.75,
    color       = "white",
    weight      = 1
  ) %>%
  addLegend(
    pal      = pal_internet,
    values   = ~internet_penetration_pct,
    title    = "Internet Penetration (%)",
    position = "bottomright"
  )

# [PAUSE] Zoom and pan. Compare Western vs Lusaka. Does this match the ggplot map?

# ── 3.2  Hover highlights and HTML popups ─────────────────────────────────────

leaflet(provinces_mapped) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    fillColor   = ~pal_internet(internet_penetration_pct),
    fillOpacity = 0.75,
    color       = "white",
    weight      = 1.5,
    highlight   = highlightOptions(
      weight       = 3,
      color        = "#FFD700",
      bringToFront = TRUE
    ),
    label = ~paste0(
      "<b>", NAME_1, "</b><br>",
      "Internet: <b>", internet_penetration_pct, "%</b><br>",
      "Mobile coverage: ", mobile_coverage_pct, "%"
    ) %>% lapply(htmltools::HTML)
  ) %>%
  addLegend(pal = pal_internet, values = ~internet_penetration_pct,
            title = "Internet (%)", position = "bottomright")

# [PAUSE] Hover over provinces. Which has the widest gap between mobile coverage
#         and internet penetration?

# ── 3.3  Convert tower CSV to spatial and plot ────────────────────────────────

# CRITICAL: coords = c("longitude", "latitude") — X (lon) BEFORE Y (lat)
# Swapping these places all points in the wrong location. R does NOT warn you.
towers_sf <- towers %>%
  st_as_sf(coords = c("___", "___"), crs = ___)    # ← BLANK G: column names + CRS

# Quick geometry check — points should appear within Zambia
plot(st_geometry(towers_sf), axes = TRUE)
plot(st_geometry(zmb_provinces), add = TRUE)

# Colour by operator
operator_colours <- colorFactor(
  palette = c("#E41A1C", "#377EB8", "#4DAF4A", "#FF7F00"),
  domain  = towers_sf$operator
)

leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(data = provinces_mapped, fillColor = "transparent",
              color = "grey60", weight = 1) %>%
  addCircleMarkers(
    data        = towers_sf,
    radius      = 6,
    color       = ~operator_colours(operator),
    fillColor   = ~operator_colours(operator),
    fillOpacity = 0.85,
    stroke      = FALSE,
    popup       = ~paste0(
      "<b>", operator, "</b><br>",
      district, ", ", province, "<br>",
      "Year: ", year_installed
    )
  ) %>%
  addLegend(pal = operator_colours, values = towers_sf$operator, title = "Operator")

# [PAUSE] Click on towers. Are they in the right provinces?

# ── 3.4  Layered map with operator toggles ── [REFERENCE: explore after session]

leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data        = provinces_mapped,
    fillColor   = ~pal_internet(internet_penetration_pct),
    fillOpacity = 0.55, color = "white", weight = 1.2,
    group       = "Internet Penetration"
  ) %>%
  addCircleMarkers(
    data = towers_sf %>% filter(operator == "Airtel Zambia"),
    radius = 5, color = "#E41A1C", fillColor = "#E41A1C",
    fillOpacity = 0.9, stroke = FALSE,
    popup = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group = "Airtel Zambia"
  ) %>%
  addCircleMarkers(
    data = towers_sf %>% filter(operator == "MTN Zambia"),
    radius = 5, color = "#377EB8", fillColor = "#377EB8",
    fillOpacity = 0.9, stroke = FALSE,
    popup = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group = "MTN Zambia"
  ) %>%
  addCircleMarkers(
    data = towers_sf %>% filter(operator == "ZAMTEL"),
    radius = 5, color = "#4DAF4A", fillColor = "#4DAF4A",
    fillOpacity = 0.9, stroke = FALSE,
    popup = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group = "ZAMTEL"
  ) %>%
  addCircleMarkers(
    data = towers_sf %>% filter(operator == "Liquid Telecom"),
    radius = 5, color = "#FF7F00", fillColor = "#FF7F00",
    fillOpacity = 0.9, stroke = FALSE,
    popup = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group = "Liquid Telecom"
  ) %>%
  addLayersControl(
    overlayGroups = c("Internet Penetration", "Airtel Zambia", "MTN Zambia",
                      "ZAMTEL", "Liquid Telecom"),
    options       = layersControlOptions(collapsed = FALSE)
  )


# ============================================================
# SECTION 4 — SPATIAL JOINS AND COVERAGE GAP ANALYSIS
# REFERENCE — not covered in the live session. Read through
# and run on your own after the training.
# ============================================================

# ── 4.1  st_join: point-in-polygon ───────────────────────────────────────────

# st_join() adds attributes from the RIGHT object to each row in the LEFT
# object based on geographic location — no shared key column needed.
towers_enriched <- towers_sf %>%
  st_join(zmb_provinces %>% select(NAME_1))

towers_enriched %>%
  st_drop_geometry() %>%
  select(tower_id, operator, province, NAME_1) %>%
  mutate(match = province == NAME_1) %>%
  count(match)
#> match     n
#> TRUE     72   ← all 72 towers correctly placed

# ── 4.2  Aggregating points to polygons ──────────────────────────────────────

towers_per_province <- towers_enriched %>%
  st_drop_geometry() %>%
  count(NAME_1, name = "n_towers") %>%
  rename(province = NAME_1)

provinces_towers <- zmb_provinces %>%
  left_join(towers_per_province, by = c("NAME_1" = "province")) %>%
  mutate(n_towers = replace_na(n_towers, 0))

ggplot(provinces_towers) +
  geom_sf(aes(fill = n_towers), colour = "white", linewidth = 0.4) +
  geom_sf_text(aes(label = paste0(NAME_1, "\n(", n_towers, ")")),
               size = 2.0, colour = "grey20") +
  scale_fill_distiller(palette = "Blues", direction = 1, name = "Towers") +
  labs(title = "ZICTA-Licensed Tower Count by Province") +
  theme_void()

# ── 4.3  Coverage gap analysis ────────────────────────────────────────────────

coverage_gap <- provinces_towers %>%
  left_join(coverage, by = c("NAME_1" = "province")) %>%
  mutate(
    towers_per_million = round((n_towers / population_2022) * 1e6, 1),
    priority_flag      = internet_penetration_pct < 20 & n_towers < 8
  )

coverage_gap %>%
  st_drop_geometry() %>%
  filter(priority_flag) %>%
  select(NAME_1, internet_penetration_pct, n_towers, towers_per_million) %>%
  arrange(internet_penetration_pct)

ggplot(coverage_gap) +
  geom_sf(aes(fill = priority_flag), colour = "white", linewidth = 0.4) +
  scale_fill_manual(values = c("FALSE" = "#d4e6f1", "TRUE" = "#c0392b"),
                    labels  = c("FALSE" = "Not priority", "TRUE" = "Priority"),
                    name    = "") +
  geom_sf_text(aes(label = NAME_1), size = 2.2, colour = "grey20") +
  labs(title   = "USAF Priority Provinces",
       caption = "Priority: internet penetration < 20% AND fewer than 8 towers") +
  theme_void() +
  theme(legend.position = "bottom")

# ── 4.4  Distance calculations ────────────────────────────────────────────────

lusaka_centroid <- zmb_provinces %>%
  filter(NAME_1 == "Lusaka") %>%
  st_transform(32735) %>%
  st_centroid() %>%
  st_geometry()

towers_utm <- towers_sf %>%
  st_transform(32735) %>%
  mutate(
    dist_lusaka_km = as.numeric(st_distance(geometry, lusaka_centroid)) / 1000
  )

towers_utm %>%
  st_drop_geometry() %>%
  group_by(province) %>%
  summarise(avg_dist_km = round(mean(dist_lusaka_km), 0),
            max_dist_km = round(max(dist_lusaka_km), 0)) %>%
  arrange(desc(avg_dist_km))

# Extension: flag towers more than 500 km from Lusaka
towers_utm %>%
  st_drop_geometry() %>%
  filter(dist_lusaka_km > 500) %>%
  count(operator)


# ============================================================
# SECTION 5 — CAPSTONE
# Your group's repository: github.com/ZICTA-ZEL-Training/ZICTA_capstone_[team]
# Use the patterns from Sections 1–4 to build your analysis.
# ============================================================

# Suggested file structure for your capstone repo:
#   01_data_cleaning.R      — load, inspect, join data
#   02_maps_ggplot.R        — static choropleth maps
#   03_maps_leaflet.R       — interactive maps
