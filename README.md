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

A collection of presentations and teaching tools for statistics and research methods, built with [Manim](https://www.manim.community/) and [manim-slides](https://github.com/jeertmans/manim-slides).

---

## Contents

### 📊 Presentations

| Folder | Topic | Description |
|--------|-------|-------------|
| [`pValue/`](./pValue/media/videos/pvalue_slides/1080p60/PValue.mp4) | What is a p-value? | An animated, plain-language walkthrough — coin story, falling-dots simulation, common misconceptions |

---

## Running a Presentation

Each presentation is pre-rendered. You only need `manim-slides` to present.

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

---

## Tech Stack

| Tool | Role |
|------|------|
| [Manim Community](https://www.manim.community/) | Animation engine |
| [manim-slides](https://github.com/jeertmans/manim-slides) | Interactive presentation layer |
| [TeX Live](https://tug.org/texlive/) | LaTeX → SVG for equations |
| [ffmpeg](https://ffmpeg.org/) | Video encoding |
