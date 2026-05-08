# Zambia Spatial Data Sources
**ZICTA Geospatial Training — Reference Document**

Curated by Matteo Larrode (IGC) | Updated May 2026

This document lists spatial datasets relevant to ZICTA's regulatory mandate, grouped by thematic area. Each entry includes the access method, license status, and notes on suitability for ZICTA analysis.

---

## 1. Administrative Boundaries

### GADM — Global Administrative Areas
**Access:** Directly in R: `geodata::gadm("ZMB", level = 1, path = tempdir())`
**Levels:** Level 0 = country outline | Level 1 = 10 provinces | Level 2 = 116 districts | Level 3 = wards
**License:** Free for academic and non-commercial use. Redistribution of modified versions restricted.
**Format:** Downloaded as SpatVector (terra) — always convert with `sf::st_as_sf()`
**Notes:** The authoritative source used in this training. Province names in `NAME_1`, district names in `NAME_2`. "North-Western" is spelled with a hyphen.

```r
library(geodata)
library(sf)
zmb_provinces <- st_as_sf(gadm("ZMB", level = 1, path = tempdir()))
zmb_districts <- st_as_sf(gadm("ZMB", level = 2, path = tempdir()))
```

---

### OCHA Common Operational Datasets (CODs) — Zambia
**Access:** https://data.humdata.org/dataset/cod-ab-zmb
**Levels:** Admin 0–3, wards included
**License:** Creative Commons Attribution for Interoperability (CC BY-SA)
**Format:** Shapefile, GeoJSON, KML — download and load with `sf::st_read()`
**Notes:** Maintained by the UN Office for the Coordination of Humanitarian Affairs. Updated after the 2023 district boundary revisions. Recommended when you need ward-level data or GeoJSON format for web applications.

```r
# After downloading from HDX:
zmb_adm2 <- sf::st_read("zmb_admbnda_adm2_OCHA.shp")
```

---

### Natural Earth (Country + Region Outlines)
**Access:** R package: `install.packages(c("rnaturalearth", "rnaturalearthdata"))`
**Scales:** 1:10m (detailed), 1:50m, 1:110m (simplified)
**License:** Public domain — no restrictions
**Notes:** Best for regional or continental context maps. For Zambia-specific district analysis, use GADM or OCHA.

```r
library(rnaturalearth)
zambia <- ne_countries(country = "Zambia", returnclass = "sf", scale = "medium")
africa <- ne_countries(continent = "Africa", returnclass = "sf", scale = "medium")
```

---

## 2. Population Data

### WorldPop — Zambia Gridded Population
**Access:** https://www.worldpop.org/geodata/listing?id=78
**Resolution:** 100m grid cells (GeoTiff raster)
**Years available:** 2000–2020, with projections to 2025
**License:** Creative Commons Attribution 4.0 (free to use with attribution)
**Format:** GeoTiff — load with `terra::rast()` or `stars::read_stars()`
**Notes:** Used to calculate population-weighted coverage metrics. Valuable for deriving the number of people within a signal coverage buffer, rather than just area coverage.

```r
library(terra)
zmb_pop <- rast("zmb_ppp_2020_1km_Aggregated.tif")  # after download
plot(zmb_pop)
```

---

### Zambia Statistics Agency — 2022 Census
**Access:** https://www.zamstats.gov.zm
**Content:** Province- and district-level population tables (CSV/Excel)
**License:** Public — official government statistics
**Notes:** The authoritative population reference for Zambia. The 2022 Census is the most current. Provincial totals used in this training (`population_2022` column) are derived from these estimates.
**Relevant datasets:**
- Zambia 2022 Census preliminary report (PDF with tables)
- Population by district (available as Excel on request from CSO)

---

## 3. Telecommunications Infrastructure

### GSMA Mobile Coverage Maps
**Access:** https://www.gsma.com/coverage (registration required, free for research)
**Content:** 2G, 3G, 4G, 5G coverage polygons by operator for Zambia
**License:** Free for research and non-commercial use — commercial redistribution prohibited
**Format:** Shapefile — load with `sf::st_read()`
**Notes:** Updated annually. The most comprehensive published source of mobile coverage polygons by operator in Zambia. Allows mapping of actual signal footprint rather than tower location proxies. Requires an account and data use agreement.

---

### OpenCelID
**Access:** https://opencellid.org (free download with registration)
**Content:** Crowdsourced cell tower locations: operator, radio type (GSM/UMTS/LTE), lat/lon, signal strength
**License:** Open Database License (ODbL) — free to use with attribution
**Format:** CSV — load with `read_csv()` and convert with `st_as_sf()`
**Update frequency:** Monthly
**Notes:** Coverage for rural Zambia is incomplete — urban areas are well-represented. Useful as a cross-reference for ZICTA's own registry. Do not treat as authoritative for regulatory purposes.

```r
# After downloading the Zambia subset:
celltowers <- read_csv("opencellid_ZMB.csv") |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)
```

---

### ZICTA Internal Registry
**Access:** Internal — ZICTA licensing and spectrum database
**Content:** Authoritative record of all licensed tower locations, frequencies, operator assignments, and spectrum zones
**Notes:** This is the correct source for any regulatory analysis. The `zicta_towers.csv` used in this training is a synthetic placeholder with realistic structure. ZICTA staff should use the actual registry for production work.

---

## 4. Topography and Physical Geography

