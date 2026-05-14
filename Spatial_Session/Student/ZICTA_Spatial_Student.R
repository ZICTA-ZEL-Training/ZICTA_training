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

# Download Zambia administrative boundaries from GADM.
# GADM (Global Administrative Areas Database) is a high-resolution database of
# the world's administrative boundaries. It provides freely downloadable
# shapefiles and R data objects for every country, making it one of the most
# used sources for boundary spatial data in research and policy work.
# gadm() needs internet. level = 1 → provinces, level = 2 → districts.
zmb_provinces_raw <- gadm("ZMB", level = 1, path = tempdir())
zmb_districts_raw <- gadm("ZMB", level = 2, path = tempdir())

# gadm() returns a SpatVector (vector data class used by the terra package).
# Convert to sf for ggplot2 and leaflet.
zmb_provinces <- st_as_sf(zmb_provinces_raw)
zmb_districts <- st_as_sf(zmb_districts_raw)

# Verify: should return 10
nrow(zmb_provinces)

# Check GADM province names
sort(zmb_provinces$NAME_1)

# Load training datasets
coverage <- read_csv("Datasets/zicta_coverage_by_province.csv")
towers   <- read_csv("Datasets/zicta_towers.csv")
usaf     <- read_csv("Datasets/zicta_usaf_projects.csv")

# coverage — 10 rows, one per province. Columns: province,
#   internet_penetration_pct, mobile_coverage_pct, broadband_per_100,
#   population_2022. Lusaka leads at 67.8%; Muchinga is lowest at 9.8%.
#
# towers   — 72 rows, one per licensed tower. Columns: tower_id, operator,
#   license_type, latitude, longitude, province, district, year_installed.
#   Four operators: Airtel Zambia, MTN Zambia, ZAMTEL, Liquid Telecom.
#
# usaf     — 30 rows, one per Universal Access and Service Fund (USAF) project.
#   Columns: project_id, project_name, province, district, latitude, longitude,
#   budget_usd, start_year, status, target_population.
#   Status: Completed / Ongoing / Planned.

# ============================================================
# SECTION 1 — SPATIAL DATA FUNDAMENTALS
# [09:50 — 10:20]
# ============================================================

# ── 1.1  The sf object ───────────────────────────────────────────────────────

class(zmb_provinces)
#> [1] "sf"         "data.frame"

# sf objects behave like data frames — familiar verbs work unchanged
glimpse(zmb_provinces)

# The geometry column is "sticky": it follows the data even when you don't
# select it, so you never accidentally lose the spatial information.
zmb_provinces %>%
  filter(NAME_1 == "Lusaka") %>%
  select(NAME_1, COUNTRY)

# [PAUSE] What is the "geometry" column? Why is it still there after select()?

# ── 1.2  Coordinate Reference Systems ────────────────────────────────────────

# Check the current CRS
st_crs(zmb_provinces)
#> User input: WGS 84    (EPSG:4326 — degrees, for DISPLAY)

# Transform to UTM Zone 35S for Zambia (EPSG:32735 — metres, for MEASURING)
# We need metres to calculate meaningful distances and areas. Degrees are
# meaningless for measurement — they vary in size depending on latitude.
zmb_provinces_utm <- zmb_provinces %>%
  st_transform(crs = ___)    # ← BLANK A: which EPSG for measuring in Zambia?

st_crs(zmb_provinces_utm)$input
#> [1] "EPSG:32735"

# Demonstrate: why CRS matters for area calculations
# Wrong CRS = wrong numbers = wrong policy conclusions
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
# [10:30 — 11:00]  ← slides at 10:30, code after break at ~10:40
# ============================================================

# ── 2.1  Joining ZICTA data to the spatial layer ─────────────────────────────

# Step 1: Compare province names BEFORE joining — spot any differences.
# A single spelling mismatch causes a silent NA that makes an entire province
# disappear from your map.
sort(zmb_provinces$NAME_1)   # GADM spelling (authoritative)
sort(coverage$province)       # Our CSV spelling
# Look carefully at every name. Do all 10 match exactly?

# Step 2: Join — same left_join from Module 10. The geometry column survives
# the join because the left table is an sf object.
provinces_mapped <- zmb_provinces %>%
  left_join(coverage, by = c("___" = "province"))    # ← BLANK C: which column in zmb_provinces?

# Step 3: Validate — any province name printed here = a mismatch to fix
provinces_mapped %>%
  st_drop_geometry() %>%
  filter(is.na(___)) %>%                             # ← BLANK D: which column to check for NAs?
  pull(NAME_1)
#> [1] "North-Western"

# "North-Western" appears because the CSV spells it "Northwestern" (no hyphen).
# GADM is the authority — we fix our CSV to match, not the other way around.
coverage <- coverage %>%
  mutate(province = case_when(
    province == "Northwestern" ~ "North-Western",
    TRUE ~ province
  ))

provinces_mapped <- zmb_provinces %>%
  left_join(coverage, by = c("NAME_1" = "province"))

# Verify — should now return character(0)
provinces_mapped %>%
  st_drop_geometry() %>%
  filter(is.na(internet_penetration_pct)) %>%
  pull(NAME_1)
#> character(0)

# [PAUSE] Why is Step 3 essential? What would the map look like if you skipped it?

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

