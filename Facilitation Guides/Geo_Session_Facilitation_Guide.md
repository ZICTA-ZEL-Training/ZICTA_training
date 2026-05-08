# Facilitation Guide: Geospatial Analysis Session
**ZICTA R Training Programme**
For re-delivery by ZEL (Chomba Kalunga & Kosam Chola)

---

## 1. Session Overview

### Learning Objectives
By the end of this session participants will be able to:

1. Explain the difference between geographic (WGS84) and projected (UTM) coordinate reference systems and know when to use each
2. Download Zambia administrative boundaries using `geodata::gadm()` and convert to sf format
3. Produce a province-level choropleth map by joining ZICTA data to a GADM shapefile using `left_join()`
4. Build an interactive leaflet map with popups, hover labels, and operator layer toggles
5. Perform a spatial join (`st_join()`) to aggregate point data to province level and identify coverage gaps

### Assumed Prior Knowledge
Participants must have completed at least **Modules 1–10** of the ZICTA R Training Programme. Specifically, they must be comfortable with:

- `read_csv()`, `glimpse()`, `filter()`, `mutate()`, `select()`
- `left_join()` by a shared key column (Module 10)
- `ggplot2`: `geom_point()`, `geom_bar()`, `aes()`, `facet_wrap()`
- `pivot_longer()` for reshaping data

They do **not** need prior experience with spatial data, shapefiles, or mapping tools.

### Materials Checklist
Before the session:

