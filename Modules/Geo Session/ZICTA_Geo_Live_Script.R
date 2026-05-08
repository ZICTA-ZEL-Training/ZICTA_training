###############################################################################
# ZICTA R Training Programme — Spatial Data Analysis Session
# Live Coding Script: Geospatial Analysis with sf and leaflet
# Facilitator: Matteo Larrode (IGC) | Re-delivery support: ZEL (Chomba & Kosam)
# Duration: Full day (~6 hours including breaks)
#            Two half-day variant: Day 1 = Sections 0–2 | Day 2 = Sections 3–5
# Datasets:  zicta_coverage_by_province.csv
#            zicta_towers.csv
#            zicta_usaf_projects.csv
#            Zambia boundaries downloaded directly in R via geodata::gadm()
###############################################################################
#
# HOW TO USE THIS SCRIPT
# ─────────────────────────────────────────────────────────────────────────────
# [PAUSE]             Stop coding. Show rendered output. Check everyone is
#                     following. Ask the highlighted question before moving on.
# [ACTIVITY]          Participants work independently. Time given in parentheses.
# [FACILITATOR NOTE]  Speaking cue — do not read verbatim. Key concept to land.
# #>                  Expected console output after running the preceding code.
# ─────────────────────────────────────────────────────────────────────────────
# PRE-SESSION CHECKLIST
# □ Run SECTION 0 to cache GADM shapefiles (needs internet, ~30 sec)
# □ Confirm all 3 CSV files are in the working directory or adjust paths
# □ Confirm RStudio shows "sf" in the Packages pane (or install it)
# □ If no internet during session: save zmb_provinces & zmb_districts with
#   sf::st_write() beforehand, then load with sf::st_read() instead of gadm()
###############################################################################


# ============================================================
# SECTION 0 — SETUP  (Run BEFORE participants arrive)
# ============================================================

# Install required packages — run once
install.packages(c("sf", "geodata", "leaflet", "leaflet.extras",
                   "RColorBrewer", "viridis", "tidyverse"))

# Load packages
library(tidyverse)   # dplyr, ggplot2, tidyr — already familiar
library(sf)          # THE spatial data package for R
library(geodata)     # download GADM boundaries directly in R
library(leaflet)     # interactive maps
library(leaflet.extras)
library(RColorBrewer)
library(viridis)

# ── Download Zambia administrative boundaries from GADM ──────────────────────
# IMPORTANT: This needs internet. Run before participants arrive.
# gadm() downloads official administrative boundaries from gadm.org.
# level = 1 → provinces (10 total), level = 2 → districts (116 total)

zmb_provinces_raw <- gadm("ZMB", level = 1, path = tempdir())
zmb_districts_raw <- gadm("ZMB", level = 2, path = tempdir())

# gadm() returns a SpatVector (terra package). We convert to sf for ggplot2/leaflet.
zmb_provinces <- st_as_sf(zmb_provinces_raw)
zmb_districts <- st_as_sf(zmb_districts_raw)

# Verify the download worked correctly
nrow(zmb_provinces)
#> [1] 10

# Check GADM province names — these MUST match your CSV exactly
sort(zmb_provinces$NAME_1)
#> [1] "Central"       "Copperbelt"    "Eastern"       "Luapula"
#> [5] "Lusaka"        "Muchinga"      "Northern"      "North-Western"
#> [9] "Southern"      "Western"

# [FACILITATOR NOTE] Note "North-Western" has a hyphen. This is GADM's spelling.
# Your CSV uses the same spelling. Any mismatch here will silently produce NAs
# in the join later — we have a diagnostic for that in Section 2.

# ── Load ZICTA training datasets ─────────────────────────────────────────────
# Adjust paths if your CSV files are in a subfolder
coverage <- read_csv("Datasets/zicta_coverage_by_province.csv")
towers   <- read_csv("Datasets/zicta_towers.csv")
usaf     <- read_csv("Datasets/zicta_usaf_projects.csv")

glimpse(coverage)
glimpse(towers)
glimpse(usaf)


# ============================================================
# SECTION 1 — SPATIAL DATA FUNDAMENTALS
# [0:00 — 0:45]
# ============================================================

# [FACILITATOR NOTE] Open with: "Before we plot anything, we need to understand
# what makes spatial data different from the tabular data you've been working with.
# The answer is two things: a geometry column, and coordinate reference systems.
# Once you understand those, everything else is just ggplot2 and dplyr."

# ── 1.1  The sf object: what makes it special? ───────────────────────────────

class(zmb_provinces)
#> [1] "sf"         "data.frame"

# It is BOTH an sf object AND a plain data frame.
# Every verb you know still works.