### SRTM Digital Elevation Model (90m)
**Access:** R: `geodata::elevation_3s(country = "ZMB", path = tempdir())`
**Resolution:** ~90m grid cells
**License:** Public domain (NASA/USGS)
**Notes:** Useful for terrain analysis affecting signal propagation. Engineering staff can overlay tower locations on elevation to assess line-of-sight coverage.

```r
library(geodata)
zmb_elev <- elevation_3s(country = "ZMB", path = tempdir())
plot(zmb_elev)
```

---

### OpenStreetMap Data via osmdata
**Access:** R package: `install.packages("osmdata")`
**Content:** Roads, rivers, schools, health facilities, buildings, administrative boundaries — all contributed by mappers
**License:** Open Data Commons Open Database License (ODbL) — free
**Notes:** Excellent for adding contextual layers (road networks, schools, district capitals). Coverage quality varies: urban Zambia is well-mapped, rural areas may be incomplete.

```r
library(osmdata)

# Example: download main roads in Zambia
zambia_roads <- opq(bbox = "Zambia") |>
  add_osm_feature(key = "highway", value = c("primary", "secondary")) |>
  osmdata_sf()

ggplot() +
  geom_sf(data = zmb_provinces) +
  geom_sf(data = zambia_roads$osm_lines, colour = "grey40", linewidth = 0.3)
```

---

## 5. Socioeconomic Data for Joining

### ITU ICT Development Index
**Access:** https://www.itu.int/en/ITU-D/Statistics (free, registration required)
**Content:** Country-level ICT indicators: mobile subscriptions, internet penetration, fixed broadband, spectrum, quality of service
**License:** Free for non-commercial use with attribution
**Notes:** The `ict_indicators_sample_dataset.csv` used in Module 11–14 is derived from this source. Useful for benchmarking Zambia against regional peers (Kenya, Tanzania, Uganda, Rwanda, Malawi).

---

### World Bank Subnational Poverty Atlas
**Access:** https://data.worldbank.org (search "Zambia subnational poverty")
**Content:** Province-level poverty headcount ratios, consumption estimates
**License:** Creative Commons Attribution 4.0
**Notes:** Valuable for correlating ICT access with poverty indicators. Join to provincial sf data by province name. Useful for the Universal Access team's USAF targeting analysis.

---

### UNDP Human Development Data
**Access:** https://hdr.undp.org/data-center/specific-country-data
**Content:** Province-level HDI estimates for Zambia (2019 and 2022 available)
**License:** Free — cite UNDP HDR as source
**Notes:** The Human Development Index combines health, education, and income sub-indices. Useful as a composite deprivation indicator to complement ZICTA's own coverage data.

---

## 6. R Packages for Spatial Data Access

| Package | Install | Purpose | Notes |
|---------|---------|---------|-------|
| `sf` | `install.packages("sf")` | Core spatial package — read, transform, analyse | Required for all spatial work |
| `geodata` | `install.packages("geodata")` | Download GADM, elevation, climate directly in R | Used in this training |
| `terra` | `install.packages("terra")` | Raster data (population grids, elevation) | For WorldPop and SRTM |
| `stars` | `install.packages("stars")` | Spatiotemporal rasters (time-series grids) | Alternative to terra |
| `rnaturalearth` | `install.packages(c("rnaturalearth", "rnaturalearthdata"))` | Country and regional boundaries | Good for context maps |
| `osmdata` | `install.packages("osmdata")` | OpenStreetMap features via Overpass API | Roads, schools, POIs |
| `afrilearndata` | See GitHub: afrimapr/afrilearndata | African boundaries, populated places, roads | Africa-specific convenience package |
| `leaflet` | `install.packages("leaflet")` | Interactive maps | Used in this training |
| `leaflet.extras` | `install.packages("leaflet.extras")` | Additional leaflet plugins | Used in this training |
| `tmap` | `install.packages("tmap")` | Alternative to ggplot2+sf for thematic maps | Mode switching: static and interactive |

---

## 7. Working with Shapefiles in R

**If you have a `.shp` file** (e.g., downloaded from OCHA HDX):
```r
library(sf)
my_data <- st_read("path/to/file.shp")
```

**If you have a `.geojson` file:**
```r
my_data <- st_read("path/to/file.geojson")
```

**If you have a `.gpkg` (GeoPackage) file:**
```r
my_data <- st_read("path/to/file.gpkg")
```

**To save an sf object for later use:**
```r
st_write(my_data, "output.gpkg", delete_dsn = TRUE)  # GeoPackage (recommended)
st_write(my_data, "output.shp")                       # Shapefile
st_write(my_data, "output.geojson")                   # GeoJSON
```

**GeoPackage (`.gpkg`) is the recommended format** for saving sf objects locally. Unlike shapefiles, it stores everything in a single file, preserves full column names (shapefiles truncate to 10 characters), and supports multiple layers per file.

---

## 8. Coordinate Reference Systems Quick Reference

| EPSG | Name | Units | Use for |
|------|------|-------|---------|
| 4326 | WGS84 | Degrees | Display, plotting, leaflet, GPS data |
| 32735 | UTM Zone 35S | Metres | Distance and area calculations in Zambia |
| 32734 | UTM Zone 34S | Metres | Western Zambia (Mongu area) |
| 3857 | Web Mercator | Metres | Web tile services (rarely needed directly) |
| 20936 | Arc 1960 / UTM Zone 36S | Metres | Historical Zambian datasets |

**The two you will use most:** 4326 (display) and 32735 (measure).

---

*For questions about data sources or access, contact Matteo Larrode (m.larrode@theigc.org) or the ZEL team.*
