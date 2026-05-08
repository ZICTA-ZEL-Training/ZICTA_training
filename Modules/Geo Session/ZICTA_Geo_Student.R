###############################################################################
# ZICTA R Training Programme — Spatial Data Analysis Session
# Student Script: Geospatial Analysis with sf and leaflet
# Fill in each ___ to complete the exercise.
# Do NOT skip the [PAUSE] markers — stop, render, check, then continue.
###############################################################################


# ============================================================
# SECTION 0 — SETUP
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

# Verify: should return 10 provinces
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
# [0:00 — 0:45]
# ============================================================

# ── 1.1  The sf object ───────────────────────────────────────────────────────

class(zmb_provinces)
#> [1] "sf"         "data.frame"

# sf objects behave like data frames — use familiar verbs
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
    area_wrong_units = as.numeric(st_area(geometry)) / 1e6,          # degrees² — wrong
    area_sqkm        = as.numeric(st_area(
                         st_transform(geometry, ___)                  # ← BLANK B: correct EPSG
                       )) / 1e6
  )

zmb_provinces %>%
  st_drop_geometry() %>%
  select(NAME_1, area_wrong_units, area_sqkm) %>%
  arrange(desc(area_sqkm))

# [PAUSE] What is the unit of area_wrong_units? What is area_sqkm?
#         Rule: always st_transform() to ___ before measuring distances or areas.

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
# [0:45 — 1:45]
# ============================================================

# ── 2.1  Joining ZICTA data to the spatial layer ─────────────────────────────

# First check: do province names align exactly?
sort(zmb_provinces$NAME_1)
sort(coverage$province)

# Perform the join — the left table is sf, so the result is also sf
provinces_mapped <- zmb_provinces %>%
  left_join(coverage, by = c("___" = "province"))    # ← BLANK C: which column in zmb_provinces?

# Validate: NAs here mean a name mismatch
provinces_mapped %>%
  st_drop_geometry() %>%
  filter(is.na(___)) %>%                             # ← BLANK D: which column to check for NAs?
  pull(NAME_1)
#> character(0)   ← good: no mismatches

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

# Compute province centroids for labels (using UTM for accuracy, then back to 4326)
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

# [PAUSE] Mobile coverage is much higher than internet penetration everywhere.
#         What explains this gap? Discuss with your group.

# [ACTIVITY — 5 min] Modify the faceted map to show broadband_per_100.


# ============================================================
# SECTION 3 — INTERACTIVE MAPS WITH leaflet
# [1:45 — 2:45]
# ============================================================

# ── 3.1  Build a colour palette and basic choropleth ─────────────────────────

# colorNumeric() is leaflet's equivalent of scale_fill_viridis_c()
# It takes a palette name and a domain (the range of values to map colours onto)
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

# [PAUSE] Hover to see labels. Click provinces to see popup content.

# ── 3.3  Convert tower CSV to spatial and plot ────────────────────────────────

# CRITICAL: coords = c("longitude", "latitude") — X (lon) BEFORE Y (lat)
# Swapping these places all points in the wrong location. R does NOT warn you.
towers_sf <- towers %>%
  st_as_sf(coords = c("___", "___"), crs = ___)    # ← BLANK G: column names + CRS

class(towers_sf)
#> [1] "sf"  "tbl_df"  "tbl"  "data.frame"

# Quick geometry check — points should appear within Zambia
plot(st_geometry(towers_sf), axes = TRUE)
plot(st_geometry(zmb_provinces), add = TRUE)

# Colour by operator (colorFactor = categorical palette)
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

# ── 3.4  Layered map with operator toggles ────────────────────────────────────

leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data        = provinces_mapped,
    fillColor   = ~pal_internet(internet_penetration_pct),
    fillOpacity = 0.55, color = "white", weight = 1.2,
    group       = "Internet Penetration"
  ) %>%
  addCircleMarkers(
    data      = towers_sf %>% filter(operator == "Airtel Zambia"),
    radius = 5, color = "#E41A1C", fillColor = "#E41A1C",
    fillOpacity = 0.9, stroke = FALSE,
    popup     = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group     = "Airtel Zambia"
  ) %>%
  addCircleMarkers(
    data      = towers_sf %>% filter(operator == "MTN Zambia"),
    radius = 5, color = "#377EB8", fillColor = "#377EB8",
    fillOpacity = 0.9, stroke = FALSE,
    popup     = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group     = "MTN Zambia"
  ) %>%
  addCircleMarkers(
    data      = towers_sf %>% filter(operator == "ZAMTEL"),
    radius = 5, color = "#4DAF4A", fillColor = "#4DAF4A",
    fillOpacity = 0.9, stroke = FALSE,
    popup     = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group     = "ZAMTEL"
  ) %>%
  addCircleMarkers(
    data      = towers_sf %>% filter(operator == "Liquid Telecom"),
    radius = 5, color = "#FF7F00", fillColor = "#FF7F00",
    fillOpacity = 0.9, stroke = FALSE,
    popup     = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group     = "Liquid Telecom"
  ) %>%
  addLayersControl(
    overlayGroups = c("Internet Penetration", "Airtel Zambia", "MTN Zambia",
                      "ZAMTEL", "Liquid Telecom"),
    options       = layersControlOptions(collapsed = FALSE)
  )

# [PAUSE] Toggle operator layers. Which operator has widest rural reach?


# ============================================================
# SECTION 4 — SPATIAL JOINS AND COVERAGE GAP ANALYSIS
# [2:45 — 3:30]
# ============================================================

# ── 4.1  st_join: point-in-polygon ───────────────────────────────────────────

# st_join() adds attributes from the RIGHT object to each row in the LEFT object
# based on geographic location (point falls inside polygon → inherits its attributes)
towers_enriched <- towers_sf %>%
  st_join(___)                                      # ← BLANK H: which spatial object to join?
  # Hint: we want each tower to inherit its province's NAME_1

towers_enriched %>%
  st_drop_geometry() %>%
  select(tower_id, operator, province, NAME_1) %>%
  mutate(match = province == NAME_1) %>%
  count(match)
#> # A tibble: 1 × 2
#>   match     n
#>   <lgl> <int>
#> 1 TRUE     72   ← all 72 towers correctly placed

# ── 4.2  Aggregating points to polygons ──────────────────────────────────────

towers_per_province <- towers_enriched %>%
  st_drop_geometry() %>%
  count(NAME_1, name = "n_towers") %>%
  rename(province = NAME_1)

provinces_towers <- zmb_provinces %>%
  left_join(towers_per_province, by = c("NAME_1" = "province")) %>%
  mutate(n_towers = replace_na(n_towers, ___))      # ← BLANK I: what value for provinces with no towers?

ggplot(provinces_towers) +
  geom_sf(aes(fill = n_towers), colour = "white", linewidth = 0.4) +
  geom_sf_text(aes(label = paste0(NAME_1, "\n(", n_towers, ")")),
               size = 2.0, colour = "grey20") +
  scale_fill_distiller(palette = "Blues", direction = 1, name = "Towers") +
  labs(title = "ZICTA-Licensed Tower Count by Province") +
  theme_void()

# [PAUSE] Which provinces have the fewest towers? Compare to the internet penetration map.

# ── 4.3  Coverage gap analysis ────────────────────────────────────────────────

coverage_gap <- provinces_towers %>%
  left_join(coverage, by = c("NAME_1" = "province")) %>%
  mutate(
    towers_per_million = round((n_towers / population_2022) * 1e6, 1),
    priority_flag      = internet_penetration_pct < 20 & n_towers < 8
  )

# Priority provinces: low penetration AND low tower density
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

# Distance requires a projected CRS — always transform FIRST
lusaka_centroid <- zmb_provinces %>%
  filter(NAME_1 == "Lusaka") %>%
  st_transform(___) %>%                             # ← BLANK J: which CRS for measuring?
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