glimpse(zmb_provinces)
# The "geometry" column holds the polygon shapes — one polygon per row.

# Familiar verbs work without change
zmb_provinces %>%
  filter(NAME_1 == "Lusaka") %>%
  select(NAME_1, COUNTRY)

# [FACILITATOR NOTE] The geometry column is "sticky" — it tags along even
# when you don't select it. That is a key sf feature, not a bug.

# [PAUSE] Ask: "What does class() tell us? Why does 'data.frame' matter?"

# ── 1.2  Coordinate Reference Systems ────────────────────────────────────────

# Check the CRS of our layer
st_crs(zmb_provinces)
#> Coordinate Reference System:
#>   User input: WGS 84
#>   wkt: GEOGCS["WGS 84"...

# EPSG:4326 — WGS84 — the GPS standard. Units are DEGREES of lat/lon.
# Good for display. Bad for measuring distances and areas.

# For distance and area in Zambia we use UTM Zone 35S
# EPSG:32735 — units are METRES, optimised for southern-central Africa

zmb_provinces_utm <- zmb_provinces %>%
  st_transform(crs = 32735)

st_crs(zmb_provinces_utm)$input
#> [1] "EPSG:32735"

# Why does it matter? Demonstrate with province areas.
zmb_provinces <- zmb_provinces %>%
  mutate(
    area_wrong_units = as.numeric(st_area(geometry)) / 1e6,    # degrees² — nonsense
    area_sqkm        = as.numeric(st_area(
                         st_transform(geometry, 32735)
                       )) / 1e6                                  # km² — correct
  )

zmb_provinces %>%
  st_drop_geometry() %>%
  select(NAME_1, area_wrong_units, area_sqkm) %>%
  arrange(desc(area_sqkm))
#> # A tibble: 10 × 3
#>   NAME_1       area_wrong_units area_sqkm
#>   <chr>               <dbl>      <dbl>
#> 1 Western             13.4     126350.
#> 2 Northern             8.5      77300.
#> 3 Eastern              8.0      69100.
#> ...

# [FACILITATOR NOTE] The area_wrong_units column is in degrees-squared —
# meaningless. area_sqkm is correct: Western province is ~126,000 km²,
# consistent with published figures.
# The rule: always st_transform() to a projected CRS before measuring.

# [PAUSE] Ask: "When would you use 4326 vs 32735?"
# Answer: 4326 for plotting/display; 32735 when calculating distances or areas.

# ── 1.3  Your first map ───────────────────────────────────────────────────────

# The simplest possible map in R
ggplot(zmb_provinces) +
  geom_sf() +
  labs(title = "Zambia: Provincial Boundaries",
       caption = "Source: GADM (geodata package)") +
  theme_void()

# [FACILITATOR NOTE] geom_sf() knows how to draw polygons, lines, and points
# because sf objects carry the geometry type. theme_void() removes axes and
# grid lines that have no meaning on a map.

# Add province labels using centroids
ggplot(zmb_provinces) +
  geom_sf(fill = "#f0f0f0", colour = "grey40", linewidth = 0.4) +
  geom_sf_label(aes(label = NAME_1), size = 2.5, fill = "white",
                label.size = 0, label.padding = unit(0.1, "lines")) +
  labs(title = "Zambia — 10 Provinces",
       caption = "Source: GADM") +
  theme_void()

# [PAUSE] Is this map correct? Does it match what you expect?
# [ACTIVITY — 2 min] Change fill = to a colour of your choice.


# ============================================================
# SECTION 2 — PROVINCE CHOROPLETH WITH ggplot2 + sf
# [0:45 — 1:45]
# ============================================================

# [FACILITATOR NOTE] "Now we connect the map to ZICTA data. The core operation
# is a left_join() — exactly what you learned in Week 10 — but the left table
# is now a spatial object. The join key is the province name."

# ── 2.1  The spatial attribute join ──────────────────────────────────────────

# First: verify that province names align EXACTLY
# This is the single most common failure point in spatial work
sort(zmb_provinces$NAME_1)
sort(coverage$province)
# Both should be identical 10-element vectors

# Perform the join
provinces_mapped <- zmb_provinces %>%
  left_join(coverage, by = c("NAME_1" = "province"))

# Validate — check for join failures
provinces_mapped %>%
  st_drop_geometry() %>%
  filter(is.na(internet_penetration_pct)) %>%
  pull(NAME_1)
#> character(0)   ← good: no mismatches. Any names here = spelling problem to fix.

# [FACILITATOR NOTE] [PAUSE] "What does character(0) mean here? Why is it good?"

# ── 2.2  Basic choropleth ─────────────────────────────────────────────────────

