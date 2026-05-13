# Facilitation Guide: Spatial Analysis Session
**ZICTA R Training Programme**
Matteo Larrode & Kosam Chola

---

## 0. Pre-Session Setup (Complete Before the Day)

This section covers the logistics of getting all participants into the repository and able to push their capstone work. Most failures on the day are caused by skipping these steps.

### 0.1 GitHub Organisation Setup

The repository lives at `github.com/ZICTA-ZEL-Training/ZICTA_training`. Before the session:

1. **Collect GitHub usernames** from all participants (they were asked to register in advance — follow up with anyone who hasn't)
2. **Add participants to the ZICTA GitHub org** (Owner or Admin access required):
   - Go to `github.com/ZICTA-ZEL-Training` → People → Invite member
   - Invite by GitHub username
   - Set role: **Member** (not Owner)
3. **Check repo permissions**: The `ZICTA_training` repo should allow write access for org members. In the repo: Settings → Collaborators and teams → confirm the org's default member role can push.

### 0.2 Pre-Session Check

Send participants this message:

> *"Before the spatial analysis session, please complete these three steps: (1) create a GitHub account if you don't have one, (2) reply to this message with your GitHub username, (3) follow the setup instructions in the README.md in the repository."*

### 0.3 Day-of Setup (Before 09:15)

**Before participants arrive:**
- Open the rendered slide deck (`ZICTA_Geo_Slide_Deck.html`) in a browser tab
- Open `ZICTA_Geo_Live_Script.R` in RStudio, scrolled to line 88 (start of Section 1)
- Have a Git Bash / terminal window open alongside RStudio

**As participants arrive (not a formal session activity — do while people settle):**
1. Ask each person to open RStudio terminal
2. Confirm `git --version` returns something (not "command not found"). Anyone who hasnt downloaded git, do it (url is https://git-scm.com/install/windows).

3. Ask each person to open Github on browser and join the ZICTA-ZEL-Training organisation
4. Everyone needs to run `git clone https://github.com/ZICTA-ZEL-Training/ZICTA_training.git` in their preferred folder together

5. Everyone opens `ZICTA_training.Rproj` in RStudio. Anyone with path errors: check they opened the `.Rproj` file, not a `.R` script
6. Everyone runs the setup from the README.md.

**Kosam** circulates to help stragglers while **Matteo** opens the session at 09:30 sharp.

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

### 0.4 Troubleshooting Access

| Problem | Most likely cause | Fix |
|---------|------------------|-----|
| "Repository not found" when cloning | Not added to GitHub org | Add them to org; they re-accept invitation |
| "Permission denied (publickey)" | SSH vs HTTPS confusion | Use HTTPS URL: `https://github.com/...` not `git@github.com:...` |
| "Authentication failed" when pushing | Not logged in to GitHub in Git Bash | Run `git config --global user.email "their@email.com"` then push again; browser will prompt for GitHub login |
| git not installed | Skipped setup step | Install from https://git-scm.com and restart terminal |

---

## 1. Session Overview

**Format:** Half-day  
**Live instruction:** 09:30–11:45  
**Capstone presentation:** 11:45–12:30 (Kosam Chola, standalone)

### Learning Objectives

By the end of the live instruction, participants will be able to:

1. Explain the difference between geographic (WGS84) and projected (UTM) coordinate reference systems and know when to use each
2. Download Zambia administrative boundaries using `geodata::gadm()` and convert to sf format
3. Produce a province-level choropleth map by joining ZICTA data to a GADM shapefile using `left_join()`
4. Build a publication-ready choropleth with viridis palette, labels, and correct colour direction
5. Build a basic interactive leaflet map with hover labels and a point layer

*Sections 4 and 5 of the live script (spatial joins, coverage gap analysis) are reference material — not covered in the live session. The capstone presentation by Kosam demonstrates these techniques as a complete worked example.*

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

---

## 2. Precise Timetable

This is your navigation guide for the session. Each block specifies time, mode, and reference, followed by what to run and what to say.

**Legend:**  
`SLIDE` — switch to slide deck  
`R` — switch to RStudio / live script (line numbers refer to `ZICTA_Geo_Live_Script.R`)  
`VERBAL` — talking point, no screen change  
`BREAK` — pause

---

### Before 09:15 | Facilitator Prep

**Matteo:**
- RStudio open → `ZICTA_training.Rproj` → `ZICTA_Geo_Live_Script.R` scrolled to line 88
- Confirm GADM cached: `nrow(zmb_provinces)` → `10`; `nrow(zmb_districts)` → `116`
- Slide deck open in browser tab (rendered HTML)
- Terminal / Git Bash window open alongside RStudio

**Kosam:**
- Prepare capstone materials for the 11:45 standalone presentation
- Available to help participants with setup issues as they arrive

---

### 09:15–09:30 | Participants Arrive

Not a formal session block. While people settle:
- Kosam circulates; Matteo is available at the front
- Ask each participant to run: `coverage <- read_csv("Datasets/zicta_coverage_by_province.csv"); nrow(coverage)` → should return `10`
- If `0` or error: check working directory with `getwd()` — confirm `.Rproj` is open, not a standalone script

---

### 09:30–09:35 (5 min) | `SLIDE` — Title → Today's Session → Why Spatial Analysis?

Show slides from the title through the "Why Spatial Analysis?" section.

- "Today we go from tabular data to maps. Everything you've learned in dplyr and ggplot2 still applies — we're adding one new concept: geometry."
- "Two facilitators: I'll lead the live coding throughout; Kosam will present the capstone from 11:45."
- Agenda: git (15 min) → spatial fundamentals (45 min) → break → choropleth (35 min) → leaflet (25 min) → capstone 11:45

→ *Move on at 09:35*

---

### 09:35–09:50 (15 min) | `SLIDE` — Git Section

Show slides: **Why Git? The Problem It Solves** → **The Three Concepts You Need Today** → **Getting the Training Materials: `git clone`** → **Submitting Your Capstone: The Full Workflow**

Key points to land:
- "You already cloned the repo before today. The three commands for submission are `git add`, `git commit -m "..."`, `git push` — we'll use them at the end."
- "Kosam will walk through the actual submission workflow at the end of the session."
- "Your capstone file goes in `Modules/Geo Session/` with your name."

Do **not** do a live push here — conceptual explanation only.

→ *Move on at 09:50*

---

### 09:50–09:58 (8 min) | `R` lines 94–113 + `SLIDE` — sf Objects Are Just Data Frames

Switch to RStudio. Script at line 94.

| Line(s) | Code | What to say |
|---------|------|-------------|
| 96 | `class(zmb_provinces)` | "Two classes: sf AND data.frame. Every dplyr verb you know still works." |
| 102 | `glimpse(zmb_provinces)` | "Spot the geometry column at the bottom. It holds the polygon shapes — one per row." |
| 106–108 | `filter(NAME_1 == "Lusaka") \|> select(NAME_1, COUNTRY)` | "Geometry tags along even though we didn't select it. That's the sticky column feature — not a bug." |

Show slide **sf Objects Are Just Data Frames** alongside or after running.

[PAUSE] "What does `class()` tell us? Why does 'data.frame' matter?"

→ *Move on at 09:58*

---

### 09:58–10:10 (12 min) | `SLIDE` — CRS + `R` lines 115–162

Show slides: **What Is a Coordinate Reference System?** + **Why CRS Matters: The Area Trap**

| Line(s) | Code | What to say |
|---------|------|-------------|
| 118 | `st_crs(zmb_provinces)` | "WGS84 — the GPS standard. Units are degrees. Good for display, bad for measuring." |
| 129–130 | `st_transform(crs = 32735)` | "UTM Zone 35S — units are metres, optimised for southern-central Africa." |
| 132 | `st_crs(zmb_provinces_utm)$input` | "Confirm the transform worked: output should say EPSG:32735." |
| 136–147 | area calculation + arrange | Run the whole block. Show output. "area_wrong_units is in degrees-squared — meaningless. area_sqkm: Western at 126,000 km² matches published figures." |

[PAUSE] "When would you use 4326 vs 32735?"  
Answer cue: 4326 for anything that ends in ggplot or leaflet. 32735 when running `st_area()`, `st_distance()`, `st_buffer()`.

→ *Move on at 10:10*

---

### 10:10–10:23 (13 min) | `SLIDE` — Your First Regulatory Map + `R` lines 164–188

Show slide: **Downloading Zambia Boundaries in R** (briefly — data already loaded, context only)  
Then: **Your First Regulatory Map**

| Line(s) | Code | What to say |
|---------|------|-------------|
| 167–171 | `ggplot(zmb_provinces) + geom_sf() + ...` | "`geom_sf()` draws polygons, lines, or points — it reads the geometry type automatically. `theme_void()` removes the axes." |
| 177–184 | labeled map with `geom_sf_label()` | "`geom_sf_label()` places labels at polygon centres. Run this." |

[ACTIVITY — 2 min] "Change `fill = "#f0f0f0"` to a colour of your choice. Any valid R colour string or hex code works."

[PAUSE] "Is this map correct? Does it match what you expect Zambia to look like?"

→ *Move on at 10:23*

---

### 10:23–10:35 (12 min) | `VERBAL` — Section 1 Recap + Questions

Recap the three concepts from Section 1 without running new code:
1. sf = data frame + geometry column (sticky — it travels with filter, select, join)
2. CRS: 4326 for display, 32735 for measuring
3. `geom_sf()` is the only new ggplot2 function — everything else is Module 1–10 knowledge

Open floor for questions. Kosam handles individual output or package issues.

If time remains: show slide **What ZICTA's Annual Report Currently Shows** → "This is what we're replacing — a table. With two lines of ggplot2 we now have a map."

---

### 10:35–10:45 | `BREAK` (10 minutes)

---

### 10:45–10:53 (8 min) | `SLIDE` — Spatial Attribute Join + `R` lines 200–217

Show slide: **The Core Pattern: A Spatial Attribute Join**

| Line(s) | Code | What to say |
|---------|------|-------------|
| 203 | `sort(zmb_provinces$NAME_1)` | "Check GADM's exact spelling. Note: 'North-Western' has a hyphen." |
| 204 | `sort(coverage$province)` | "Check our CSV spelling. Both vectors must match exactly — 10 names, identical strings." |
| 208–209 | `left_join(coverage, by = c("NAME_1" = "province"))` | "Same `left_join()` from Module 10. The geometry column stays attached — the sf object survives the join." |
| 212–215 | validation filter | "Run this. `character(0)` = no mismatches = good. Any names printed here are spelling problems to fix before going further." |

[PAUSE] "What does `character(0)` mean? Why don't we skip this validation step?"

→ *Move on at 10:53*

---

### 10:53–11:03 (10 min) | `SLIDE` — Basic Choropleth + `R` lines 219–231

Show slide: **Basic Choropleth**

| Line(s) | Code | What to say |
|---------|------|-------------|
| 222–227 | basic choropleth | Run. Wait for the plot to render. Say nothing for 30 seconds — let participants read the map on their own screens. |

[PAUSE — 2 min] "What does this map tell us? Who can describe it in one sentence?"  
Expected answer: Lusaka and Copperbelt have the highest internet penetration; Western, Muchinga, and Luapula are the lowest. The urban-rural divide is visible at a glance.

→ *Move on at 11:03*

---

### 11:03–11:13 (10 min) | `SLIDE` — Publication-Ready + `R` lines 233–267

Show slides: **Publication-Ready: Labels and Palette Direction** + **Colour Palette Choices**

| Line(s) | Code | What to say |
|---------|------|-------------|
| 236–242 | centroid calculation block | Run without dwelling. "We compute centroids in UTM for accuracy, then transform back to 4326 for ggplot. Trust the block — the full explanation is in the script comments." |
| 244–267 | publication-ready map | Run. Show output. "`direction = -1` reverses the palette: darker = lower penetration. Design choice: draw the eye to the problem, not the well-served areas. Always explain palette choices in the caption." |

→ *Move on at 11:13*

---

### 11:13–11:20 (7 min) | `SLIDE` — Faceted Choropleth + `R` lines 279–312

Show slides: **Faceted Choropleth: Comparing Two Indicators** → **Reading the Faceted Map**

| Line(s) | Code | What to say |
|---------|------|-------------|
| 279–289 | `pivot_longer(...)` block | "Same `pivot_longer()` from earlier modules. The geometry column stays sticky even after pivoting." |
| 291–303 | faceted ggplot | Run. Show the two-panel map. |

[PAUSE] "Mobile coverage is near-universal. Internet penetration is much lower in rural provinces. What explains the gap?"  
Discussion prompt: affordability of data bundles, device ownership, digital literacy — these are ZICTA policy questions, not just data observations.

→ *Move on at 11:20*

---

### 11:20–11:23 (3 min) | `SLIDE` — leaflet vs ggplot2 + The leaflet Pipeline

Show slides: **leaflet vs ggplot2** + **The leaflet Pipeline**

"ggplot2 = reports and printed maps. leaflet = exploration and dashboards — they pan, zoom, and respond to clicks. Different syntax: `%>%` pipes, `addXxx()` functions, no `+` signs between layers."

→ *Move on at 11:23*

---

### 11:23–11:32 (9 min) | `SLIDE` — Interactive Choropleth + `R` lines 324–357

Show slide: **Interactive Choropleth with Hover Labels**

| Line(s) | Code | What to say |
|---------|------|-------------|
| 329–333 | `colorNumeric(...)` | "Build the palette object first — this is leaflet's equivalent of `scale_fill_viridis_c()`. We reference it with `~pal_internet(...)` in the map." |
| 335–348 | basic leaflet map | Run. Open in Viewer pane. "The `~` (tilde) means 'evaluate this formula on the data'. You'll see it everywhere in leaflet." |

[PAUSE] Zoom into Western province. Compare colour to Lusaka. "Does this match what we saw in the ggplot map?"

→ *Move on at 11:32*

---

### 11:32–11:40 (8 min) | `R` lines 359–393

| Line(s) | Code | What to say |
|---------|------|-------------|
| 361–385 | hover + popup map | Run. Open in Viewer. "`CartoDB.Positron` = cleaner background than OSM. `highlightOptions()` controls the hover border. `lapply(htmltools::HTML)` tells leaflet to render bold tags in the label." |

[PAUSE] Hover over provinces. "Which province has the widest gap between mobile coverage and internet penetration?"

→ *Move on at 11:40*

---

### 11:40–11:45 (5 min) | `R` lines 395–413 + `VERBAL` — Section 3 Close

| Line(s) | Code | What to say |
|---------|------|-------------|
| 399–400 | `st_as_sf(coords = c("longitude", "latitude"), crs = 4326)` | "Critical rule: X before Y — longitude before latitude. Swap them and your points end up in the Atlantic. R does not warn you." |
| 405–407 | `plot(st_geometry(towers_sf), axes = TRUE); plot(st_geometry(zmb_provinces), add = TRUE)` | "Quick sanity check before building any map: do the points look right geographically?" |

VERBAL: "Lines 449–511 in the live script build the full layered map with operator toggle controls — explore it after the session. Sections 4 and 5 cover spatial joins and the coverage gap analysis, also in the script as reference material."

**Matteo:** "That's the live coding portion. Kosam will now present the capstone, which brings all of this together into a complete analytical output."

---

### 11:45 | Handover to Kosam Chola

Matteo steps back. Kosam takes over at the front.

---

### 11:45–12:30 (45 min) | CAPSTONE PRESENTATION — Kosam Chola

*Delivered as a standalone by Kosam Chola. No group work.*

Suggested structure:

| Time | Content |
|------|---------|
| 11:45–11:50 | Introduce the capstone brief: analytical question, data sources, output |
| 11:50–12:15 | Walk through the full analysis |
| 12:15–12:25 | Q&A from participants |
| 12:25–12:30 | Close: key functions slide, Zambia spatial data sources, what comes next |

**Slide references for close:** "Key Functions Reference" + "Zambia Spatial Data Sources" + "What Comes Next"

---

## 3. What to Cut If Running Behind

If a section is running 10–15 minutes late, cut in this priority order:

| Cut this | Time saved | How to handle |
|----------|-----------|----------------|
| **Sec 1.2** CRS area demo (lines 136–147) | ~6 min | State the rule verbally — "32735 for measuring, 4326 for display." Point to the lines in the script and move on. |
| **Sec 2.3** centroid computation detail (lines 236–242) | ~4 min | Run the block without explaining the UTM reproject steps — just say "trust this block" and show the output. |
| **Sec 2.4** faceted choropleth (lines 279–312) | ~7 min | Show the slide screenshot instead of live coding. Point to lines for self-study. |
| **Sec 3.2** hover + popup map (lines 359–393) | ~8 min | Show the slide screenshot. Skip live coding of this block entirely. |

**Do not cut:**
- **Section 2.1 join validation** (lines 212–215) — the diagnostic that prevents silent NAs is a core habit, not optional.
- **Section 1.3 first map** (lines 167–184) — the payoff moment of Section 1; losing it deflates the session.

---

## 4. Common Technical Problems and Fixes

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

### Adding a Buffer Zone Analysis
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