# [PAUSE] Which province has towers furthest from Lusaka?
# [ACTIVITY — 3 min] Flag towers more than 500 km from Lusaka.


# ============================================================
# SECTION 5 — CAPSTONE EXERCISE
# [3:30 — 5:00]
# ============================================================
# Work in your functional group. Produce one publication-ready map.
# Use the starter code below for your group. Fill in all ___ blanks.
# Presentation: 2 minutes per group at the end.

# ── GROUP A: ENGINEERING ──────────────────────────────────────────────────────
# Filter to ZAMTEL only. Map ZAMTEL coverage by province.
# Flag towers more than 500 km from Lusaka.

zamtel_towers <- towers_sf %>%
  filter(operator == "___")                         # ← BLANK K

zamtel_per_province <- zamtel_towers %>%
  st_join(zmb_provinces %>% select(NAME_1)) %>%
  st_drop_geometry() %>%
  count(NAME_1, name = "n_zamtel") %>%
  rename(province = NAME_1)

provinces_zamtel <- zmb_provinces %>%
  left_join(zamtel_per_province, by = c("NAME_1" = "province")) %>%
  mutate(n_zamtel = replace_na(n_zamtel, 0))

# Build an interactive leaflet map showing ZAMTEL tower density by province
# and mark towers that are >500 km from Lusaka in a different colour
# ... (continue building from Section 3 and 4 patterns)


# ── GROUP B: STATISTICAL UNIT ─────────────────────────────────────────────────
# Faceted choropleth of all 4 indicators. Quantify inequality (max/min ratio).

stat_data <- provinces_mapped %>%
  left_join(towers_per_province, by = c("NAME_1" = "province")) %>%
  mutate(
    n_towers           = replace_na(n_towers, 0),
    towers_per_million = round((n_towers / population_2022) * 1e6, 1)
  )

stat_long <- stat_data %>%
  select(NAME_1, internet_penetration_pct, mobile_coverage_pct,
         broadband_per_100, towers_per_million, geometry) %>%
  pivot_longer(
    cols      = c(internet_penetration_pct, mobile_coverage_pct,
                  broadband_per_100, towers_per_million),
    names_to  = "___",                              # ← BLANK L
    values_to = "value"
  )

ggplot(stat_long) +
  geom_sf(aes(fill = value), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "plasma", direction = -1, name = "Value") +
  facet_wrap(~ ___) +                               # ← BLANK M: facet by the names column
  labs(title = "ZICTA ICT Indicators by Province, Zambia 2022") +
  theme_void(base_size = 10) +
  theme(strip.text = element_text(face = "bold"), legend.position = "bottom")

# Calculate max/min inequality ratio
stat_data %>%
  st_drop_geometry() %>%
  summarise(
    internet_ratio  = max(internet_penetration_pct) / min(internet_penetration_pct),
    coverage_ratio  = max(mobile_coverage_pct)       / min(mobile_coverage_pct),
    broadband_ratio = max(broadband_per_100)          / min(broadband_per_100),
    towers_ratio    = max(towers_per_million)         / min(towers_per_million)
  )


# ── GROUP C: FINANCIAL STATISTICS ─────────────────────────────────────────────
# Join compliance scores to provinces. Map and explore the relationship
# with internet penetration.

telecoms <- read_csv("../../ZICTA Training 2026/Datasets/Sample data_telecoms.csv")

compliance_by_province <- telecoms %>%
  group_by(___) %>%                                 # ← BLANK N: group by the region/province column
  summarise(avg_compliance = round(mean(compliance_score, na.rm = TRUE), 1)) %>%
  rename(province = region)

provinces_compliance <- zmb_provinces %>%
  left_join(compliance_by_province, by = c("NAME_1" = "province")) %>%
  left_join(coverage, by = c("NAME_1" = "province"))

ggplot(provinces_compliance) +
  geom_sf(aes(fill = avg_compliance), colour = "white", linewidth = 0.4) +
  scale_fill_distiller(palette = "RdYlGn", direction = 1,
                       name = "Avg compliance\nscore") +
  geom_sf_text(aes(label = paste0(NAME_1, "\n", avg_compliance)), size = 2.0) +
  labs(title = "Average Operator Compliance Score by Province") +
  theme_void()