ggplot(provinces_mapped) +
  geom_sf(aes(fill = internet_penetration_pct)) +
  scale_fill_viridis_c(name = "Internet\npenetration (%)") +
  labs(title = "Internet Penetration by Province, Zambia 2022",
       caption = "Source: ZICTA ICT Indicators | Boundaries: GADM") +
  theme_void()

# [PAUSE] What does this map tell us? Ask participants to read it before continuing.
# Expected observation: Lusaka and Copperbelt are bright (high penetration);
# Western, Muchinga and Luapula are dark (low). Urban-rural divide visible at a glance.

# ── 2.3  Publication-ready: labels, colour direction, titles ─────────────────

# Compute province centroids for label placement (do in UTM for accuracy)
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
    direction = -1,              # darker = lower penetration (more visible for low values)
    labels    = function(x) paste0(x, "%")
  ) +
  labs(
    title    = "Internet Penetration by Province, Zambia 2022",
    subtitle = "Lusaka (67.8%) and Copperbelt (52.1%) far exceed rural provinces",
    caption  = "Source: ZICTA 2022 ICT Indicators | Boundaries: GADM"
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(colour = "grey40", size = 10),
    legend.position = "right"
  )

# [FACILITATOR NOTE] direction = -1 reverses the palette so darker = lower value.
# This is a design choice: underserved areas are darker, which draws the eye
# to the problem rather than the well-served areas. Always explain your palette
# choices in the map caption.

# ── 2.4  Faceted choropleth: comparing two indicators ────────────────────────

# [FACILITATOR NOTE] "Now we use something you already know — pivot_longer()
# and facet_wrap() — but applied to a spatial object. The geometry stays attached."

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
  scale_fill_viridis_c(option = "plasma", direction = -1,
                       name = "Value (%)",
                       labels = function(x) paste0(x, "%")) +
  facet_wrap(~ indicator) +
  labs(
    title   = "Digital Connectivity Indicators by Province, Zambia 2022",
    caption = "Source: ZICTA 2022 ICT Indicators | Boundaries: GADM"
  ) +
  theme_void(base_size = 11) +
  theme(strip.text = element_text(face = "bold", size = 10),
        legend.position = "bottom")

# [PAUSE] Key observation: mobile coverage is universally higher than internet
# penetration. Zambia has towers but limited internet use.
# Ask: "What explains this gap?" (affordability, device ownership, digital literacy)
# This is a ZICTA policy question, not just a data observation.

# [ACTIVITY — 5 min] Modify the faceted map to use broadband_per_100
# instead of mobile_coverage_pct. What story does the new map tell?


# ============================================================
# SECTION 3 — INTERACTIVE MAPS WITH leaflet
# [1:45 — 2:45]
# ============================================================

# [FACILITATOR NOTE] "ggplot2 maps are for reports and printed slides.
# leaflet maps are for exploration and dashboards — they pan, zoom, and
# respond to clicks. The syntax is different: we use %>% pipes but no + signs,
# and we add layers with addXxx() functions."

# ── 3.1  Basic leaflet choropleth ─────────────────────────────────────────────

# leaflet REQUIRES data in EPSG:4326 (WGS84). Our provinces are already in 4326.

# Build the colour palette first (leaflet's equivalent of scale_fill_viridis_c)
pal_internet <- colorNumeric(
  palette = "plasma",
  domain  = provinces_mapped$internet_penetration_pct,
  reverse = TRUE
)

leaflet(provinces_mapped) %>%
  addTiles() %>%                          # OpenStreetMap tiles as base layer
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

# [FACILITATOR NOTE] Two things to emphasise:
# 1. colorNumeric() is leaflet's palette function. It takes the same palette
#    names as viridis (and also accepts RColorBrewer names like "Blues").
# 2. The ~ (tilde) in fillColor = ~pal_internet(...) means "evaluate this as
#    a formula on the data". You will see ~ a lot in leaflet.

# [PAUSE] Zoom into Western province. Compare to Lusaka. Does the colour match
# what we showed in the ggplot map?

# ── 3.2  Hover highlights and HTML popups ─────────────────────────────────────

leaflet(provinces_mapped) %>%
  addProviderTiles("CartoDB.Positron") %>%    # cleaner background than OSM
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
      "Internet penetration: <b>", internet_penetration_pct, "%</b><br>",
      "Mobile coverage: ", mobile_coverage_pct, "%<br>",
      "Population: ", format(population_2022, big.mark = ",")
    ) %>% lapply(htmltools::HTML)
  ) %>%
  addLegend(
    pal      = pal_internet,
    values   = ~internet_penetration_pct,
    title    = "Internet Penetration (%)",
    position = "bottomright"
  )