# direction = -1 reverses the palette: darker = lower penetration.
# This draws the reader's eye to underserved areas — the policy-relevant
# provinces — rather than the well-connected ones.
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

# Faceting lets us compare two indicators on the same scale and palette,
# making differences immediately visible.
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
# SECTION 3 — SPATIAL JOINS AND COVERAGE GAP ANALYSIS
# [11:00 — 11:15]
# ============================================================

# ── 3.1  Convert tower CSV to spatial points ─────────────────────────────────

# Our tower data is a plain CSV with latitude and longitude columns. To use
# spatial operations (st_join, st_distance, plotting on a map), we need to
# convert it to an sf object.
#
# CRITICAL: coords = c("longitude", "latitude") — X (lon) BEFORE Y (lat).
# This follows the mathematical convention (x, y). Swapping them places all
# 72 towers in the southern Atlantic Ocean — and R does NOT warn you.
# crs = 4326 because these are GPS coordinates (degrees).
towers_sf <- towers %>%
  st_as_sf(coords = c("___", "___"), crs = ___)    # ← BLANK G: column names + CRS

# Quick geometry check — points should appear within Zambia
plot(st_geometry(towers_sf), axes = TRUE)
plot(st_geometry(zmb_provinces), add = TRUE)

# [PAUSE] Do all 72 towers fall inside Zambia?

# ── 3.2  st_join: point-in-polygon ──────────────────────────────────────────

# Unlike left_join (which needs a shared column name), st_join uses geography
# as the join key — each point inherits the attributes of whichever polygon
# it falls inside. No shared column needed.
#
# We select only the province name from the polygon layer — keeping all GADM
# columns would add unnecessary metadata to our tower data.
towers_enriched <- towers_sf %>%
  st_join(zmb_provinces %>% select(___))             # ← BLANK E: which column to keep?

# Validate: does the province from GPS (spatial join) match the province
# stated in the CSV? This catches GPS transcription errors in infrastructure
# registries — a common data quality issue in real ZICTA data.
towers_enriched %>%
  st_drop_geometry() %>%
  select(tower_id, operator, province, NAME_1) %>%
  mutate(match = province == NAME_1) %>%
  count(match)
#> match     n
#> TRUE     72   ← all 72 towers correctly placed

# [PAUSE] What would it mean if some rows showed match = FALSE?

# ── 3.3  Aggregating points to province level ───────────────────────────────

towers_per_province <- towers_enriched %>%
  st_drop_geometry() %>%
  count(NAME_1, name = "n_towers") %>%
  rename(province = NAME_1)

# Provinces with no towers get NA from the join. On a map, NA renders as
# transparent — the province disappears entirely. We replace NA with the
# correct value: zero towers.
provinces_towers <- zmb_provinces %>%
  left_join(towers_per_province, by = c("NAME_1" = "province")) %>%
  mutate(n_towers = replace_na(n_towers, ___))       # ← BLANK F: what value for missing towers?

ggplot(provinces_towers) +
  geom_sf(aes(fill = n_towers), colour = "white", linewidth = 0.4) +
  geom_sf_text(aes(label = paste0(NAME_1, "\n(", n_towers, ")")),
               size = 2.0, colour = "grey20") +
  scale_fill_distiller(palette = "Blues", direction = 1, name = "Towers") +
  labs(title = "ZICTA-Licensed Tower Count by Province") +
  theme_void()

# [PAUSE] Which provinces have the most towers? The fewest? Does this
#         pattern match what you saw in the internet penetration map?

# ── 3.4  Coverage gap analysis ───────────────────────────────────────────────

# The key regulatory question: where should USAF invest next?
# Provinces with BOTH low internet penetration AND few towers are the
# highest priority — they lack both demand-side adoption and supply-side
# infrastructure.
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

# A binary priority map is clearer for decision-makers than a continuous scale.
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

# ── 3.5  Distance calculations ── [REFERENCE: explore after session] ────────

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
# SECTION 4 — INTERACTIVE MAPS WITH leaflet
# REFERENCE — not covered in the live session. Read through
# and run on your own after the training.
# ============================================================

# ── 4.1  Build a colour palette and basic choropleth ─────────────────────────

# colorNumeric() is leaflet's equivalent of scale_fill_viridis_c().
# The tilde (~) in leaflet means "evaluate as a formula on the data."
pal_internet <- colorNumeric(
  palette = "plasma",
  domain  = provinces_mapped$internet_penetration_pct,
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

# ── 4.2  Hover highlights and HTML popups ─────────────────────────────────────

# CartoDB.Positron gives a cleaner background than the default OSM tiles.
# highlightOptions() controls the hover border effect.
# lapply(htmltools::HTML) tells leaflet to render <b> tags in the label.
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

# ── 4.3  Tower map with operator colours ─────────────────────────────────────

# colorFactor() is for categorical data (operators), while colorNumeric()
# is for continuous data (penetration percentages).
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

# ── 4.4  Layered map with operator toggles ───────────────────────────────────

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
# SECTION 5 — CAPSTONE
# Your group's repository: github.com/ZICTA-ZEL-Training/ZICTA_capstone_[team]
# Use the patterns from Sections 1–4 to build your analysis.
# ============================================================

# Suggested file structure for your capstone repo:
#   01_data_cleaning.R      — load, inspect, join data
#   02_maps_ggplot.R        — static choropleth maps
#   03_maps_leaflet.R       — interactive maps