- [ ] `ZICTA_Geo_Live_Script.R` — facilitator coding script (this guide's companion)
- [ ] `ZICTA_Geo_Student.R` — printed or distributed digitally to participants
- [ ] `zicta_coverage_by_province.csv`, `zicta_towers.csv`, `zicta_usaf_projects.csv` accessible from working directory
- [ ] Internet access confirmed — needed for `gadm()` download and leaflet map tiles
- [ ] All packages pre-installed: `sf`, `geodata`, `leaflet`, `leaflet.extras`, `viridis`
- [ ] Section 0 of the live script run before participants arrive (caches GADM data)
- [ ] Slide deck rendered to HTML via `quarto render ZICTA_Geo_Slide_Deck.qmd`

**If no internet during the session:**
Run this before participants arrive to save the boundaries locally:
```r
zmb_provinces <- st_as_sf(gadm("ZMB", level = 1, path = tempdir()))
zmb_districts <- st_as_sf(gadm("ZMB", level = 2, path = tempdir()))
sf::st_write(zmb_provinces, "zambia_provinces.gpkg", delete_dsn = TRUE)
sf::st_write(zmb_districts, "zambia_districts.gpkg",  delete_dsn = TRUE)
```
Then load in the session with:
```r
zmb_provinces <- sf::st_read("zambia_provinces.gpkg")
zmb_districts <- sf::st_read("zambia_districts.gpkg")
```

---

## 2. Session Flow and Timing

### Full-Day Format (recommended)

| Time | Section | Content |
|------|---------|---------|
| 08:30 | Pre-session | Facilitator runs Section 0, confirms setup |
| 09:00 | Section 1 | Spatial data fundamentals: sf, CRS, first map |
| 09:45 | Break (10 min) | |
| 09:55 | Section 2 | Province choropleth: join + ggplot2 |
| 11:00 | Break (15 min) | |
| 11:15 | Section 3 | Interactive leaflet maps |
| 12:15 | Lunch (60 min) | |
| 13:15 | Section 4 | Spatial joins: st_join, aggregation, coverage gap |
| 14:00 | Break (10 min) | |
| 14:10 | Section 5 | Capstone exercise (group work) |
| 15:40 | Presentations | 2 minutes per group |
| 16:00 | Close | Key functions cheat sheet, Q&A |

### Two Half-Day Format

**Day 1 (3 hours):** Sections 0–2
- Spatial data fundamentals, CRS, first map
- Province choropleth: join + basic + publication-ready + faceted

**Day 2 (3 hours):** Sections 3–5
- Interactive leaflet maps
- Spatial joins and coverage gap analysis
- Capstone exercise

### What to Cut If Running Behind
If the session is running 15–20 minutes late, these sub-sections can be shortened or skipped without losing core skills:

- **Section 1.2** (CRS area demonstration) — explain the concept verbally, skip the mutate() demo. Time saved: ~10 minutes
- **Section 4.4** (st_distance calculations) — mention the concept, point to the code in the script, skip live coding. Time saved: ~10 minutes
- **Section 2.3** (centroid label computation) — use geom_sf_label() on polygons directly (simpler, slightly less precise). Time saved: ~8 minutes

Do **not** cut Section 2.1 (the join validation diagnostic) — this is a critical skill that prevents silent errors.

---

## 3. Common Technical Problems and Fixes

### Problem 1: `gadm()` returns a SpatVector, not sf

**Symptom:** `ggplot(zmb_provinces) + geom_sf()` throws an error like "cannot coerce class SpatVector"

**Fix:** Always call `st_as_sf()` immediately after `gadm()`:
```r
zmb_provinces <- st_as_sf(gadm("ZMB", level = 1, path = tempdir()))
```

**Note:** This is the #1 error when participants use `geodata`. Mention it before they run Section 0.

---

### Problem 2: Province name mismatch — NAs after join

**Symptom:** `filter(is.na(internet_penetration_pct))` returns province names instead of `character(0)`

**Common causes:**
- "North-Western" vs "Northwestern" vs "North Western" — GADM uses the hyphenated form
- Trailing spaces in CSV province names
- Wrong capitalisation

**Fix:**
```r
# Diagnose
zmb_provinces$NAME_1  # check exact GADM spelling
coverage$province      # check CSV spelling

# Fix trailing spaces
coverage <- coverage |> mutate(province = str_trim(province))

# Fix specific mismatches
coverage <- coverage |>
  mutate(province = case_when(
    province == "Northwestern" ~ "North-Western",
    TRUE ~ province
  ))
```

---

### Problem 3: Leaflet map appears blank or shows only base tiles

**Most common cause:** Data is in a projected CRS (e.g., EPSG:32735). Leaflet requires EPSG:4326.

**Fix:**
```r
# Check CRS
st_crs(my_data)$input

# Fix: transform before passing to leaflet
my_data_4326 <- my_data |> st_transform(4326)
leaflet(my_data_4326) |> ...
```

**Second most common cause:** `addTiles()` requires internet. If offline, use a static base or skip tiles:
```r
leaflet() |>
  addPolygons(data = provinces_mapped, ...)   # no tiles — works offline
```

---

### Problem 4: `st_as_sf()` coordinates look wrong (points in ocean)

**Symptom:** All tower points appear in the southern Atlantic Ocean

**Cause:** `coords` argument has longitude and latitude in the wrong order

**Fix:**
```r
# WRONG (lat before lon):
towers_sf <- towers |> st_as_sf(coords = c("latitude", "longitude"), crs = 4326)

# CORRECT (lon before lat — X before Y):
towers_sf <- towers |> st_as_sf(coords = c("longitude", "latitude"), crs = 4326)
```

**Teaching note:** The rule is **X before Y**, i.e., **longitude before latitude**. This matches the mathematical convention (x, y) and the order in coordinate pairs (28.3°E, −15.4°S).

---

### Problem 5: `st_distance()` returns very large numbers (millions)

**Cause:** Data is in EPSG:4326 (degrees). `st_distance()` returns values in decimal degrees — not metres.

**Fix:** Transform to EPSG:32735 (metres) before computing distances:
```r
towers_utm <- towers_sf |> st_transform(32735)
ref_utm    <- reference_point |> st_transform(32735)
st_distance(towers_utm, ref_utm)   # now in metres
```

---

### Problem 6: `replace_na()` not working

**Symptom:** Error "could not find function 'replace_na'"

**Fix:** `replace_na()` is in the `tidyr` package (part of `tidyverse`). Ensure `library(tidyverse)` is loaded.

---

## 4. Group-Specific Facilitation Notes

### Engineering Group
- Likely to find the **distance analysis** (Section 4.4) most directly relevant to their work — encourage them to extend it with `st_buffer()` to approximate signal coverage footprints
- May ask about displaying fibre routes or spectrum boundaries — explain these would be line geometries (`geom_sf()` handles them the same way as polygons)
- Common question: "Can we use real GPS coordinates from our field teams?" — Yes: any CSV with lat/lon columns works with `st_as_sf(coords = c("longitude", "latitude"), crs = 4326)`

### Statistical Unit
- Likely to want to extend the faceted choropleth with formal inequality statistics (Gini coefficient, coefficient of variation)
- Good extension: `summarise(gini = ineq::gini(internet_penetration_pct))` — requires the `ineq` package
- May want to use district-level data: encourage them to change `level = 1` to `level = 2` in `gadm()` and use `NAME_2` as the join key

### Financial Statistics
- The compliance score join exercise directly connects to their existing work with `sample_data_telecoms.csv` from earlier modules
- **Note on telecoms data path:** If they are running from `ZICTA_training/`, they need to adjust the path: `read_csv("../../ZICTA Training 2026/Datasets/Sample data_telecoms.csv")` — or copy the file to the `Datasets/` folder
- The scatter plot (compliance vs penetration) may generate discussion about causality vs correlation — encourage them to add region labels to the points for context

### Postal Services
- The USAF project map is operationally relevant to their mandate — encourage them to bring real project data after the session
- Circle radius proportional to budget (`~sqrt(budget_usd / 10000)`) is a useful pattern to highlight — explain why sqrt() gives more visually proportional circles than raw budget
- If they finish early: ask them to produce a bar chart of total budget by province to complement the map

### Universal Access
- The coverage gap analysis (Section 4.3 + capstone) is the most directly actionable output for their team
- The `underinvested` flag (low penetration AND low USAF investment) can be presented to the group as a draft policy brief
- Encourage them to discuss the **threshold choices** — why 20% for penetration? Why $500k for USAF? These are policy decisions, not just statistical cutoffs
- If they have real USAF project coordinates, this code runs unchanged — just substitute the CSV

---

## 5. Adaptation Notes for Future Delivery

### Updating to Real ZICTA Data
All three CSV files can be replaced with real ZICTA data without modifying any code, provided:

1. **Province names** match GADM exactly. Use `sort(zmb_provinces$NAME_1)` as the reference. The 10 names are: Central, Copperbelt, Eastern, Luapula, Lusaka, Muchinga, Northern, North-Western, Southern, Western
2. **Column names** in the replacement CSVs match what the scripts reference. The key columns are:
   - `zicta_coverage_by_province.csv`: `province`, `internet_penetration_pct`, `mobile_coverage_pct`, `broadband_per_100`, `population_2022`
   - `zicta_towers.csv`: `tower_id`, `operator`, `license_type`, `latitude`, `longitude`, `province`, `district`, `year_installed`
   - `zicta_usaf_projects.csv`: `project_id`, `project_name`, `province`, `district`, `latitude`, `longitude`, `budget_usd`, `start_year`, `status`, `target_population`

### Upgrading to District Level
To run the analysis at district rather than province level:

```r
# Change level=1 to level=2
zmb_districts <- st_as_sf(gadm("ZMB", level = 2, path = tempdir()))

# Join column changes from NAME_1 to NAME_2
coverage_district |>
  left_join(zicta_district_data, by = c("NAME_2" = "district"))
```

Allow an extra 15 minutes for Section 2 — district maps have more labels and the centroid calculation takes longer.

### Embedding Leaflet Maps in a flexdashboard
The leaflet maps from Section 3 embed directly into a flexdashboard without modification:

```r
---
title: "ZICTA Coverage Dashboard"
output: flexdashboard::flex_dashboard
---

## Province Coverage {data-width=600}

### Internet Penetration by Province

```{r}
leaflet(provinces_mapped) |>
  addProviderTiles("CartoDB.Positron") |>
  addPolygons(fillColor = ~pal_internet(internet_penetration_pct), ...)
```
```

Each `leaflet()` call goes inside a chunk in a flexdashboard panel. No additional wrapping is needed — this links directly to the Module 15–16 dashboard skills.

### Adding a Buffer Zone Analysis (Engineering Extension)
To visualise approximate tower signal coverage footprints:

```r
# Create 30 km buffer around each tower (30 km is a rough rural signal range)
tower_buffers <- towers_sf |>
  st_transform(32735) |>           # must be projected for distance-based buffers
  st_buffer(dist = 30000) |>       # 30,000 metres = 30 km
  st_transform(4326) |>            # back to WGS84 for leaflet
  st_union() |>                    # optional: merge overlapping buffers
  st_sf()

# Add to leaflet map
leaflet() |>
  addPolygons(data = tower_buffers, fillColor = "blue", fillOpacity = 0.2,
              color = "blue", weight = 1) |>
  addCircleMarkers(data = towers_sf, ...)
```

---

## 6. Quick Reference: Package Functions

| Function | Package | When to use |
|----------|---------|------------|
| `st_as_sf(coords=...)` | sf | Convert CSV lat/lon to spatial |
| `st_transform(crs=...)` | sf | Change CRS (4326 display, 32735 measure) |
| `st_crs()` | sf | Check current CRS |
| `st_join()` | sf | Point-in-polygon spatial join |
| `st_centroid()` | sf | Compute centroid (use projected CRS) |
| `st_distance()` | sf | Distances (use projected CRS) |
| `st_buffer()` | sf | Buffer zone around geometries |
| `st_drop_geometry()` | sf | Convert sf back to plain data frame |
| `gadm()` | geodata | Download GADM boundaries |
| `geom_sf()` | ggplot2 | Draw any sf geometry |
| `geom_sf_text()` | ggplot2 | Labels at geometry centres |
| `colorNumeric()` | leaflet | Continuous colour scale |
| `colorFactor()` | leaflet | Categorical colour scale |
| `addProviderTiles()` | leaflet | Base map tiles (CartoDB, OSM) |
| `addPolygons()` | leaflet | Polygon layer |
| `addCircleMarkers()` | leaflet | Point layer |
| `addLayersControl()` | leaflet | Toggle controls |
| `addLegend()` | leaflet | Legend |
| `highlightOptions()` | leaflet | Hover effect configuration |