# [FACILITATOR NOTE] lapply(htmltools::HTML) tells leaflet to render the label
# as HTML rather than plain text. That is what makes bold tags work.
# highlightOptions() controls what happens on hover.

# [PAUSE] Hover over provinces. Click to see popup content.
# Ask: "Which province has the widest gap between mobile coverage and internet penetration?"

# ── 3.3  Point layer: tower locations ─────────────────────────────────────────

# Convert towers CSV to sf spatial object
# CRITICAL: coords = c("longitude", "latitude") — X (lon) BEFORE Y (lat)
# If you swap these, points end up in the ocean. R does NOT warn you.
towers_sf <- towers %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

class(towers_sf)
#> [1] "sf"         "tbl_df"     "tbl"        "data.frame"

# Quick check: do the points look right?
plot(st_geometry(towers_sf), axes = TRUE)
plot(st_geometry(zmb_provinces), add = TRUE)

# Colour towers by operator (colorFactor = categorical palette)
operator_colours <- colorFactor(
  palette = c("#E41A1C", "#377EB8", "#4DAF4A", "#FF7F00"),
  domain  = towers_sf$operator
)

leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data        = provinces_mapped,
    fillColor   = "transparent",
    color       = "grey60",
    weight      = 1,
    label       = ~NAME_1
  ) %>%
  addCircleMarkers(
    data        = towers_sf,
    radius      = 6,
    color       = ~operator_colours(operator),
    fillColor   = ~operator_colours(operator),
    fillOpacity = 0.85,
    stroke      = FALSE,
    popup       = ~paste0(
      "<b>Tower ID:</b> ", tower_id, "<br>",
      "<b>Operator:</b> ", operator, "<br>",
      "<b>Province:</b> ", province, "<br>",
      "<b>District:</b> ", district, "<br>",
      "<b>Year installed:</b> ", year_installed, "<br>",
      "<b>License type:</b> ", license_type
    )
  ) %>%
  addLegend(
    pal    = operator_colours,
    values = towers_sf$operator,
    title  = "Operator"
  )

# [PAUSE] Click on individual towers. Click on provinces.
# Ask: "Are towers evenly distributed? Which provinces look underserved?"

# ── 3.4  Layered map: choropleth + towers + operator toggles ──────────────────

leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data        = provinces_mapped,
    fillColor   = ~pal_internet(internet_penetration_pct),
    fillOpacity = 0.55,
    color       = "white",
    weight      = 1.2,
    label       = ~paste0(NAME_1, ": ", internet_penetration_pct, "%") %>%
                  lapply(htmltools::HTML),
    group       = "Internet Penetration"
  ) %>%
  addCircleMarkers(
    data        = towers_sf %>% filter(operator == "Airtel Zambia"),
    radius      = 5, color = "#E41A1C", fillColor = "#E41A1C",
    fillOpacity = 0.9, stroke = FALSE,
    popup       = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group       = "Airtel Zambia"
  ) %>%
  addCircleMarkers(
    data        = towers_sf %>% filter(operator == "MTN Zambia"),
    radius      = 5, color = "#377EB8", fillColor = "#377EB8",
    fillOpacity = 0.9, stroke = FALSE,
    popup       = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group       = "MTN Zambia"
  ) %>%
  addCircleMarkers(
    data        = towers_sf %>% filter(operator == "ZAMTEL"),
    radius      = 5, color = "#4DAF4A", fillColor = "#4DAF4A",
    fillOpacity = 0.9, stroke = FALSE,
    popup       = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group       = "ZAMTEL"
  ) %>%
  addCircleMarkers(
    data        = towers_sf %>% filter(operator == "Liquid Telecom"),
    radius      = 5, color = "#FF7F00", fillColor = "#FF7F00",
    fillOpacity = 0.9, stroke = FALSE,
    popup       = ~paste0("<b>", operator, "</b><br>", district, ", ", province),
    group       = "Liquid Telecom"
  ) %>%
  addLegend(pal = pal_internet, values = provinces_mapped$internet_penetration_pct,
            title = "Internet (%)", position = "bottomleft") %>%
  addLegend(pal = operator_colours, values = towers_sf$operator,
            title = "Operator", position = "bottomright") %>%
  addLayersControl(
    overlayGroups = c("Internet Penetration", "Airtel Zambia", "MTN Zambia",
                      "ZAMTEL", "Liquid Telecom"),
    options       = layersControlOptions(collapsed = FALSE)
  )

# [FACILITATOR NOTE] The group = argument links each layer to the toggle control.
# addLayersControl() creates the checkbox panel. This is the map format that
# ZICTA's Engineering team will use to compare operator coverage side by side.

