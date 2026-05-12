# Capstone Submissions — Geospatial Session

Each functional group saves their capstone output here. Work only in your group's subfolder.

## Group Folders

| Group | Folder | Task |
|-------|--------|------|
| Engineering | `GroupA_Engineering/` | ZAMTEL tower gap analysis |
| Statistical Unit | `GroupB_Statistical_Unit/` | Four-indicator inequality map |
| Financial Statistics | `GroupC_Financial_Statistics/` | Compliance score choropleth |
| Postal Services | `GroupD_Postal_Services/` | USAF project interactive map |
| Universal Access | `GroupE_Universal_Access/` | Underinvestment priority analysis |

## What to Submit

Save at minimum one file to your group folder:
- Your R script (`GroupA_capstone.R`, etc.)
- Optionally: a saved map image (`GroupA_map.png`) exported with `ggsave()`

## How to Submit

From the `ZICTA_training/` directory in your terminal:

```bash
git add Capstone/GroupA_Engineering/
git commit -m "GroupA: Engineering tower gap analysis"
git push
```

Then share the GitHub link with the facilitator for the group presentations.

## Saving a Static Map as PNG

```r
# After producing your ggplot map, save it:
ggsave("Capstone/GroupA_Engineering/GroupA_map.png",
       width = 10, height = 7, dpi = 150)
```

Leaflet maps cannot be saved with ggsave — screenshot them or use `mapview::mapshot()`.
