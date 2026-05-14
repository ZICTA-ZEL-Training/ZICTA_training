# ZICTA R Training Programme — Project Guide for Claude

## What this project is

A repository of training materials for a spatial analysis session delivered to ZICTA (Zambia Information and Communications Technology Authority) staff, as part of a broader 16-module R training programme run by ZEL/IGC.

**Facilitators:** Matteo Larrode (IGC) and Kosam Chola  
**Format:** Half-day (09:30–12:30)  
**GitHub org:** `github.com/ZICTA-ZEL-Training` — this repo is `ZICTA_training`

The session teaches: sf objects and CRS, province choropleth maps (ggplot2), spatial joins and coverage gap analysis, and ends with a git training + capstone project introduction by Kosam Chola. Interactive maps (leaflet) are included as reference material in the scripts.

---

## Directory structure

```
ZICTA_training/
├── Datasets/                          ← public, committed
│   ├── zicta_coverage_by_province.csv
│   ├── zicta_towers.csv
│   └── zicta_usaf_projects.csv
├── Spatial_Session/
│   ├── Facilitator/                   ← GITIGNORED — never on GitHub
│   │   ├── ZICTA_Spatial_Coding_Answer.R   ← answer key
│   │   ├── ZICTA_Geo_Slide_Deck.qmd        ← Quarto revealjs slide deck
│   │   ├── ZICTA_Geo_Slide_Deck.html       ← rendered slide deck (open in browser)
│   │   └── Geo_Session_Facilitation_Guide.md
│   └── Student/                       ← public, committed
│       ├── ZICTA_Spatial_Student.R         ← student fill-in-the-blank script
│       └── Zambia_Spatial_Data_Sources.md
├── README.md                          ← participant setup instructions (Steps 1–6)
├── ZICTA_training.Rproj
└── .gitignore                         ← ignores Spatial_Session/Facilitator/ and *.html
```

**Important:** `Datasets/` paths in the slide deck are `../../Datasets/` (two levels up from `Spatial_Session/Facilitator/`). The student script uses `Datasets/` (relative to project root via `.Rproj`).

---

## The two-script design

- **`ZICTA_Spatial_Student.R`** — the script Matteo runs live with students. Contains blanks (BLANK A through BLANK G) that students fill in during the session. Section 3.5 and Section 4 (leaflet) are marked as reference material (not covered live).
- **`ZICTA_Spatial_Coding_Answer.R`** — identical structure to the student script, all blanks filled in. Matteo uses this to follow along and verify answers. Gitignored.

There is no separate "live script" — the answer key IS the facilitator's live script.

---

## Datasets

All three CSVs are synthetic but realistic. Province names are matched to GADM (`NAME_1`) — with one **deliberate typo** for teaching purposes:

| File | Rows | Key columns | Notes |
|------|------|-------------|-------|
| `zicta_coverage_by_province.csv` | 10 | province, internet_penetration_pct, mobile_coverage_pct, broadband_per_100, population_2022 | **"Northwestern" is intentionally misspelled** — should be "North-Western" (GADM uses a hyphen). Taught as a join validation exercise in Section 2.1. |
| `zicta_towers.csv` | 72 | tower_id, operator, license_type, latitude, longitude, province, district, year_installed | 4 operators: Airtel Zambia, MTN Zambia, ZAMTEL, Liquid Telecom |
| `zicta_usaf_projects.csv` | 30 | project_id, project_name, province, district, latitude, longitude, budget_usd, start_year, status, target_population | Status: Completed / Ongoing / Planned. Weighted towards underserved provinces. |

---

## Session structure (blanks A–G)

| Blank | Section | Answer |
|-------|---------|--------|
| A | 1.2 `st_transform` | `32735` |
| B | 1.2 `st_area` transform | `32735` |
| C | 2.1 `left_join` by column | `"NAME_1"` |
| D | 2.1 NA validation | `internet_penetration_pct` |
| E | 3.2 `st_join` column to retain | `NAME_1` |
| F | 3.3 `replace_na` value | `0` |
| G | 3.1 `st_as_sf` coords | `c("longitude", "latitude"), crs = 4326` |

The Section 2.1 join validation is intentionally broken by the CSV typo. The student script shows the full fix sequence: `sort()` comparison → join → validate (returns `"North-Western"`) → `case_when` fix → re-join → verify (`character(0)`).

---

## Key CRS rule

- **EPSG:4326** (WGS84, degrees) — for display, ggplot2, leaflet
- **EPSG:32735** (UTM Zone 35S, metres) — for `st_area()`, `st_distance()`, `st_buffer()` in Zambia

---

## Capstone project

After the spatial session, each functional group creates their own repo in the `ZICTA-ZEL-Training` org (e.g., `ZICTA_capstone_engineering`). Kosam Chola leads the capstone admin from 12:00 onward. Matteo leads a 30-minute git mini-training immediately before the handover, covering: why version control, the five commands, creating a repo, team workflow, and common errors.

---

## Known pending items

- Changes from recent sessions are staged but not yet committed (`git status` will show them).

---

## Working conventions

- The user edits files actively in parallel with Claude — always read before editing to avoid conflicts.
- The facilitation guide timetable is iterated frequently; check the current file before updating it.
- `Spatial_Session/Facilitator/` is gitignored. Never try to `git add` anything from that folder.
- HTML files are gitignored globally (`*.html`). The rendered slide deck (`ZICTA_Geo_Slide_Deck.html`) lives only in `Facilitator/` and is not committed.