# [PAUSE] Toggle operators on and off. Which operator has the widest rural reach?
# Ask: "How would you explain this map to a ZICTA board member?"

# [ACTIVITY — 5 min] Add a popup to the polygon layer that shows the province
# name AND the number of towers in that province. Hint: you will need to
# calculate n_towers per province first (see Section 4).


# ============================================================
# SECTION 4 — SPATIAL JOINS AND COVERAGE GAP ANALYSIS
# [2:45 — 3:30]
# ============================================================

# [FACILITATOR NOTE] "In Week 10 we joined data frames using a shared column.
# Spatial joins match rows by LOCATION — a point falls inside a polygon,
# so it inherits that polygon's attributes. You do not need a shared column.
# Geography IS the join key."

# ── 4.1  st_join: point-in-polygon ───────────────────────────────────────────

# Does the spatial province assignment match the province column in the CSV?
towers_enriched <- towers_sf %>%
  st_join(zmb_provinces %>% select(NAME_1))

towers_enriched %>%
  st_drop_geometry() %>%
  select(tower_id, operator, province, NAME_1) %>%
  mutate(match = province == NAME_1) %>%
  count(match)
#> # A tibble: 1 × 2
#>   match     n
#>   <lgl> <int>
#> 1 TRUE     72   ← all 72 towers correctly placed within their named provinces

# [FACILITATOR NOTE] In real data this check catches GPS transcription errors
# — a common data quality issue with infrastructure registries.

# ── 4.2  Aggregating points to polygons ──────────────────────────────────────

towers_per_province <- towers_enriched %>%
  st_drop_geometry() %>%
  count(NAME_1, name = "n_towers") %>%
  rename(province = NAME_1)

towers_per_province
#> # A tibble: 10 × 2
#>   province        n_towers
#>   <chr>              <int>
#> 1 Central                7
#> 2 Copperbelt            10
#> ...

provinces_towers <- zmb_provinces %>%
  left_join(towers_per_province, by = c("NAME_1" = "province")) %>%
  mutate(n_towers = replace_na(n_towers, 0))   # provinces with zero towers → 0 not NA

# [FACILITATOR NOTE] replace_na(n_towers, 0) is important: provinces with NO
# towers still need to appear on the map. An NA would make them transparent.

ggplot(provinces_towers) +
  geom_sf(aes(fill = n_towers), colour = "white", linewidth = 0.4) +
  geom_sf_text(aes(label = paste0(NAME_1, "\n(", n_towers, ")")),
               size = 2.0, colour = "grey20") +
  scale_fill_distiller(palette = "Blues", direction = 1,
                       name = "Licensed\ntowers") +
  labs(title   = "ZICTA-Licensed Tower Count by Province",
       caption = "Source: ZICTA tower registry | Boundaries: GADM") +
  theme_void()

# ── 4.3  Coverage gap analysis ────────────────────────────────────────────────

# Combine tower counts with penetration and population data
coverage_gap <- provinces_towers %>%
  left_join(coverage, by = c("NAME_1" = "province")) %>%
  mutate(
    towers_per_million = round((n_towers / population_2022) * 1e6, 1),
    # Flag provinces where both penetration AND towers are below threshold
    priority_flag = internet_penetration_pct < 20 & n_towers < 8
  )

# Priority provinces for USAF investment
coverage_gap %>%
  st_drop_geometry() %>%
  filter(priority_flag) %>%
  select(NAME_1, internet_penetration_pct, n_towers, towers_per_million, population_2022) %>%
  arrange(internet_penetration_pct)
#> # A tibble: 5 × 5
#>   NAME_1       internet_penetration_pct n_towers towers_per_million population_2022
#>   <chr>                           <dbl>    <int>             <dbl>           <dbl>
#> 1 Muchinga                          9.8        5               5.3          935000
#> 2 Western                          10.4        7               6.4         1089000
#> 3 Luapula                          11.2        5               4.6         1086000
#> 4 Northern                         12.3        6               4.2         1415000
#> 5 North-Western                    15.6        6               7.4          809000

# [FACILITATOR NOTE] This output is the key analytical result for the
# Universal Access team. Five provinces have both low internet penetration
# AND low tower density. These are evidence-based USAF priority targets.

# Visualise the priority provinces
ggplot(coverage_gap) +
  geom_sf(aes(fill = priority_flag), colour = "white", linewidth = 0.4) +
  scale_fill_manual(values = c("FALSE" = "#d4e6f1", "TRUE" = "#c0392b"),
                    labels  = c("FALSE" = "Not priority", "TRUE" = "Priority (low penetration + low towers)"),
                    name    = "") +
  geom_sf_text(aes(label = NAME_1), size = 2.2, colour = "grey20") +
  labs(title   = "USAF Priority Provinces: Low Penetration and Low Tower Density",
       caption = "Priority: internet penetration < 20% AND fewer than 8 towers\nSource: ZICTA 2022") +
  theme_void() +
  theme(legend.position = "bottom")

