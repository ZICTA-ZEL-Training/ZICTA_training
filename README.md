# ZICTA R Training Programme

Repository hosting ZEL's 16-module R training programme for ZICTA staff across: Engineering, Statistical Unit, Financial Statistics, Postal Services and Universal Access.

---

## Getting Started

**Complete these steps BEFORE the spatial analysis session.**

This repository contains all training materials, datasets, and R scripts. You will need to *clone* (download) it to your computer to participate.

---

### Step 1: Check Prerequisites

You need three things installed on your computer:

| Tool | Check how | Download if missing |
|------|-----------|---------------------|
| **R** (version ≥ 4.2) | Open RStudio → type `R.version$major` | https://cran.r-project.org |
| **RStudio** | Open RStudio → Help → About RStudio | https://posit.co/download/rstudio-desktop |
| **Git** | Open a terminal → type `git --version` | https://git-scm.com/downloads |

**To open a terminal:**
- Windows: Search "Git Bash" in the Start menu (installed with Git)
- Mac: Applications → Utilities → Terminal

---

### Step 2: Join the ZICTA GitHub Organisation

The repository is private. To access it you must:

1. Create a GitHub account at https://github.com if you haven't already
2. Share your GitHub username with your training coordinator
3. Accept the invitation email from the `ZICTA-ZEL-Training` GitHub organisation

You will receive an invitation to: `github.com/ZICTA-ZEL-Training`

---

### Step 3: Clone the Repository

Open **Git Bash** (Windows) or **Terminal** (Mac/Linux).

Navigate to where you want to store the training files. For example:
```bash
cd Documents
```

Then clone the repository:
```bash
git clone https://github.com/ZICTA-ZEL-Training/ZICTA_training.git
```

This downloads the full repository — all scripts, slides, and datasets — to a new folder called `ZICTA_training`.

**Verify it worked:**
```bash
cd ZICTA_training
ls
```
You should see: `Datasets/`, `Modules/`, `Facilitation Guides/`, `README.md`, `ZICTA_training.Rproj`

---

### Step 4: Open the Project in RStudio

**This step is important.** Opening the `.Rproj` file sets your working directory to the repository root automatically. All `read_csv("Datasets/...")` calls in the scripts will then work without any manual path adjustments.

1. Open RStudio
2. File → Open Project
3. Navigate to the `ZICTA_training` folder
4. Click `ZICTA_training.Rproj`

RStudio will reload. You should see `ZICTA_training` in the top-right corner of the window, and a **Git** tab will appear in the top-right pane.

---

### Step 5: Install Required R Packages

In the RStudio Console, run:
```r
install.packages(c(
  "tidyverse",
  "sf",
  "geodata",
  "leaflet",
  "leaflet.extras",
  "viridis",
  "RColorBrewer"
))
```

This takes 3–5 minutes. You only need to do this once.

---

### Step 6: Test Your Setup

Run this in the RStudio Console:
```r
library(tidyverse)
library(sf)
coverage <- read_csv("Datasets/zicta_coverage_by_province.csv")
nrow(coverage)
```

Expected output: `[1] 10`

If you see 10 rows, you are ready for the session.

---

## Keeping Your Copy Up to Date

The facilitator may push corrections or new materials before the session. To download the latest version:

```bash
git pull
```

Or in RStudio: click the **Pull** button (blue arrow pointing down) in the Git tab.

---

## During the Session: Your Workflow

```
┌─────────────────────────────────────────────────┐
│  1. git pull        ← get latest materials      │
│  2. Work in R       ← follow the session script │
│  3. git add         ← stage your capstone file  │
│  4. git commit      ← save a named snapshot     │
│  5. git push        ← share with the group      │
└─────────────────────────────────────────────────┘
```

---

## Troubleshooting

**"git: command not found"** — Git is not installed. Download from https://git-scm.com/downloads and restart your terminal.

**"Permission denied" when cloning** — You have not yet been added to the ZICTA GitHub organisation. Contact your training coordinator with your GitHub username.

**read_csv() says file not found** — Make sure you opened the `.Rproj` file, not just the `.R` script. The project file sets the correct working directory.