# ── GROUP D: POSTAL SERVICES ─────────────────────────────────────────────────
# Interactive leaflet map of USAF projects, coloured by status.
# Circle size proportional to budget.

usaf_sf <- usaf %>%
  st_as_sf(coords = c("___", "___"), crs = ___)    # ← BLANK O: lon/lat columns + CRS

status_colours <- colorFactor(
  palette = c("Completed" = "#27ae60", "Ongoing" = "#2980b9", "Planned" = "#e67e22"),
  domain  = usaf_sf$status
)

leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(data = zmb_provinces, fillColor = "transparent",
              color = "grey60", weight = 1, label = ~NAME_1) %>%
  addCircleMarkers(
    data        = usaf_sf,
    radius      = ~sqrt(budget_usd / 10000),
    color       = ~status_colours(___),             # ← BLANK P: which column for colour?
    fillColor   = ~status_colours(status),
    fillOpacity = 0.8, stroke = TRUE, weight = 1,
    popup       = ~paste0(
      "<b>", project_name, "</b><br>",
      province, " | ", district, "<br>",
      "Budget: $", format(budget_usd, big.mark = ","), "<br>",
      "Status: ", status
    )
  ) %>%
  addLegend(pal = status_colours, values = usaf_sf$status,
            title = "Project status")


# ── GROUP E: UNIVERSAL ACCESS ─────────────────────────────────────────────────
# Identify provinces that are both digitally underserved AND underfunded by USAF.

usaf_by_province <- usaf %>%
  group_by(province) %>%
  summarise(
    total_budget     = sum(budget_usd),
    n_projects       = n(),
    total_target_pop = sum(target_population)
  )

provinces_usaf <- zmb_provinces %>%
  left_join(usaf_by_province, by = c("NAME_1" = "province")) %>%
  left_join(coverage,         by = c("NAME_1" = "province")) %>%
  mutate(
    total_budget  = replace_na(total_budget, ___),  # ← BLANK Q: what value for provinces with no projects?
    n_projects    = replace_na(n_projects, 0),
    underinvested = internet_penetration_pct < 20 & total_budget < 500000
  )

# Map priority provinces
ggplot(provinces_usaf) +
  geom_sf(aes(fill = underinvested), colour = "white", linewidth = 0.4) +
  scale_fill_manual(
    values = c("FALSE" = "#aec6e8", "TRUE" = "#c0392b"),
    labels = c("FALSE" = "Adequately covered or funded",
               "TRUE"  = "Priority: underserved & underfunded"),
    name   = ""
  ) +
  geom_sf_text(aes(label = NAME_1), size = 2.2, colour = "grey20") +
  labs(
    title    = "USAF Priority Targeting: Underserved and Underfunded Provinces",
    subtitle = "Priority = internet penetration < 20% AND USAF investment < $500k",
    caption  = "Source: ZICTA 2022 ICT Indicators & USAF project database"
  ) +
  theme_void() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"))

# Summary table
provinces_usaf %>%
  st_drop_geometry() %>%
  filter(underinvested) %>%
  select(NAME_1, internet_penetration_pct, total_budget, n_projects,
         total_target_pop, population_2022) %>%
  mutate(pct_pop_targeted = round(total_target_pop / population_2022 * 100, 1)) %>%
  arrange(internet_penetration_pct)


###############################################################################
# BLANK ANSWERS (reference — cover during the session)
# A: 32735    B: 32735    C: NAME_1          D: internet_penetration_pct
# E: "plasma" F: provinces_mapped$internet_penetration_pct
# G: c("longitude", "latitude"), crs = 4326
# H: zmb_provinces %>% select(NAME_1)
# I: 0        J: 32735    K: "ZAMTEL"        L: "indicator"
# M: indicator N: region  O: c("longitude","latitude"), crs = 4326
# P: status   Q: 0
###############################################################################