# ── 4.4  Distance calculations ────────────────────────────────────────────────

# How far are towers from Lusaka? (Engineering use case: maintenance cost proxy)
# MUST use a projected CRS for distance — transform FIRST

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
  summarise(
    avg_dist_km = round(mean(dist_lusaka_km), 0),
    max_dist_km = round(max(dist_lusaka_km), 0)
  ) %>%
  arrange(desc(avg_dist_km))
#> Western towers are ~700 km from Lusaka on average — the most remote

# [FACILITATOR NOTE] [PAUSE] Rule: st_distance() requires a projected CRS.
# If you forget to transform, st_distance() returns a value in degrees —
# and R does NOT warn you. Always transform before measuring.

# [ACTIVITY — 3 min] Flag towers that are more than 500 km from Lusaka.
# How many are there, and which operators operate them?


# ============================================================
# SECTION 5 — CAPSTONE EXERCISE (GROUP WORK)
# [3:30 — 5:00 | 90 minutes]
# ============================================================

# [FACILITATOR NOTE] Participants split into functional groups.
# Each group produces one publication-ready map relevant to their mandate.
# Circulate every 10–15 minutes. Each group presents ~2 minutes at the end.
#
# Starter code is below each task. Groups fill in the blanks and extend as time allows.

# ──────────────────────────────────────────────────────────────────────────────
# GROUP A — ENGINEERING
# Task: Analyse ZAMTEL tower gaps and flag remote towers.
# ──────────────────────────────────────────────────────────────────────────────

# Step 1: Filter to ZAMTEL towers only
zamtel_towers <- towers_sf %>%
  filter(operator == "ZAMTEL")

# Step 2: Count ZAMTEL towers per province
zamtel_per_province <- zamtel_towers %>%
  st_join(zmb_provinces %>% select(NAME_1)) %>%
  st_drop_geometry() %>%
  count(NAME_1, name = "n_zamtel") %>%
  rename(province = NAME_1)

provinces_zamtel <- zmb_provinces %>%
  left_join(zamtel_per_province, by = c("NAME_1" = "province")) %>%
  mutate(n_zamtel       = replace_na(n_zamtel, 0),
         low_coverage   = n_zamtel < 2)

# Step 3: Interactive map — ZAMTEL choropleth + remote tower flags
zamtel_remote <- towers_utm %>%
  filter(operator == "ZAMTEL", dist_lusaka_km > 500) %>%
  st_transform(4326)

leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data      = provinces_zamtel,
    fillColor = ~colorNumeric("Reds", n_zamtel, reverse = TRUE)(n_zamtel),
    fillOpacity = 0.7, color = "white", weight = 1,
    label     = ~paste0(NAME_1, ": ", n_zamtel, " ZAMTEL towers") %>% lapply(htmltools::HTML)
  ) %>%
  addCircleMarkers(
    data      = zamtel_towers,
    radius = 5, color = "#4DAF4A", fillColor = "#4DAF4A",
    fillOpacity = 0.9, stroke = FALSE,
    popup     = ~paste0("<b>", tower_id, "</b><br>", district, ", ", province,
                        "<br>Year: ", year_installed)
  ) %>%
  addCircleMarkers(
    data      = zamtel_remote,
    radius = 9, color = "black", fillColor = "red",
    fillOpacity = 0.9, stroke = TRUE, weight = 2,
    popup     = ~paste0("<b>REMOTE TOWER</b><br>", tower_id, "<br>",
                        district, ", ", province,
                        "<br>Distance from Lusaka: ", round(dist_lusaka_km), " km")
  ) %>%
  addLegend(colors = c("#4DAF4A", "red"), labels = c("ZAMTEL tower", "Remote (>500 km)"),
            title = "ZAMTEL Infrastructure")


# ──────────────────────────────────────────────────────────────────────────────
# GROUP B — STATISTICAL UNIT
# Task: Compare all 4 connectivity indicators + quantify provincial inequality.
# ──────────────────────────────────────────────────────────────────────────────

# Step 1: Add towers_per_million to the dataset
stat_data <- provinces_mapped %>%
  left_join(towers_per_province, by = c("NAME_1" = "province")) %>%
  mutate(
    n_towers           = replace_na(n_towers, 0),
    towers_per_million = round((n_towers / population_2022) * 1e6, 1)
  )

