<div align="center">

<svg width="100%" viewBox="0 0 800 150" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%"   stop-color="#0f2027"/>
      <stop offset="50%"  stop-color="#203a43"/>
      <stop offset="100%" stop-color="#2c5364"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="800" height="150" rx="14" fill="url(#bg)"/>

  <!-- Animated accent line sweeping left → right -->
  <line x1="0" y1="146" x2="0" y2="146" stroke="#4a9eda" stroke-width="3" stroke-linecap="round">
    <animate attributeName="x2" from="0" to="800" dur="1.4s" begin="0s" fill="freeze" calcMode="spline"
             keySplines="0.4 0 0.2 1" keyTimes="0;1"/>
  </line>

  <!-- Title -->
  <text x="400" y="75" text-anchor="middle"
        font-family="Arial, sans-serif" font-size="34" font-weight="bold" fill="white" opacity="0">
    Teaching Materials
    <animate attributeName="opacity" from="0" to="1" dur="0.8s" begin="0.3s" fill="freeze"/>
  </text>

  <!-- Subtitle -->
  <text x="400" y="112" text-anchor="middle"
        font-family="Arial, sans-serif" font-size="16" fill="#90b8d0" opacity="0">
    Statistics · Methodology · Quantitative Research
    <animate attributeName="opacity" from="0" to="1" dur="0.8s" begin="0.9s" fill="freeze"/>
  </text>
</svg>

</div>

&nbsp;

A collection of presentations and teaching tools for statistics and research methods, built with [Manim](https://www.manim.community/), [manim-slides](https://github.com/jeertmans/manim-slides) and [Quarto](https://quarto.org/).

---

## Contents

### 📊 Presentations

| Folder | Topic | Description |
|--------|-------|-------------|
| [`pValue/`](./pValue/media/videos/pvalue_slides/1080p60/PValue.mp4) | What is a p-value? | An animated, plain-language walkthrough — coin story, falling-dots simulation, common misconceptions |
| [`tTests/`](./tTests/media/videos/ttest_slides/1080p60/TTestTrap.mp4) | The t-test trap | Why the t-test shouldn't be your first choice (`manim-slides present TTestTrap`) |
| [`CLT/`](./CLT/) | Central Limit Theorem | Quarto simulations of the sampling distribution of the mean, median & mode (Python/marimo and R versions) |
| [`building_your_model/`](./building_your_model/) | Building a model for your study | Multilevel, generalised linear and Bayesian models added piece by piece to one LEGO-building experiment — DAGs and colliders, random effects and partial pooling, count models, priors (Quarto reveal.js: open `brick_dag_slides.html` in a browser) |

---

## Running a Presentation

Each presentation is pre-rendered. How you open it depends on the format.

### HTML presentations (Quarto reveal.js)

`building_your_model/brick_dag_slides.html` is a single self-contained file — no install and no internet connection needed. Download it and open it in any web browser.

Use **→ / Space** to advance, **←** to go back, **F** for fullscreen, **S** for the speaker view with notes, and **Esc** for a slide overview.

### Manim presentations (pValue, tTests)

You only need `manim-slides` to present.

**1. Install the presenter**
```bash
pip install "manim-slides[pyqt6]"
```

**2. Navigate to the folder and present**
```bash
cd pValue
manim-slides present PValue
```

Use **→ / Space** to advance, **← / Backspace** to go back, **Escape** to quit.

---

## Re-rendering from Source

If you want to modify a presentation and re-render it:

### Manim presentations (pValue, tTests)

**Prerequisites**
- Python 3.9+
- [TeX Live](https://tug.org/texlive/) (for LaTeX rendering)
- [ffmpeg](https://ffmpeg.org/) (for video encoding)

```bash
cd pValue

# Create and activate a virtual environment
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # macOS / Linux

# Install dependencies
pip install manim "manim-slides[pyqt6]"

# Render, then present
manim-slides render pvalue_slides.py PValue
manim-slides present PValue
```

> **Note:** The first render is slow because LaTeX compiles every maths expression from scratch. Subsequent renders reuse the cache and are much faster.

### Quarto deck (building_your_model)

**Prerequisites**
- [Quarto](https://quarto.org/)
- [R](https://www.r-project.org/) with the packages below

```r
install.packages(c("knitr", "rmarkdown", "ggplot2", "patchwork", "lme4", "svglite"))
```

```bash
cd building_your_model
quarto render brick_dag_slides.qmd
```

| File | Role |
|------|------|
| `brick_dag_slides.qmd` | The slides (text, layout, click order) |
| `brick_dag.R` | Draws the LEGO-brick DAGs and hand-drawn figures as inline SVG |
| `lego_figs.R` | Simulates the LEGO dataset and draws the data figures (written to `figs/`) |
| `brick_dag.css` | Deck styling: colours, fragment dimming, layout |
| `count_return_check.R` | Stand-alone check behind the count-model slide — not used by the deck; needs `lme4` and `glmmTMB` |

> **Note:** `figs/` is created during the render, so it doesn't need to be committed. The output is a single self-contained `brick_dag_slides.html`.

---

## Tech Stack

| Tool | Role |
|------|------|
| [Manim Community](https://www.manim.community/) | Animation engine |
| [manim-slides](https://github.com/jeertmans/manim-slides) | Interactive presentation layer |
| [Quarto](https://quarto.org/) | HTML slide decks (reveal.js) and simulation documents |
| [R](https://www.r-project.org/) + [ggplot2](https://ggplot2.tidyverse.org/) | Simulated data and figures for the Quarto decks |
| [TeX Live](https://tug.org/texlive/) | LaTeX → SVG for equations |
| [ffmpeg](https://ffmpeg.org/) | Video encoding |