# Step 2: Faceted choropleth of all 4 indicators
stat_long <- stat_data %>%
  select(NAME_1, internet_penetration_pct, mobile_coverage_pct,
         broadband_per_100, towers_per_million, geometry) %>%
  pivot_longer(
    cols      = c(internet_penetration_pct, mobile_coverage_pct,
                  broadband_per_100, towers_per_million),
    names_to  = "indicator",
    values_to = "value"
  ) %>%
  mutate(indicator = recode(indicator,
    "internet_penetration_pct" = "Internet Penetration (%)",
    "mobile_coverage_pct"      = "Mobile Coverage (%)",
    "broadband_per_100"        = "Broadband Subscriptions (per 100)",
    "towers_per_million"       = "Towers per Million Population"
  ))

ggplot(stat_long) +
  geom_sf(aes(fill = value), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "plasma", direction = -1, name = "Value") +
  facet_wrap(~ indicator, nrow = 2) +
  labs(title   = "ZICTA ICT Connectivity Indicators by Province, Zambia 2022",
       caption = "Source: ZICTA 2022 | Boundaries: GADM") +
  theme_void(base_size = 10) +
  theme(strip.text = element_text(face = "bold"),
        legend.position = "bottom")

# Step 3: Quantify inequality (max/min ratio per indicator)
stat_data %>%
  st_drop_geometry() %>%
  summarise(
    internet_ratio  = max(internet_penetration_pct) / min(internet_penetration_pct),
    coverage_ratio  = max(mobile_coverage_pct)       / min(mobile_coverage_pct),
    broadband_ratio = max(broadband_per_100)          / min(broadband_per_100),
    towers_ratio    = max(towers_per_million)         / min(towers_per_million)
  )
# Which indicator shows the greatest inequality?


# ──────────────────────────────────────────────────────────────────────────────
# GROUP C — FINANCIAL STATISTICS
# Task: Map compliance scores by province and explore relationship with penetration.
# ──────────────────────────────────────────────────────────────────────────────

# Note: sample_data_telecoms.csv uses "region" not "province"
telecoms <- read_csv("../../ZICTA Training 2026/Datasets/Sample data_telecoms.csv")

compliance_by_province <- telecoms %>%
  group_by(region) %>%
  summarise(avg_compliance = round(mean(compliance_score, na.rm = TRUE), 1)) %>%
  rename(province = region)

compliance_by_province

# Join to spatial layer
provinces_compliance <- zmb_provinces %>%
  left_join(compliance_by_province, by = c("NAME_1" = "province")) %>%
  left_join(coverage, by = c("NAME_1" = "province"))

# Map compliance scores
ggplot(provinces_compliance) +
  geom_sf(aes(fill = avg_compliance), colour = "white", linewidth = 0.4) +
  scale_fill_distiller(palette = "RdYlGn", direction = 1,
                       name = "Average\ncompliance score",
                       limits = c(60, 100)) +
  geom_sf_text(aes(label = paste0(NAME_1, "\n", avg_compliance)),
               size = 2.0) +
  labs(title   = "Average Operator Compliance Score by Province",
       caption = "Source: ZICTA licensing data | Boundaries: GADM") +
  theme_void()

# Scatterplot: Is compliance associated with internet penetration?
provinces_compliance %>%
  st_drop_geometry() %>%
  ggplot(aes(x = avg_compliance, y = internet_penetration_pct, label = NAME_1)) +
  geom_point(size = 3, colour = "#2c7bb6") +
  geom_text(nudge_y = 1.5, size = 3) +
  geom_smooth(method = "lm", se = TRUE, colour = "grey50") +
  labs(title = "Compliance Score vs Internet Penetration by Province",
       x = "Average compliance score", y = "Internet penetration (%)") +
  theme_minimal()


# ──────────────────────────────────────────────────────────────────────────────
# GROUP D — POSTAL SERVICES
# Task: Interactive map of USAF projects with status and budget information.
# ──────────────────────────────────────────────────────────────────────────────

usaf_sf <- usaf %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Colour by project status
status_colours <- colorFactor(
  palette = c("Completed" = "#27ae60", "Ongoing" = "#2980b9", "Planned" = "#e67e22"),
  domain  = usaf_sf$status
)

leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data        = zmb_provinces,
    fillColor   = "transparent",
    color       = "grey60", weight = 1,
    label       = ~NAME_1
  ) %>%
  addCircleMarkers(
    data        = usaf_sf,
    radius      = ~sqrt(budget_usd / 10000),   # size proportional to budget
    color       = ~status_colours(status),
    fillColor   = ~status_colours(status),
    fillOpacity = 0.8,
    stroke      = TRUE, weight = 1,
    popup       = ~paste0(
      "<b>", project_name, "</b><br>",
      "<b>Province:</b> ", province, " | ", district, "<br>",
      "<b>Budget:</b> $", format(budget_usd, big.mark = ","), "<br>",
      "<b>Status:</b> ", status, "<br>",
      "<b>Target population:</b> ", format(target_population, big.mark = ",")
    )
  ) %>%
  addLegend(pal = status_colours, values = usaf_sf$status,
            title = "Project status", position = "bottomright")

# Calculate total USAF investment by province
usaf_by_province <- usaf %>%
  group_by(province) %>%
  summarise(
    total_budget_usd  = sum(budget_usd),
    n_projects        = n(),
    total_target_pop  = sum(target_population)
  ) %>%
  arrange(desc(total_budget_usd))

print(usaf_by_province)


# ──────────────────────────────────────────────────────────────────────────────
# GROUP E — UNIVERSAL ACCESS
# Task: Identify underinvested provinces for USAF targeting.
# ──────────────────────────────────────────────────────────────────────────────

# Aggregate USAF investment by province
usaf_by_province <- usaf %>%
  group_by(province) %>%
  summarise(
    total_budget     = sum(budget_usd),
    n_projects       = n(),
    total_target_pop = sum(target_population)
  )

# Join USAF data + coverage data to spatial layer
provinces_usaf <- zmb_provinces %>%
  left_join(usaf_by_province, by = c("NAME_1" = "province")) %>%
  left_join(coverage,         by = c("NAME_1" = "province")) %>%
  mutate(
    total_budget  = replace_na(total_budget, 0),
    n_projects    = replace_na(n_projects, 0),
    # Flag provinces that are both digitally underserved AND underfunded by USAF
    underinvested = internet_penetration_pct < 20 & total_budget < 500000
  )

# Map: USAF budget by province
ggplot(provinces_usaf) +
  geom_sf(aes(fill = total_budget / 1e6), colour = "white", linewidth = 0.4) +
  geom_sf_text(aes(label = paste0(NAME_1, "\n$",
                                  round(total_budget / 1000), "k")),
               size = 1.9, colour = "grey20") +
  scale_fill_viridis_c(name = "Total USAF\ninvestment ($M)",
                       option = "cividis") +
  labs(title   = "Total USAF Investment by Province",
       caption = "Source: ZICTA USAF project database | Boundaries: GADM") +
  theme_void()

# Final output: Underinvested province analysis
underinvested_summary <- provinces_usaf %>%
  st_drop_geometry() %>%
  filter(underinvested) %>%
  select(NAME_1, internet_penetration_pct, total_budget, n_projects,
         total_target_pop, population_2022) %>%
  mutate(
    pct_population_targeted = round(total_target_pop / population_2022 * 100, 1)
  ) %>%
  arrange(internet_penetration_pct)

print(underinvested_summary)
# [FACILITATOR NOTE] This table is the key policy output for the Universal
# Access group: underserved provinces where USAF has invested less than $500k.
# The pct_population_targeted column shows how small a share of the population
# is currently being reached by USAF projects.

ggplot(provinces_usaf) +
  geom_sf(aes(fill = underinvested), colour = "white", linewidth = 0.4) +
  scale_fill_manual(
    values = c("FALSE" = "#aec6e8", "TRUE" = "#c0392b"),
    labels = c("FALSE" = "Adequately covered or funded",
               "TRUE"  = "Underserved & underfunded (priority)"),
    name   = ""
  ) +
  geom_sf_text(aes(label = NAME_1), size = 2.2, colour = "grey20") +
  labs(
    title    = "USAF Priority Targeting: Underserved and Underfunded Provinces",
    subtitle = "Priority = internet penetration < 20% AND total USAF investment < $500k",
    caption  = "Source: ZICTA 2022 ICT Indicators & USAF project database"
  ) +
  theme_void() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"))


###############################################################################
# END OF SESSION
# ─────────────────────────────────────────────────────────────────────────────
# Key functions to remember:
#   st_as_sf()         — convert data frame with lat/lon to spatial object
#   st_transform()     — change CRS (use 4326 for display, 32735 for measuring)
#   st_crs()           — check current CRS
#   st_join()          — spatial join (point-in-polygon)
#   st_centroid()      — compute centroid of a polygon
#   st_distance()      — distance between geometries (requires projected CRS)
#   geom_sf()          — draw sf objects in ggplot2
#   geom_sf_text()     — add labels at geometry locations
#   colorNumeric()     — continuous colour palette for leaflet
#   colorFactor()      — categorical colour palette for leaflet
#   addPolygons()      — add polygon layer to leaflet
#   addCircleMarkers() — add point layer to leaflet
#   addLayersControl() — add toggle controls to leaflet
###############################################################################
