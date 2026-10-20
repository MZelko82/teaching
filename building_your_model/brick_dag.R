# brick_dag.R -----------------------------------------------------------------
# Brick-built DAG for "Building the right model" (Oct 20 workshop).
#
# How it works
# - Every element (brick, arrow, overlay) has a `step` (when it appears) and an
#   optional `until` (the step at which it fades out).
# - show_dag(upto, frag, highlight, shown, layout) draws:
#     * every element whose step is in `shown` (default 1:upto) and whose
#       `until` is not, as STATIC, and
#     * every element whose step is in `frag` as a revealjs FRAGMENT, in the
#       order given (frag[1] -> fragment index 1, frag[2] -> index 2, ...).
#   Elements whose `until` is in `frag` fade out at that fragment.
#   Steps keep their numbers; `shown` and `frag` set the order of appearance
#   (e.g. shown = 1:2, frag = c(3, 4) adds traits, then the two builds).
# - Each element is wrapped in <g class="piece">. When a click brings pieces
#   in, every other piece dims (brick_dag.css, --dag-dim); clicks that only
#   remove pieces dim nothing. highlight = FALSE turns dimming off.
# - `lit` = steps at which an older element stays at full strength while
#   the new pieces arrive (an empty fragment marker inside its piece).
# - Bricks carry only the variable name; level details and model roles are
#   notes (plain text) outside the brick, so both can use a large font.
# - A brick that changes is replaced, not covered: the old element gets
#   `until` = the step of its replacement (grey Session factors -> yellow at
#   step 8; build errors -> copies without studs under their NegBin plates
#   at step 10).
#   Covering alone breaks under dimming: both layers turn translucent and
#   the old label shows through the new one.
#
# Steps (fragment plan; numbers are names, the slides set the order)
#   1  Hook:       Instructions -> Errors (naive model)
#   2  Variance:   Session factors (grey, unobserved) -> Errors, on a "per
#                  session" baseplate with Instructions: both come in 6s.
#                  Nothing points into Instructions (randomised per session)
#   3  (unused: Participant traits moved to 13)
#   4  Variance:   Errors split into build 1 / build 2 (explains sequence A,
#                  each session against itself)
#   5  Causal:     Collider through Session factors: conditioning on build-1
#                  errors opens the red path. This slide is the hand-off to
#                  Stef's talk (Matt, 2026-10-08)
#   6-7 (unused: the U1/U2 extension and its collapse were removed)
# Every element must map to a variance idea the talk discusses; the DAG is
# a vehicle for those ideas, not an exhaustive causal map.
#   8  Multilevel: Session factors clicks in as structure (yellow).
#                  Participant traits stays grey: the multilevel case is
#                  made through sessions alone (Matt, 2026-10-08)
#   9  Multilevel: shrinkage figure (separate slide, no DAG change)
#   10 GLM:        a NegBin plate (orange) on top of the Errors brick (Matt,
#                  2026-10-09: distributions are plates on top). Only the
#                  outcome's distribution since 2026-10-18 (Matt): the
#                  Normal/Gaussian plate on Session factors was dropped
#   11 Bayesian:   prior plate (green) on Session factors
#   12 Close:      full build (no new elements)
#   13 Variance:   Participant traits (grey) -> both builds, in the "full"
#                  layout only. Learning and Participant traits appear on one
#                  slide ("The same session, building twice")
#                  and nowhere else (Matt, 2026-10-08): the multilevel case
#                  is made through sessions alone. Numbered after 12 so
#                  `upto` (1:n) never includes it.
#   14 Variance:   Learning (blue) -> build 2, in the "full" layout only, one
#                  click after the split (Matt, 2026-10-09; it used to arrive
#                  with step 4). Numbered after 12 for the same reason.
#   15 GLM:        a Poisson plate on Errors, on slide 30 only, one click
#                  before NegBin replaces it (until = 10; Matt, 2026-10-19).
#   16 GLM:        a Normal plate on Errors, slide 30's first click: the
#                  linear model's distribution, there all along; Poisson
#                  replaces it (until = 15; Matt, 2026-10-19).
#                  Numbered after 12 for the same reason. Pieces shared
#                  with step 10 list both steps (render_pieces).
#   17 Causal:     the collider slide's second hop: Instructions -> Build 1
#                  and Session factors -> Build 1 turn red (step 5 is now
#                  only the box round Build 1 errors; Matt, 2026-10-19).
#   18 Causal:     the third hop: Session factors -> Build 2 and the
#                  Instructions -> Build 2 arc turn red (no note: "no
#                  difference" is the next slide's point). Both fade at
#                  6; numbered after 12 so `upto` never includes them.
# No Greek letters on slides: words only ("spread", not sigma).
#
# Legend (right column): one entry per brick type, named by colour, each
# arriving with the first brick of its colour. Notes beside bricks describe
# study components only (room, experimenter); brick types live in the legend.
#
# Section map: show_map(from, to) stacks one brick per section. The slide
# opens with `from` highlighted; one click moves the highlight to `to`.
#
# Colour meaning (fixed): blue = core variables, red = causal warning,
# yellow = structure, orange = distributional assumptions, green = priors,
# grey dashed = unobserved.
# Slides use words, not Greek letters (Matt, 2026-10-08). Any special
# character goes in as an HTML entity so the file works regardless of R's
# locale.
# ---------------------------------------------------------------------------

# dark = fill at 75% brightness (outline of body and studs);
# text / sub = label and second line inside the brick;
# note = text in this colour on the page (outside notes)
pal <- list(
  blue = c(
    fill = "#1F89BB",
    dark = "#17678C",
    text = "#FFFFFF",
    sub = "#D9EEF8",
    note = "#17678C"
  ),
  yellow = c(
    fill = "#FBB802",
    dark = "#BC8A02",
    text = "#FFFFFF",
    sub = "#FFF3D6",
    note = "#8A6501"
  ),
  # Red (Matt, 2026-10-17): fill #d6442d; dark = fill at 75% brightness,
  # sub = same hue and saturation at 89% lightness, as the other colours.
  # Was #D11D00 / #9D1600 / #F8D3CC.
  red = c(
    fill = "#D6442D",
    dark = "#A03322",
    text = "#FFFFFF",
    sub = "#F6D5D0",
    note = "#A03322"
  ),
  # light (Matt, 2026-10-19 late): the normal and transformed models, which
  # were yellow (yellow = random effect); fill's hue and saturation at 68%
  # lightness (fill is 51%). The count model keeps fill, the NegBin brick's.
  orange = c(
    fill = "#F57D0D",
    dark = "#C25E00",
    text = "#FFFFFF",
    sub = "#FFE3C7",
    note = "#C25E00",
    light = "#F9AB62"
  ),
  green = c(
    fill = "#60AC48",
    dark = "#488136",
    text = "#FFFFFF",
    sub = "#DDF0D6",
    note = "#488136"
  ),
  grey = c(
    fill = "#A6A6A6",
    dark = "#646464",
    text = "#2B2B2B",
    sub = "#4A4A4A",
    note = "#646464"
  )
)
# Neutral ink (Matt, 2026-10-09): text, notes, arrows and figure lines that
# used to be grey are the palette's dark blue. Grey that carries meaning stays
# grey: unobserved bricks, the format plates, the "per session" baseplate.
note_col <- pal$blue[["dark"]]
edge_col <- c(ink = note_col, red = pal$red[["fill"]])
# Page colour (Matt, 2026-10-09): light cream, Matt's lighter shade of the
# cream sampled from figs/title_background.png (#F8E2CE, which turned the
# format tints grey). Painted behind the data figures (their stacked
# images must be opaque), inside hollow markers and around haloed labels.
# Must match --r-background-color in brick_dag.css; the previous page was
# "#FFFFFF". White cards and empty session plates stay white (objects).
# Legacy page_bg <- "#F8E2CE",#fbf3ec
page_bg <- "#fff7f0"
# ---- drawing helpers --------------------------------------------------------

# ty = vertical position of the label as a fraction of h
# stud_w = stud width as a fraction of w; n_studs = 2 (left, right) or 3
# (left, middle, right; the section map and the opening stack); show_studs =
# which of them to draw (a stud covered by a brick above can be left out)
svg_brick <- function(
  x,
  y,
  w,
  h,
  col,
  label,
  sub = NULL,
  unobserved = FALSE,
  size = 30,
  ty = if (is.null(sub)) 0.5 else 0.37,
  stud_w = 0.22,
  stud_h = 10,
  n_studs = 2,
  show_studs = rep(TRUE, n_studs)
) {
  stopifnot(n_studs %in% 2:3, length(show_studs) == n_studs)
  p <- pal[[col]]
  sw <- stud_w * w # stud width
  sh <- stud_h # stud height
  op <- if (unobserved) ' fill-opacity="0.55"' else ""
  da <- if (unobserved) ' stroke-dasharray="6 4"' else ""
  stud_x <- c(
    x + 0.16 * w,
    if (n_studs == 3) x + (w - sw) / 2,
    x + w - 0.16 * w - sw
  )
  studs <- sprintf(
    '<rect x="%.1f" y="%.1f" width="%.1f" height="%d" rx="2" fill="%s" stroke="%s" stroke-width="1"%s/>',
    stud_x[show_studs],
    y - sh + 1,
    sw,
    sh,
    p[["fill"]],
    p[["dark"]],
    op
  )
  body <- sprintf(
    '<rect class="brick-body" x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="4" fill="%s" stroke="%s" stroke-width="1.5"%s%s/>',
    x,
    y,
    w,
    h,
    p[["fill"]],
    p[["dark"]],
    op,
    da
  )
  txt <- sprintf(
    '<text x="%.1f" y="%.1f" text-anchor="middle" dominant-baseline="central" font-size="%d" font-weight="600" fill="%s">%s</text>',
    x + w / 2,
    y + h * ty,
    size,
    p[["text"]],
    label
  )
  if (!is.null(sub)) {
    txt <- c(
      txt,
      sprintf(
        '<text x="%.1f" y="%.1f" text-anchor="middle" dominant-baseline="central" font-size="%d" fill="%s">%s</text>',
        x + w / 2,
        y + h * 0.72,
        round(size * 0.7),
        p[["sub"]],
        sub
      )
    )
  }
  c(studs, body, txt)
}

# Plain text outside a brick (level details, counts, model role)
svg_note <- function(
  x,
  y,
  label,
  anchor = "middle",
  col = note_col,
  size = 24
) {
  sprintf(
    '<text x="%.1f" y="%.1f" text-anchor="%s" dominant-baseline="central" font-size="%d" fill="%s">%s</text>',
    x,
    y,
    anchor,
    size,
    col,
    label
  )
}

# d = SVG path data; arrows always end with an arrowhead
svg_edge <- function(d, col = "ink", dashed = FALSE, width = 3) {
  sprintf(
    '<path class="edge" d="%s" fill="none" stroke="%s" stroke-width="%.1f" stroke-linecap="round" stroke-linejoin="round"%s marker-end="url(#ah-%s)"/>',
    d,
    edge_col[[col]],
    width,
    if (dashed) ' stroke-dasharray="8 6"' else "",
    col
  )
}

# Small tag inside a brick (was the NegBin likelihood; unused since the
# NegBin plates, 2026-10-09)
svg_tag <- function(x, y, w, h, col, label, size = 20) {
  p <- pal[[col]]
  c(
    sprintf(
      '<rect class="brick-body" x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="3" fill="%s" stroke="%s" stroke-width="1"/>',
      x,
      y,
      w,
      h,
      p[["fill"]],
      p[["dark"]]
    ),
    sprintf(
      '<text x="%.1f" y="%.1f" text-anchor="middle" dominant-baseline="central" font-size="%d" font-weight="600" fill="%s">%s</text>',
      x + w / 2,
      y + h / 2,
      size,
      p[["text"]],
      label
    )
  )
}

# Flat translucent plate behind bricks that vary at the same level (the brick
# version of a DAG plate), with its label along the bottom edge
svg_baseplate <- function(x, y, w, h, label, size = 22) {
  p <- pal[["grey"]]
  c(
    sprintf(
      '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="8" fill="%s" fill-opacity="0.25" stroke="%s" stroke-width="1.5"/>',
      x,
      y,
      w,
      h,
      p[["fill"]],
      p[["dark"]]
    ),
    sprintf(
      '<text x="%.1f" y="%.1f" text-anchor="middle" dominant-baseline="central" font-size="%d" font-weight="600" fill="%s">%s</text>',
      x + w / 2,
      y + h - 18,
      size,
      note_col,
      label
    )
  )
}

# quiet = a redrawn piece that is not news (an arrow shortened to make room
# for a plate): it arrives dimmed, not highlighted (brick_dag.css)
el <- function(step, svg, until = NA, lit = integer(), quiet = FALSE) {
  list(
    step = step,
    until = until,
    lit = lit,
    quiet = quiet,
    svg = paste(svg, collapse = "\n")
  )
}

# One legend row: a small brick in the type's colour, then its name.
# row = position from the top (rows keep their slot, so the legend grows
# downwards as types arrive)
legend_x <- 1125
legend_y0 <- 200
legend_dy <- 50
svg_legend_item <- function(row, col, label, unobserved = FALSE) {
  y <- legend_y0 + (row - 1) * legend_dy
  c(
    svg_brick(
      legend_x,
      y,
      44,
      26,
      col,
      "",
      unobserved = unobserved,
      stud_h = 7
    ),
    svg_note(legend_x + 56, y + 13, label, anchor = "start", size = 22)
  )
}

# ---- layouts (viewBox 1370 x 590) ------------------------------------------
# The DAG keeps x 0-1150; the legend column sits at x 1125-1370.
# Two layouts share one structure; only the row heights change (Matt,
# 2026-10-08):
#   main = every DAG slide but one. No bottom row, so the two rows spread
#          over the full height and use all the space.
#   full = "The same session, building twice" (the build split), the only slide
#          with Learning and Participant traits. Rows move up to make room
#          for them on the bottom row.
#   centre = the hook slide (step 1 only): the middle row centred
#          vertically (Matt, 2026-10-09). No jump to worry about: the
#          sequence B figure sits between it and the step-2 slide.
# top = y of Session factors; mid = y of Instructions / Errors / builds;
# bot = y of the bottom row (NA = none). In main, top is 116 (was 82): the
# plate and prior stack above Session factors (y 48-116) and the baseplate
# grows to hold them (Matt, 2026-10-09), up to y 22. full and centre never
# show the plates, so they keep 82.
dag_layouts <- list(
  main = list(top = 116, mid = 420, bot = NA),
  full = list(top = 82, mid = 240, bot = 490),
  centre = list(top = 82, mid = 240, bot = NA)
)

# Main bricks h = 88; x is fixed, y comes from the layout.
#   Baseplate        x  14  y top-26 to mid+160, behind Session factors and
#                    Instructions ("per session": both come in 6s)
#   Session factors  x  30  w 240  y top  note below; arrows from mid-right
#   Instructions     x  30  w 240  y mid  note below
#   Errors           x 645  w 220  y mid  steps 1-2, and again from 6, note below
#   Build 1          x 420  w 250  y mid
#   Build 2          x 835  w 250  y mid
#   Participant      x 520  w 300  y bot  note left (x 506); full only
#   Learning         x 870  w 190  y bot  full only
# Plates (h 34; w 172, just covering the studs below) stack on Session
# factors: the prior (11; the Normal/Gaussian plate at 10 was dropped
# 2026-10-18, so the space above is spare). Session factors -> Build 1
# crosses Instructions -> Build 2 once: unavoidable with both causes in the
# left column, so it crosses at a clear angle.
# The step-4 arrows from Session factors assume step 2 is already shown.
dag_elements <- function(L) {
  top <- L$top
  mid <- L$mid
  bot <- L$bot
  # Arrow paths used twice (grey, then red on the collider). Session
  # factors' arrows all leave from the middle of its right edge (y top + 44;
  # Matt, 2026-10-09), so its note sits below the brick.
  instr_b1 <- sprintf("M 272 %g L 412 %g", mid + 44, mid + 44)
  sf_b1 <- sprintf("M 276 %g L 412 %g", top + 44, mid + 10)
  sf_b2 <- sprintf(
    "M 276 %g C 560 %g, 965 %g, 965 %g",
    top + 44,
    top - 50,
    top - 82,
    mid - 16
  )
  instr_b2 <- sprintf(
    "M 272 %g C 330 %g, 760 %g, 853 %g",
    mid + 22,
    mid - 90,
    mid - 90,
    mid - 10
  )
  # Session factors -> Errors (steps 2 and 6); from step 10 the NegBin plate
  # sits on Errors' top, where it lands: the same curve, stopping above the
  # plate's studs
  sf_err <- function(end) {
    sprintf(
      "M 276 %g C 450 %g, 650 %g, 668 %g",
      top + 44,
      top + 44,
      (top + mid) / 2,
      end
    )
  }

  els <- list(
    # -- legend: each type arrives with the first brick of its colour ---------
    # lit at 13: the legend names Participant traits (grey) as it arrives
    el(1, svg_legend_item(1, "blue", "Observed")),
    el(
      2,
      svg_legend_item(2, "grey", "Unobserved", unobserved = TRUE),
      lit = 13
    ),
    # "Random effect" (Matt, 2026-10-18), matching slide 23's title; was
    # "Session level" (17 Oct, Neil: jargon), before that "Random intercept"
    el(8, svg_legend_item(3, "yellow", "Random effect")),
    # With the first orange plate: Normal (16) on slide 30, else NegBin (10)
    el(c(10, 15, 16), svg_legend_item(4, "orange", "Distribution")),
    el(11, svg_legend_item(5, "green", "Prior")),

    # -- baseplate first (drawn behind the bricks that sit on it) -------------
    el(
      2,
      # top edge 26 above Session factors (was 12) so its studs have room
      svg_baseplate(14, top - 26, 272, mid + 186 - top, "per session"),
      until = 11,
      lit = c(17, 18)
    ),
    # The baseplate grows upward when the prior plate stacks on Session
    # factors, so it sits on it too (Matt, 2026-10-09): its top edge stays
    # 17 above the highest studs. The bottom edge stays put. Quiet: redrawn,
    # not news. (Until 2026-10-18 it grew twice: the Normal/Gaussian plate
    # at 10, then the prior.)
    el(
      11,
      svg_baseplate(14, top - 60, 272, mid + 220 - top, "per session"),
      quiet = TRUE
    ),

    # -- arrows (drawn underneath bricks) -------------------------------------
    el(
      1,
      svg_edge(sprintf("M 272 %g L 637 %g", mid + 44, mid + 44)),
      until = 4
    ), # Instr -> Errors
    el(2, svg_edge(sf_err(mid - 10)), until = 4), # SF -> Errors
    # The split into two builds (4) lasts only through the collider, the
    # hand-off to Stef's talk (Matt, 2026-10-18: "the point was the change
    # in errors per format, not per build"); at 6 the DAG is back to one
    # Errors brick for Sections 2-4
    el(4, svg_edge(instr_b1), until = 6), # Instr -> B1
    el(4, svg_edge(instr_b2), until = 6), # Instr -> B2
    el(4, svg_edge(sf_b1), until = 6), # SF -> B1
    el(4, svg_edge(sf_b2), until = 6), # SF -> B2
    # Back to one Errors brick (6)
    el(6, svg_edge(sprintf("M 272 %g L 637 %g", mid + 44, mid + 44))), # Instr -> Errors
    el(6, svg_edge(sf_err(mid - 10)), until = c(10, 15, 16)), # SF -> Errors
    # SF -> Errors, onto its plate (Normal 16, Poisson 15 or NegBin 10)
    el(c(10, 15, 16), svg_edge(sf_err(mid - 46)), quiet = TRUE),

    # -- bricks ---------------------------------------------------------------
    # lit: Instructions stays readable when Session factors joins its
    # baseplate (2), and with the other bricks on the collider path as its
    # arrows turn red (17, 18); at the box (5) only Build 1 errors is lit
    el(
      1,
      c(
        svg_brick(30, mid, 240, 88, "blue", "Instructions"),
        svg_note(150, mid + 114, "picture vs text")
      ),
      lit = c(2, 17, 18)
    ),
    el(
      1,
      c(
        svg_brick(645, mid, 220, 88, "blue", "Errors"),
        svg_note(755, mid + 114, "per build") # below, level with Instructions' note
      ),
      until = 4
    ),
    el(
      2,
      c(
        svg_brick(
          30,
          top,
          240,
          88,
          "grey",
          "Session",
          unobserved = TRUE
        ),
        svg_note(150, top + 114, "room, experimenter")
      ),
      until = 8,
      lit = c(17, 18)
    ),
    el(
      4,
      svg_brick(420, mid, 250, 88, "blue", "Build 1 errors"),
      until = 6,
      lit = c(5, 17, 18)
    ),
    el(
      4,
      svg_brick(835, mid, 250, 88, "blue", "Build 2 errors"),
      until = 6,
      lit = 18
    ),
    # One Errors brick again from 6 (as at step 1), replaced by a copy
    # without studs under the first orange plate (Normal 16, Poisson 15 or
    # NegBin 10)
    el(
      6,
      c(
        svg_brick(645, mid, 220, 88, "blue", "Errors"),
        svg_note(755, mid + 114, "per build")
      ),
      until = c(10, 15, 16)
    ),

    # -- steps 5, 17, 18: collider through session factors (fade at 6) -------
    # One hop per click (Matt, 2026-10-19: show that the collider pushes back
    # through session factors into build 2): 5 the box (adding build-1
    # errors to the model); 17 the two arrows into it; 18 Session factors ->
    # Build 2 and the Instructions -> Build 2 arc, the answer the open path
    # damages (the answer, not the builders' errors; Matt chose the arc
    # over a red Build 2 brick). No note on the arc: "no difference" comes
    # on the next slide (Matt, 2026-10-19). Each later click keeps the earlier red lit,
    # so click 18 shows the whole route. 17 and 18 are numbered after 12 so
    # `upto` never includes them.
    el(
      5,
      sprintf(
        '<rect x="407" y="%g" width="276" height="122" rx="10" fill="none" stroke="%s" stroke-width="4"/>',
        mid - 20,
        edge_col[["red"]]
      ),
      until = 6,
      lit = c(17, 18)
    ),
    el(
      17,
      c(
        svg_edge(instr_b1, col = "red", width = 5),
        svg_edge(sf_b1, col = "red", width = 5)
      ),
      until = 6,
      lit = 18
    ),
    el(
      18,
      c(
        svg_edge(sf_b2, col = "red", width = 5),
        svg_edge(instr_b2, col = "red", width = 5)
      ),
      until = 6
    ),

    # -- step 8: structure clicks in -------------------------------------------
    # The yellow brick replaces the grey one (which leaves at 8) and repeats
    # its note; the legend names it a random intercept. Its studs are a
    # separate element that leaves when the prior plate covers them (11):
    # left under the plate, they would show through it once the plate dims.
    # [1:2] = the two stud rects.
    el(8, svg_brick(30, top, 240, 88, "yellow", "")[1:2], until = 11),
    el(
      8,
      c(
        svg_brick(
          30,
          top,
          240,
          88,
          "yellow",
          "Session",
          show_studs = c(FALSE, FALSE)
        ),
        svg_note(150, top + 114, "room, experimenter")
      )
    ),

    # -- step 10: the outcome's distribution -----------------------------------
    # A distribution is an orange plate on top of its brick (Matt's
    # Scratchpad, 2026-10-09: NegBin "should be plates on top, not inside"):
    # NegBin on the Errors brick (w 180, covering the studs below; one brick
    # since 2026-10-18, was one plate on each build). The blue Errors brick
    # is replaced by a copy without studs, which would show through a dimmed
    # plate. Only the outcome's distribution (Matt, 2026-10-18: "we are just
    # focusing on the DV distribution"): the Normal/Gaussian plate on Session
    # factors is gone.
    # Steps 16 and 15 (slide 30 only; Matt, 2026-10-19): first a
    # "Transform" plate (was "Normal": the transformed model of slide 29,
    # a normal model on transformed errors); then Poisson, the simplest
    # count model, in its place ("Instead of transforming our
    # distribution..."); then NegBin at 10, for counts more variable than
    # that. Numbered after 12 so `upto` never includes them. The stud-less
    # Errors brick is its own piece, arriving with whichever plate comes
    # first, so it doesn't flicker at the swaps.
    el(
      16,
      svg_brick(665, mid - 34, 180, 34, "orange", "Transform", size = 19),
      until = 15
    ),
    el(
      c(10, 15, 16),
      c(
        svg_brick(
          645,
          mid,
          220,
          88,
          "blue",
          "Errors",
          show_studs = c(FALSE, FALSE)
        ),
        svg_note(755, mid + 114, "per build")
      )
    ),
    el(
      15,
      svg_brick(665, mid - 34, 180, 34, "orange", "Poisson", size = 19),
      until = 10
    ),
    el(10, svg_brick(665, mid - 34, 180, 34, "orange", "NegBin", size = 19)),

    # -- step 11: prior on the spread between sessions ------------------------
    # Straight on Session factors since the Normal/Gaussian plate went
    # (2026-10-18). Label just "prior" (Matt, 2026-10-19 late; was "prior on
    # spread"): slide 35's title says what it is on, "A prior on how much
    # sessions differ"
    el(
      11,
      svg_brick(64, top - 34, 172, 34, "green", "prior", size = 19)
    )
  )

  # -- bottom row: "full" layout only ------------------------------------------
  # Learning (14, after the split) and Participant traits (13) appear on one
  # slide only. Neither is part of the model built in the talk; the
  # multilevel case is made through sessions alone. Arrows are drawn first so
  # they sit under the bricks.
  if (!is.na(bot)) {
    els <- c(
      list(
        el(13, svg_edge(sprintf("M 540 %g L 540 %g", bot - 8, mid + 96))), # U -> B1
        el(13, svg_edge(sprintf("M 800 %g L 868 %g", bot - 8, mid + 96))), # U -> B2
        el(14, svg_edge(sprintf("M 965 %g L 965 %g", bot - 8, mid + 96))) # Learning -> B2
      ),
      els,
      list(
        el(
          13,
          c(
            svg_brick(
              520,
              bot,
              300,
              88,
              "grey",
              "Participant traits",
              unobserved = TRUE
            ),
            svg_note(506, bot + 44, "skill, attention", anchor = "end")
          )
        ),
        el(14, svg_brick(870, bot, 190, 88, "blue", "Learning"))
      )
    )
  }
  els
}

# ---- renderer -----------------------------------------------------------------

# Arrowhead ids must be unique per diagram: reveal.js sets display: none on
# far-away slides, and a marker defined inside a hidden <svg> does not draw,
# so a shared id loses every arrowhead a few slides after the first diagram.
svg_defs <- function(id) {
  paste0(
    '<defs>',
    sprintf(
      '<marker id="%s-%s" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto-start-reverse"><path d="M1 1 L9 5 L1 9 Z" fill="%s"/></marker>',
      id,
      names(edge_col),
      edge_col
    ) |>
      paste(collapse = ""),
    '</defs>'
  )
}
dag_count <- new.env()
dag_count$n <- 0L

# shown = steps already on screen when the slide opens (any set, in any
# order); upto = n is shorthand for shown = 1:n.
# layout = "main" (every DAG slide but one) or "full" (dag_layouts).
# offset = fragments on the slide before the DAG's first click (render_pieces).
# clicks = the click each `frag` step lands on, where the DAG's clicks have
# gaps for captions; overrides offset. (Slide 30 used it until its two
# caption-only clicks were dropped, 2026-10-19; no slide uses it now.)
brick_dag <- function(
  upto = 0,
  frag = integer(),
  highlight = TRUE,
  shown = seq_len(upto),
  layout = "main",
  offset = 0,
  clicks = seq_along(frag) + offset
) {
  stopifnot(layout %in% names(dag_layouts))
  dag_count$n <- dag_count$n + 1L
  id <- paste0("ah", dag_count$n)
  parts <- render_pieces(
    dag_elements(dag_layouts[[layout]]),
    shown,
    frag,
    clicks = clicks
  )
  parts <- gsub("url(#ah-", paste0("url(#", id, "-"), parts, fixed = TRUE)
  cls <- if (highlight) "brick-dag" else "brick-dag no-highlight"
  paste0(
    '<svg class="',
    cls,
    '" viewBox="0 0 1370 590" xmlns="http://www.w3.org/2000/svg">',
    svg_defs(id),
    paste(parts[!is.na(parts)], collapse = ""),
    '</svg>'
  )
}

# Wraps each element as a piece: static (step in `shown`), arriving or
# leaving with the fragments (`frag`), or left out (NA). Shared by the DAG
# and the design figure. offset shifts every fragment index, for a figure
# whose first click comes after other fragments on its slide.
# `step` and `until` may each list several steps (2026-10-19, for the
# Poisson plate): the piece arrives with the first of its steps on the
# slide and leaves with the first of its untils, so a piece shared by two
# alternative steps (15 Poisson, 10 NegBin) is drawn once and doesn't
# flicker when one gives way to the other.
# clicks = the click each `frag` step lands on (default: one after another,
# after `offset`), so a figure's clicks can leave gaps for captions.
render_pieces <- function(
  elements,
  shown,
  frag,
  offset = 0,
  clicks = seq_along(frag) + offset
) {
  first <- function(steps) min(match(steps, frag), na.rm = TRUE)
  vapply(
    elements,
    function(e) {
      static <- any(e$step %in% shown) && !any(e$until %in% shown)
      appears <- any(e$step %in% frag)
      leaves <- any(!is.na(e$until) & e$until %in% frag)
      if (!static && !appears) {
        return(NA_character_)
      }
      s <- e$svg
      if (appears) {
        s <- sprintf(
          '<g class="fragment" data-fragment-index="%d">%s</g>',
          clicks[first(e$step)],
          s
        )
      }
      if (leaves) {
        s <- sprintf(
          '<g class="fragment fade-out" data-fragment-index="%d">%s</g>',
          clicks[first(e$until)],
          s
        )
      }
      # An empty fragment marks this piece as current (so not dimmed) at each
      # lit step where the element is already on screen
      on_at <- function(k) {
        i <- match(k, frag)
        (static || first(e$step) < i) &&
          !(leaves && first(e$until) <= i)
      }
      lit <- Filter(on_at, e$lit[e$lit %in% frag])
      marks <- sprintf(
        '<g class="fragment" data-fragment-index="%d"></g>',
        clicks[match(lit, frag)]
      )
      sprintf(
        '<g class="piece%s">%s%s</g>',
        if (isTRUE(e$quiet)) " quiet" else "",
        s,
        paste(marks, collapse = "")
      )
    },
    character(1)
  )
}

# Use in a chunk with `#| output: asis`
show_dag <- function(
  upto = 0,
  frag = integer(),
  highlight = TRUE,
  shown = seq_len(upto),
  layout = "main",
  offset = 0,
  clicks = seq_along(frag) + offset
) {
  cat(
    "```{=html}\n",
    brick_dag(upto, frag, highlight, shown, layout, clicks = clicks),
    "\n```\n",
    sep = ""
  )
}

# ---- design figure ("The LEGO experiment") -----------------------------------
# The study at a glance, no DAG (Matt, 2026-10-08). 6 sessions (Matt,
# 2026-10-09; was 12) as plates in two rows of three by format; each person
# is a small generic toy figure, each build a small red-on-blue model beside
# it. Session sizes match the simulation (lego_sizes in lego_figs.R: first
# three sessions picture, last three text).
# Steps (numbers are names): 1 sessions (empty white plates); 2 people
# (figures); 3 format (plates take their format's colour and a manual
# appears beside each row; the white plates leave); 4 builds (two beside
# each figure). The slide shows them in the order 1, 3, 2, 4 (Matt,
# 2026-10-09: the sessions split into two sets before people arrive).
# viewBox 1200 x 510.
# Figures per plate: a visual, not a count (Matt, 2026-10-08). The
# simulation's session sizes divided by 2.7 and rounded, keeping their order
# (4 -> 1, 6 -> 2, 10 -> 4, 14 -> 5, 16 -> 6), so small and large sessions
# sit where the simulation has them: picture c(4, 16, 10), text c(14, 6, 10).
session_sizes <- list(
  picture = c(1, 6, 4),
  text = c(5, 2, 4)
)
# The formats' colours (Matt, 2026-10-09; were two greys): picture = the
# palette's dark blue, text = its dark green (the CSS's .slogan-sm-b / -g).
# Large fills (plates, curves) use them as a tint (fill-opacity).
format_col <- c(picture = pal$blue[["dark"]], text = pal$green[["dark"]])

# The same instruction in each format: put the red brick on the blue one.
# w 140, h 180; band = cover strip in the format's colour, name in white.
svg_manual <- function(x, y, format) {
  w <- 140
  h <- 180
  page <- c(
    sprintf(
      '<rect x="%g" y="%g" width="%g" height="%g" rx="6" fill="#FFFFFF" stroke="%s" stroke-width="2"/>',
      x,
      y,
      w,
      h,
      pal$grey[["dark"]]
    ),
    # Cover band: top corners follow the page's rounded corners (rx 6)
    sprintf(
      '<path d="M %g %g a 6 6 0 0 1 6 -6 h %g a 6 6 0 0 1 6 6 v 28 h %g Z" fill="%s" stroke="%s" stroke-width="2"/>',
      x,
      y + 6,
      w - 12,
      -w,
      format_col[[format]],
      format_col[[format]]
    ),
    # The format's name on the band (replaces a caption; Matt, 2026-10-08)
    svg_note(
      x + w / 2,
      y + 18,
      sprintf(
        '<tspan font-weight="700">%s</tspan>',
        c(picture = "Picture", text = "Text")[[format]]
      ),
      col = "#FFFFFF",
      size = 20
    )
  )
  content <- if (format == "picture") {
    c(
      svg_note(x + 22, y + 66, "1", size = 28, col = note_col),
      svg_brick(x + 52, y + 54, 64, 26, "red", "", stud_h = 6),
      sprintf(
        '<path d="M %g %g L %g %g" stroke="%s" stroke-width="3"/><path d="M %g %g l -8 -10 h 16 Z" fill="%s"/>',
        x + 84,
        y + 86,
        x + 84,
        y + 100,
        note_col,
        x + 84,
        y + 110,
        note_col
      ),
      svg_brick(x + 52, y + 122, 64, 26, "blue", "", stud_h = 6)
    )
  } else {
    lines <- c("Put the red", "brick on top", "of the blue", "brick.")
    c(
      svg_note(
        x + 14,
        y + 60,
        '<tspan font-weight="700">Step 1:</tspan>',
        anchor = "start",
        size = 18
      ),
      svg_note(
        x + 14,
        y + 86 + 24 * (seq_along(lines) - 1),
        lines,
        anchor = "start",
        size = 18
      )
    )
  }
  c(page, content)
}

# A generic toy figure (one person), feet at (cx, base), about 20 x 44 at
# s = 1: yellow head with a stud, blue body and arms, grey legs, simple face.
# s scales it about the feet.
svg_figure <- function(cx, base, s = 1) {
  y <- pal$yellow
  b <- pal$blue
  g <- pal$grey
  fig <- sprintf(
    paste0(
      # legs and hips
      '<rect x="%1$g" y="%2$g" width="6" height="12" fill="%7$s" stroke="%8$s" stroke-width="0.8"/>',
      '<rect x="%3$g" y="%2$g" width="6" height="12" fill="%7$s" stroke="%8$s" stroke-width="0.8"/>',
      '<rect x="%4$g" y="%5$g" width="16" height="4" fill="%7$s" stroke="%8$s" stroke-width="0.8"/>',
      # arms, then body
      '<rect x="%6$g" y="%9$g" width="4" height="11" rx="1.5" fill="%10$s" stroke="%11$s" stroke-width="0.8"/>',
      '<rect x="%12$g" y="%9$g" width="4" height="11" rx="1.5" fill="%10$s" stroke="%11$s" stroke-width="0.8"/>',
      '<path d="M %13$g %9$g h 12 l 2 14 h -16 Z" fill="%10$s" stroke="%11$s" stroke-width="0.8"/>',
      # head with stud, eyes and smile
      '<rect x="%14$g" y="%15$g" width="6" height="3" rx="1" fill="%16$s" stroke="%17$s" stroke-width="0.8"/>',
      '<rect x="%18$g" y="%19$g" width="11" height="10" rx="3" fill="%16$s" stroke="%17$s" stroke-width="0.8"/>',
      '<circle cx="%20$g" cy="%21$g" r="0.9" fill="%22$s"/>',
      '<circle cx="%23$g" cy="%21$g" r="0.9" fill="%22$s"/>',
      '<path d="M %20$g %24$g q 2.2 1.8 4.4 0" fill="none" stroke="%22$s" stroke-width="0.8"/>'
    ),
    cx - 7, # 1 left leg x
    base - 12, # 2 leg y
    cx + 1, # 3 right leg x
    cx - 8, # 4 hips x
    base - 16, # 5 hips y
    cx - 10, # 6 left arm x
    g[["dark"]], # 7 legs fill
    g[["sub"]], # 8 legs outline
    base - 30, # 9 shoulders y
    b[["fill"]], # 10 body fill
    b[["dark"]], # 11 body outline
    cx + 6, # 12 right arm x
    cx - 6, # 13 body top-left x
    cx - 3, # 14 stud x
    base - 44, # 15 stud y
    y[["fill"]], # 16 head fill
    y[["dark"]], # 17 head outline
    cx - 5.5, # 18 head x
    base - 41, # 19 head y
    cx - 2.2, # 20 left eye / smile start x
    base - 37.5, # 21 eye y
    pal$grey[["text"]], # 22 face colour
    cx + 2.2, # 23 right eye x
    base - 34.5 # 24 smile y
  )
  if (s == 1) {
    return(fig)
  }
  sprintf(
    '<g transform="translate(%g %g) scale(%g) translate(%g %g)">%s</g>',
    cx,
    base,
    s,
    -cx,
    -base,
    fig
  )
}

# One build: the manuals' instruction done, a small red brick on a wider
# blue one (10 x 9), top-left at (x, y)
svg_build <- function(x, y) {
  sprintf(
    paste0(
      '<rect x="%g" y="%g" width="10" height="5" fill="%s" stroke="%s" stroke-width="0.8"/>',
      '<rect x="%g" y="%g" width="8" height="4" fill="%s" stroke="%s" stroke-width="0.8"/>'
    ),
    x,
    y + 4,
    pal$blue[["fill"]],
    pal$blue[["dark"]],
    x + 1,
    y,
    pal$red[["fill"]],
    pal$red[["dark"]]
  )
}

# One session plate; fill = "#FFFFFF" before the format is assigned
# A format's plate is a tint of its colour (fill_opacity) with a full-colour
# outline (stroke)
svg_plate <- function(
  x,
  y,
  w,
  h,
  fill,
  fill_opacity = 1,
  stroke = pal$grey[["dark"]]
) {
  sprintf(
    '<rect x="%g" y="%g" width="%g" height="%g" rx="8" fill="%s" fill-opacity="%g" stroke="%s" stroke-width="2"/>',
    x,
    y,
    w,
    h,
    fill,
    fill_opacity,
    stroke
  )
}

design_elements <- function() {
  plate_w <- 330 # three plates a row, up to six figures each
  plate_h <- 138
  row_y <- c(picture = 70, text = 330)
  plate_x <- 175 + (0:2) * 340
  # One person = a figure with its two builds beside it, drawn at unit size
  # (38 wide, 44 tall, feet at 0) and scaled by s; 6 fit across a plate
  s <- 1.35
  cell <- 38 * s
  # Drawn in this order: plates under people; manuals beside the rows
  plates <- list()
  people <- list()
  manuals <- list()
  for (f in names(session_sizes)) {
    y0 <- row_y[[f]]
    for (i in seq_along(session_sizes[[f]])) {
      x0 <- plate_x[i]
      n <- session_sizes[[f]][i]
      plates <- c(
        plates,
        list(
          el(1, svg_plate(x0, y0, plate_w, plate_h, "#FFFFFF"), until = 3),
          el(
            3,
            svg_plate(
              x0,
              y0,
              plate_w,
              plate_h,
              format_col[[f]],
              fill_opacity = 0.18,
              stroke = format_col[[f]]
            )
          )
        )
      )
      # People in one row, centred on the plate. Builds: two, one above the
      # other with a clear gap, beside the figure's legs.
      base <- y0 + plate_h / 2 + 22 * s
      xs <- x0 + (plate_w - n * cell) / 2 + (0:(n - 1)) * cell
      at <- function(x, svg) {
        sprintf(
          '<g transform="translate(%g %g) scale(%g)">%s</g>',
          x,
          base,
          s,
          paste(svg, collapse = "")
        )
      }
      figs <- vapply(xs, function(x) at(x, svg_figure(13, 0)), "")
      builds <- vapply(
        xs,
        function(x) at(x, c(svg_build(26, -9), svg_build(26, -23))),
        ""
      )
      people <- c(people, list(el(2, figs), el(4, builds)))
    }
    # Manual beside its row, centred on the plates
    manuals <- c(
      manuals,
      list(el(3, svg_manual(0, y0 + plate_h / 2 - 90, f)))
    )
  }
  c(plates, people, manuals)
}

# The design figure with its fragments; no dimming (pieces accumulate).
# Use in a chunk with `#| output: asis`.
show_design <- function(shown = integer(), frag = 1:4) {
  parts <- render_pieces(design_elements(), shown, frag)
  cat(
    "```{=html}\n",
    '<svg class="brick-dag no-highlight brick-design" viewBox="0 0 1200 510" xmlns="http://www.w3.org/2000/svg">',
    paste(parts[!is.na(parts)], collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- what a random effect does (Section 2, before the random-effect DAG) ------
# Slide 23 (Matt, 2026-10-20; replaces the 19 Oct "allows for / assumes"
# explainer: its confounding half, "if text went to the quieter rooms", and
# the dice are gone). Matt's point: normally the format difference must
# stand out from how much people differ, and more people average that out;
# here people come in sessions, sessions differ and format was given by
# session, so the session is the unit and the difference must stand out
# from how much sessions differ; more people per session barely helps, only
# more sessions average that out. Drawn by hand (the general case), in
# slide 25's look: a tinted panel per format, dashed format averages, the
# gap between them an ink bar; each build is the design figure's build icon
# (svg_build). Up = more errors; no numbers. viewBox 1200 x 440.
#   opens    left half, "Format given to each person": builds scattered,
#            no sessions; the format averages and the gap
#   frag     right half, "Format given to each session": the same panels
#            and gap, builds in a yellow band per session (session =
#            yellow), the bands at different heights
#   (the captions, clicks 1, 3 and 4, are in the qmd)
# Only the unit format was given to differs between the halves: the same
# gap, the same number of builds per format (13, 14), about the same overall
# scatter. Points never move: each half's builds sit in place from its
# first image.
# Exaggerated (Matt, 2026-10-19 late): sessions drawn far apart, builds in a
# session close together. In the simulation (lego_figs.R) sessions differ
# about as much as builds within a session do (session 2, person 2, leftover
# 1; format effect 1). Positions are in format-effect units (u px), mean 0
# within each format, so each half's gap is the format's real effect.
rooms_geom <- list(u = 46, base = 178, top = 50, h = 340)
# Right half: one row per session (push = up from its format's average;
# n = builds drawn, a visual)
rooms_set <- data.frame(
  push = c(2.0, -1.6, -0.4, 1.6, -2.0, 0.4),
  n = c(3, 6, 4, 5, 2, 7),
  format = c("picture", "picture", "picture", "text", "text", "text")
)
# Left half: one build per person, placed by hand (fx = share of the
# panel's width; push as above, made mean 0 in rooms_half)
rooms_people <- data.frame(
  fx = c(
    c(0.15, 0.55, 0.80, 0.30, 0.65, 0.15, 0.45, 0.85, 0.25, 0.60, 0.80, 0.35, 0.55),
    c(0.20, 0.70, 0.45, 0.85, 0.15, 0.60, 0.35, 0.80, 0.20, 0.55, 0.85, 0.30, 0.65, 0.45)
  ),
  push = c(
    c(2.4, 2.1, 1.5, 1.2, 0.7, 0.3, 0.0, -0.2, -0.7, -1.0, -1.5, -1.8, -2.4),
    c(2.2, 1.9, 1.4, 0.9, 0.6, 0.2, -0.1, -0.5, -0.9, -1.2, -1.6, -1.9, -2.2, -2.6)
  ),
  format = rep(c("picture", "text"), c(13, 14))
)

# A white LEGO die (a 2x2 brick with pips on its face), centred on cx.
# Unused since 2026-10-20 (slide 23's dice cut with its confounding half)
svg_die <- function(cx, y, face) {
  w <- 30
  h <- 24
  pip <- list(
    c(0, 0),
    c(-1, -1, 1, 1),
    c(-1, -1, 0, 0, 1, 1),
    c(-1, -1, 1, -1, -1, 1, 1, 1),
    c(-1, -1, 1, -1, 0, 0, -1, 1, 1, 1),
    c(-1, -1, 1, -1, -1, 0, 1, 0, -1, 1, 1, 1)
  )[[face]]
  xy <- matrix(pip, ncol = 2, byrow = TRUE)
  c(
    sprintf(
      '<rect x="%g" y="%g" width="7" height="5" rx="1" fill="#FFFFFF" stroke="%s" stroke-width="1.2"/>',
      cx + c(-11, 4),
      y - 4,
      note_col
    ),
    sprintf(
      '<rect x="%g" y="%g" width="%g" height="%g" rx="4" fill="#FFFFFF" stroke="%s" stroke-width="1.5"/>',
      cx - w / 2,
      y,
      w,
      h,
      note_col
    ),
    sprintf(
      '<circle cx="%g" cy="%g" r="2.3" fill="%s"/>',
      cx + 8 * xy[, 1],
      y + h / 2 + 6.5 * xy[, 2],
      note_col
    )
  )
}

# One half of the figure: two format panels from x0, format given to each
# "person" (left) or each "session" (right). Returns its pieces by role.
rooms_half <- function(x0, unit) {
  g <- rooms_geom
  pw <- 235 # panel width; the gap between the panels holds the bar
  gap <- 50
  px <- c(picture = x0, text = x0 + pw + gap)
  bar_x <- x0 + pw + gap / 2
  # Height on the page: text sits one format effect lower (fewer errors)
  up <- function(push, fmt) g$base - (push - (fmt == "text")) * g$u
  bands <- character()
  if (unit == "person") {
    s <- rooms_people
    bx <- px[s$format] + 15 + (pw - 30) * s$fx
    by <- up(s$push - ave(s$push, s$format), s$format)
    avg <- tapply(by, s$format, mean)
  } else {
    s <- rooms_set
    # Column order in each panel: the sessions in the order listed
    slot <- ave(seq_along(s$format), s$format, FUN = seq_along)
    cx <- px[s$format] + pw * (2 * slot - 1) / 6
    cy <- up(s$push, s$format)
    bx <- by <- numeric()
    for (i in seq_len(nrow(s))) {
      k <- seq_len(s$n[i]) - 1
      y <- cy[i] + (k - (s$n[i] - 1) / 2) * 10
      bx <- c(bx, cx[i] + ifelse(k %% 2 == 0, -11, 11))
      by <- c(by, y)
      bands <- c(
        bands,
        sprintf(
          '<rect x="%.1f" y="%.1f" width="54" height="%.1f" rx="12" fill="%s" fill-opacity="0.28" stroke="%s" stroke-width="2"/>',
          cx[i] - 27,
          min(y) - 15,
          max(y) - min(y) + 30,
          pal$yellow[["fill"]],
          pal$yellow[["fill"]]
        )
      )
    }
    avg <- tapply(cy, s$format, mean)
  }
  builds <- sprintf(
    '<g transform="translate(%.1f %.1f) scale(1.8)">%s</g>',
    bx - 9,
    by - 8,
    svg_build(0, 0)
  )
  panels <- unlist(lapply(c("picture", "text"), function(f) {
    c(
      svg_plate(
        px[[f]],
        g$top,
        pw,
        g$h,
        format_col[[f]],
        fill_opacity = 0.12,
        stroke = format_col[[f]]
      ),
      svg_note(
        px[[f]] + pw / 2,
        g$top + g$h + 26,
        c(picture = "Picture", text = "Text")[[f]],
        col = format_col[[f]],
        size = 26
      )
    )
  }))
  # Format averages run from their panel to the bar between the panels; the
  # bar (the gap) has no end caps: with them the short bar read as a capital
  # I, so the dashed lines meet its ends instead
  lines <- c(
    sprintf(
      '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="3" stroke-dasharray="10 8"/>',
      c(px[["picture"]] + 8, bar_x),
      avg[c("picture", "text")],
      c(bar_x, px[["text"]] + pw - 8),
      avg[c("picture", "text")],
      format_col[c("picture", "text")]
    ),
    sprintf(
      '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="6" stroke-linecap="butt"/>',
      bar_x,
      avg[["picture"]],
      bar_x,
      avg[["text"]],
      note_col
    )
  )
  list(
    panels = panels,
    builds = builds,
    bands = bands,
    lines = lines,
    mid = x0 + pw + gap / 2
  )
}

# frag = the right half's fragment index
rooms_elements <- function(frag = 2) {
  g <- rooms_geom
  l <- rooms_half(55, "person")
  r <- rooms_half(655, "session")
  heading <- function(x, label) {
    sprintf(
      '<g font-weight="700">%s</g>',
      svg_note(x, 22, label, size = 26)
    )
  }
  c(
    sprintf(
      '<text x="24" y="%g" transform="rotate(-90 24 %g)" text-anchor="middle" dominant-baseline="central" font-size="22" fill="%s">more errors &#8594;</text>',
      g$top + g$h / 2,
      g$top + g$h / 2,
      note_col
    ),
    l$panels,
    l$builds,
    l$lines,
    heading(l$mid, "Format given to each person"),
    repeat_frag(
      c(
        r$panels,
        r$bands,
        r$builds,
        r$lines,
        heading(r$mid, "Format given to each session")
      ),
      frag
    )
  )
}

# Use in a chunk with `#| output: asis`.
show_rooms <- function(frag = 2) {
  cat(
    "```{=html}\n",
    '<svg class="brick-dag no-highlight brick-rooms" viewBox="0 0 1200 440" xmlns="http://www.w3.org/2000/svg">',
    paste(rooms_elements(frag), collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- section map ----------------------------------------------------------------
# One brick per section, stacked bottom-up in teaching order (multilevel before
# GLM) as a running bond: each brick is shifted by d against the one below,
# with its edge at the edge of a stud, so it covers two of its three studs
# and leaves one showing beside it. Three studs, and narrower and taller than
# in the DAG, so the exposed ones stand out (Matt, 2026-10-09: map bricks
# only). Covered studs are not drawn (they would show through a dimmed brick
# above). All bricks are full colour; highlighting dims the others. Labels
# are placeholders (Matt's call).
# Four sections (Matt, 2026-10-09): the causal section was folded into the
# first one, now "Building the model", which ends with the collider slide.
map_sections <- list(
  build = c(col = "blue", label = "Building the model"),
  multilevel = c(col = "yellow", label = "Multilevel structure"),
  glm = c(col = "orange", label = "Distributions (GLM)"),
  bayes = c(col = "green", label = "Priors (Bayesian)")
)

# from = section highlighted when the slide opens (the one just covered);
# to   = section highlighted after one click (the next one). NULL = none.
brick_map <- function(from = NULL, to = NULL) {
  keys <- names(map_sections)
  stopifnot(is.null(from) || from %in% keys, is.null(to) || to %in% keys)
  n <- length(keys)
  w <- 600
  h <- 124 # thicker with four bricks (was 96 with five)
  sw <- 0.10
  sh <- 16
  d <- (0.16 + sw) * w # shift = left stud's right edge
  x0 <- (1150 - w - d) / 2
  y0 <- (590 - n * h - sh) / 2 + sh # top brick's body, stack centred
  parts <- vapply(
    seq_along(keys),
    function(i) {
      s <- map_sections[[i]]
      right <- i %% 2 == 0 # odd bricks left, even bricks right
      # The brick above covers the studs on the side it is shifted towards:
      # a left brick keeps its left stud, a right brick its right stud
      show <- if (i == n) {
        c(TRUE, TRUE, TRUE)
      } else if (right) {
        c(FALSE, FALSE, TRUE)
      } else {
        c(TRUE, FALSE, FALSE)
      }
      svg <- svg_brick(
        x0 + right * d,
        y0 + (n - i) * h,
        w,
        h,
        s[["col"]],
        s[["label"]],
        size = 36,
        stud_w = sw,
        stud_h = sh,
        n_studs = 3,
        show_studs = show
      )
      cls <- if (!is.null(from) && keys[i] != from) {
        "piece dim-open"
      } else {
        "piece"
      }
      mark <- if (identical(keys[i], to)) {
        '<g class="fragment" data-fragment-index="1"></g>'
      } else {
        ""
      }
      sprintf('<g class="%s">%s%s</g>', cls, paste(svg, collapse = "\n"), mark)
    },
    character(1)
  )
  paste0(
    '<svg class="brick-dag brick-map" viewBox="0 0 1150 590" xmlns="http://www.w3.org/2000/svg">',
    paste(parts, collapse = ""),
    '</svg>'
  )
}

show_map <- function(from = NULL, to = NULL) {
  cat("```{=html}\n", brick_map(from, to), "\n```\n", sep = "")
}

# ---- opening brick stack ------------------------------------------------------------
# Three bricks in the colours of the three methods in the talk's title
# (multilevel yellow, GLM orange, Bayesian green; Matt, 2026-10-09), stacked
# bottom-up as a running bond like the section map, three studs each (Matt,
# 2026-10-09). All studs are drawn: the brick above covers two of the three
# below it, and the top brick's lift-off must reveal them again.
#   mode = "drop": one click (fragment index `frag`) drops the bricks in one
#                  after another, slowly (slide "Build the model your study
#                  actually is").
#   mode = "lift": the stack is built when the slide opens; at fragment
#                  `frag` the top brick lifts off and fades (slide "Every
#                  piece earns its place", with "Complexity").
# The animations live in brick_dag.css (.brick-stack). viewBox 520 x 300.
stack_cols <- c("yellow", "orange", "green") # bottom to top

brick_stack <- function(mode = c("drop", "lift"), frag = 1) {
  mode <- match.arg(mode)
  w <- 300
  h <- 80
  sw <- 0.10
  d <- (0.16 + sw) * w # shift = left stud's right edge, as in the map
  x0 <- (520 - w - d) / 2
  bricks <- vapply(
    seq_along(stack_cols),
    function(i) {
      svg <- svg_brick(
        x0 + (i %% 2 == 0) * d,
        300 - i * h - 20,
        w,
        h,
        stack_cols[i],
        "",
        stud_w = sw,
        stud_h = 16,
        n_studs = 3
      )
      cls <- sprintf("stack-brick b%d", i)
      if (mode == "lift" && i == length(stack_cols)) {
        cls <- sprintf(
          '%s fragment custom stack-lift" data-fragment-index="%d',
          cls,
          frag
        )
      }
      sprintf('<g class="%s">%s</g>', cls, paste(svg, collapse = ""))
    },
    character(1)
  )
  inner <- paste(bricks, collapse = "")
  if (mode == "drop") {
    inner <- sprintf(
      '<g class="fragment custom stack-drop" data-fragment-index="%d">%s</g>',
      frag,
      inner
    )
  }
  paste0(
    '<svg class="brick-stack" viewBox="0 0 520 300" xmlns="http://www.w3.org/2000/svg">',
    inner,
    "</svg>"
  )
}

show_stack <- function(mode = c("drop", "lift"), frag = 1) {
  cat("```{=html}\n", brick_stack(mode, frag), "\n```\n", sep = "")
}

# ---- about me (slide 2) ---------------------------------------------------------
# Three research areas as LEGO pictures side by side, one per click, a
# caption under each (Matt, 2026-10-19; panels as slide 40's: 340 wide, 60
# apart). Colours from slide 23 (Matt, 2026-10-20): its green panel, yellow
# band, white dice, blue and red bricks, ink lines (nothing on screen has a
# meaning yet). Taller, each picture with its caption as one block, the
# blocks centred on the slide (Matt, 2026-10-20): pictures 360 tall from
# y = 75, captions under them. The SVG starts 53 px down the slide (under
# the title), so the blocks' middle (y 297) sits at the slide's (350); if a
# line is added above the pictures, lower about_geom$top by its height.
#   1 Behavioural analysis: a baseplate seen from above (the arena; slide
#     23's Text panel), a centre zone (its session band), an animal's
#     tracked path (ink) ending at a red brick seen from above.
#   2 Population cycles and genetic inheritance: a cycle (green wave) over a
#     three-generation pedigree of bricks; red bricks carry the trait, white
#     ones (slide 23's dice) don't.
#   3 Functional genomics and transcriptomics: a DNA helix, an arrow, then a
#     gene network: one brick per gene, in each of the colours, ink lines
#     for the links (was brick stacks for expression).
about_lines <- list(
  c("Behavioural analysis", ""),
  c("Population cycles and", "genetic inheritance"),
  c("Functional genomics", "and transcriptomics")
)
about_geom <- list(w = 340, gap = 60, top = 75, h = 360, vb_h = 570)

# A small brick seen from the side, centred at cx, body top at y; col = a
# pal colour (fill, dark outline) or "white" (slide 23's dice: white, ink)
svg_icon_brick <- function(cx, y, col = "blue", w = 48, h = 26) {
  if (col == "white") {
    fill <- "#FFFFFF"
    dark <- note_col
  } else {
    fill <- pal[[col]][["fill"]]
    dark <- pal[[col]][["dark"]]
  }
  sw <- 0.22 * w
  sprintf(
    '<rect x="%.1f" y="%.1f" width="%.1f" height="6" rx="1.5" fill="%s" stroke="%s" stroke-width="1.5"/>',
    c(cx - w / 2 + 0.16 * w, cx + w / 2 - 0.16 * w - sw),
    y - 5,
    sw,
    fill,
    dark
  ) |>
    c(
      sprintf(
        '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="3" fill="%s" stroke="%s" stroke-width="2"/>',
        cx - w / 2,
        y,
        w,
        h,
        fill,
        dark
      )
    )
}

about_elements <- function(frag = 1:3) {
  g <- about_geom
  x0s <- (1200 - 3 * g$w - 2 * g$gap) / 2 + (0:2) * (g$w + g$gap)
  top <- g$top
  bot <- g$top + g$h
  ink <- note_col
  green <- format_col[["text"]]
  under <- function(i) {
    l <- about_lines[[i]]
    l <- l[nzchar(l)]
    svg_note(x0s[i] + g$w / 2, bot + 38 + (seq_along(l) - 1) * 32, l, size = 26)
  }
  line <- function(x1, y1, x2, y2, width = 2.5) {
    sprintf(
      '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="%g" stroke-linecap="round"/>',
      x1,
      y1,
      x2,
      y2,
      ink,
      width
    )
  }
  # 1 behavioural analysis: arena 300 x 360, studs every 30, a centre zone
  x <- x0s[1]
  studs <- expand.grid(
    x = x + 20 + 15 + 30 * (0:9),
    y = top + 15 + 30 * (0:11)
  )
  path <- sprintf(
    "M %g %g C %g %g, %g %g, %g %g S %g %g, %g %g S %g %g, %g %g",
    x + 55,
    405,
    x + 100,
    350,
    x + 40,
    300,
    x + 110,
    270,
    x + 235,
    255,
    x + 200,
    195,
    x + 150,
    125,
    x + 262,
    114
  )
  p1 <- c(
    svg_plate(x + 20, top, 300, g$h, green, fill_opacity = 0.12, stroke = green),
    sprintf(
      '<circle cx="%g" cy="%g" r="8" fill="%s" fill-opacity="0.12" stroke="%s" stroke-opacity="0.45" stroke-width="1.2"/>',
      studs$x,
      studs$y,
      green,
      green
    ),
    sprintf(
      '<rect x="%g" y="165" width="150" height="180" rx="12" fill="%s" fill-opacity="0.28" stroke="%s" stroke-width="2"/>',
      x + 95,
      pal$yellow[["fill"]],
      pal$yellow[["fill"]]
    ),
    sprintf(
      '<path d="%s" fill="none" stroke="%s" stroke-width="4" stroke-linecap="round"/>',
      path,
      ink
    ),
    # the animal: a red brick seen from above, at the path's end
    sprintf(
      '<g transform="translate(%g 110) rotate(-20)"><rect x="-24" y="-15" width="48" height="30" rx="4" fill="%s" stroke="%s" stroke-width="2"/>%s</g>',
      x + 280,
      pal$red[["fill"]],
      pal$red[["dark"]],
      paste(
        sprintf(
          '<circle cx="%d" cy="0" r="7" fill="%s" stroke="%s" stroke-width="1.5"/>',
          c(-11, 11),
          pal$red[["fill"]],
          pal$red[["dark"]]
        ),
        collapse = ""
      )
    ),
    under(1)
  )
  # 2 population cycles over a three-generation pedigree
  x <- x0s[2]
  wx <- seq(x + 20, x + 320, length.out = 121)
  wy <- top + 40 - 22 * sin(2 * pi * 2 * (wx - x - 20) / 300)
  bw <- 54
  bh <- 30
  gens <- c(200, 297, 394) # brick tops
  mid <- function(k) gens[k] + bh / 2
  sib <- function(k) (gens[k] + bh + gens[k + 1] - 5) / 2 # children's line
  bricks <- data.frame(
    cx = x + c(130, 210, 70, 150, 230, 300, 230, 300),
    gen = c(1, 1, 2, 2, 2, 2, 3, 3),
    col = c("red", "white", "white", "red", "red", "white", "red", "white")
  )
  p2 <- c(
    sprintf(
      '<path d="M %s" fill="none" stroke="%s" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>',
      paste(sprintf("%.1f %.1f", wx, wy), collapse = " L "),
      green
    ),
    # couples, then each couple's line down to its children
    line(x + 130 + bw / 2, mid(1), x + 210 - bw / 2, mid(1)),
    line(x + 170, mid(1), x + 170, sib(1)),
    line(x + 70, sib(1), x + 230, sib(1)),
    line(x + c(70, 150, 230), sib(1), x + c(70, 150, 230), gens[2] - 5),
    line(x + 230 + bw / 2, mid(2), x + 300 - bw / 2, mid(2)),
    line(x + 265, mid(2), x + 265, sib(2)),
    line(x + 230, sib(2), x + 300, sib(2)),
    line(x + c(230, 300), sib(2), x + c(230, 300), gens[3] - 5),
    unlist(Map(
      function(cx, k, col) svg_icon_brick(cx, gens[k], col, w = bw, h = bh),
      bricks$cx,
      bricks$gen,
      bricks$col
    )),
    under(2)
  )
  # 3 helix -> arrow -> gene network
  x <- x0s[3]
  hy <- seq(top + 5, bot - 5, length.out = 121)
  ph <- 2 * pi * 2 * (hy - top - 5) / (g$h - 10)
  ry <- seq(top + 5, bot - 5, length.out = 16)[2:15]
  rp <- 2 * pi * 2 * (ry - top - 5) / (g$h - 10)
  strand <- function(sgn, col) {
    sprintf(
      '<path d="M %s" fill="none" stroke="%s" stroke-width="4" stroke-linecap="round"/>',
      paste(sprintf("%.1f %.1f", x + 60 + sgn * 30 * sin(ph), hy), collapse = " L "),
      col
    )
  }
  mid_y <- top + g$h / 2
  genes <- data.frame(
    cx = x + c(210, 300, 245, 190, 300, 245, 305),
    cy = c(105, 150, 205, 300, 265, 360, 410),
    col = c("blue", "yellow", "red", "green", "white", "blue", "red")
  )
  links <- rbind(
    c(1, 2),
    c(1, 3),
    c(2, 3),
    c(2, 5),
    c(3, 4),
    c(3, 5),
    c(4, 6),
    c(5, 6),
    c(5, 7),
    c(6, 7)
  )
  p3 <- c(
    sprintf(
      '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="2" stroke-opacity="0.6"/>',
      x + 60 + 30 * sin(rp),
      ry,
      x + 60 - 30 * sin(rp),
      ry,
      ink
    ),
    strand(1, ink),
    strand(-1, pal$blue[["fill"]]),
    line(x + 102, mid_y, x + 142, mid_y),
    sprintf(
      '<path d="M %g %g L %g %g L %g %g Z" fill="%s"/>',
      x + 140,
      mid_y - 10,
      x + 154,
      mid_y,
      x + 140,
      mid_y + 10,
      ink
    ),
    line(
      genes$cx[links[, 1]],
      genes$cy[links[, 1]],
      genes$cx[links[, 2]],
      genes$cy[links[, 2]]
    ),
    unlist(Map(
      function(cx, cy, col) svg_icon_brick(cx, cy - 14, col, w = 46, h = 28),
      genes$cx,
      genes$cy,
      genes$col
    )),
    under(3)
  )
  c(
    repeat_frag(p1, frag[1]),
    repeat_frag(p2, frag[2]),
    repeat_frag(p3, frag[3])
  )
}

# Use in a chunk with `#| output: asis`.
show_about <- function(frag = 1:3) {
  cat(
    "```{=html}\n",
    sprintf(
      '<svg class="brick-dag no-highlight brick-about" viewBox="0 0 1200 %d" xmlns="http://www.w3.org/2000/svg">',
      about_geom$vb_h
    ),
    paste(about_elements(frag), collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- what can go wrong ----------------------------------------------------------
# The problems each piece fixes, set up front so later sections can point
# back to them (Matt's vault Scratchpad). LEGO form agreed 2026-10-09 (Matt),
# replacing the dartboards in IDEAS section 0. A sketch, not data: rows are
# placed to make each point (Matt, 2026-10-17: "the visuals are there to
# make points, not to be a pure point from a simulation"), and nothing
# carries a number.
# Each column is a wall of repeats: one row = one run of the study. The
# brick sits at that run's answer (its best guess); the plate under it
# (only ever one per brick) spans how far off that guess could be; the
# line is the true answer. Our experiment (row repeat_ours) is the one
# solid row in every column; the other runs never happen, so they are drawn
# like the DAG's unobserved bricks (translucent, dashed outline).
# Rebuilt 2026-10-17 from the vault handoff "Handoff - Bias, variance and
# coverage animation", with Matt's overrides: 7 rows placed by hand (not 20
# simulated), no numbers but the coverage definition's "95%", red (not
# coral) for plates that miss, LEGO wording. One slide per comparison; each
# changes exactly one thing between its two columns:
#   bias:      unbiased | biased      the centre (no plates)
#   variance:  low | high variance    the spread (no plates)
#   coverage:  honest | overconfident the plates (same bricks)
#   bias breaks coverage: unbiased | biased, both with honest plates
# Two bells tie the ideas together (Matt, 2026-10-17; bells are fine where
# they help): the plate is the middle of a bell around its own brick (the
# zoom on the first slide), and the spread of the bricks is a bell over
# the column, whose middle is the spread bracket (variance). On the
# coverage slide our brick's own bell sits beside the column's bell: an
# honest plate's bell is as wide as the real spread, an overconfident one
# much narrower. Bracket and shaded middle span 1.96 spreads either side,
# so an honest plate (1.96 either side of its brick) is exactly as long as
# the bracket. Bells share one height (a sketch: width is the idea). The
# spread is a bracket, never a plate.
# The left column's bricks are the same on every slide and carry data-ids,
# so auto-animate holds them still between slides; everything else fades.
# Layout: left column (left third), right column (middle third), text in
# HTML in the qmd (right third). Each column is a 400 x 600 SVG: heading,
# "true answer", rows, the bell strip (baseline 500), bracket or average
# marker (518) with its word (540); with both, the average marker goes
# under the bracket (566).
# Positions in spreads, placed by hand; they average exactly 0. Checked:
# honest plates all reach the line; overconfident plates (0.6) miss rows
# 1, 4, 5, 7 (both sides); biased (shift 2) with honest plates misses rows
# 2, 4, 6, 7 (all right); every hit or miss clears the line by at least
# 0.2 spreads. Low variance puts our experiment near the line, high
# variance (x 2.5) well away.
repeat_answers <- c(-1.3, 0.3, -0.4, 0.8, -0.9, 0.2, 1.3)
repeat_ours <- 4 # the row that is our experiment
repeat_u <- 24 # px per unit (default)
# Column specs: shift and spread (units), plate = half-width (units),
# u = px per unit, nodiff = where "no difference" sits (units from the
# true answer; a dashed line)
repeat_cols <- list(
  unbiased = list(head = "Unbiased", shift = 0, spread = 1),
  biased = list(head = "Biased", shift = 2, spread = 1),
  low = list(head = "Low variance", shift = 0, spread = 1),
  high = list(head = "High variance", shift = 0, spread = 2.5),
  honest = list(head = "Honest plates", shift = 0, spread = 1, plate = 1.96),
  over = list(
    head = "Overconfident plates",
    shift = 0,
    spread = 1,
    plate = 0.6
  ),
  unbiased_honest = list(
    head = "Unbiased",
    shift = 0,
    spread = 1,
    plate = 1.96
  ),
  biased_honest = list(head = "Biased", shift = 2, spread = 1, plate = 1.96),
  # Build-1 errors (Section 1's return): units are the format effect (true
  # answer -1, "no difference" 0, so nodiff = 1). Backstage (HANDOFF
  # 2026-10-09 evening section 5, 400 repeats): leaving them out centres
  # near the truth (-0.86); adding them centres near "no difference"
  # (-0.13) and always shortens the plates. Placed to make that point: the
  # build-1 column centred 0.9 of the way to "no difference", tight (0.35)
  # with plates honest about that spread; 5 of 7 miss, all on the
  # "no difference" side; every hit or miss clears the line by 0.07 units
  # (about 5 px).
  build1_out = list(
    head = c("Leaving out errors", "on the first build"),
    shift = 0,
    spread = 0.69,
    plate = 1.35,
    u = 66,
    nodiff = 1
  ),
  build1_in = list(
    head = c("Adding errors", "on the first build"),
    shift = 0.9,
    spread = 0.35,
    plate = 0.69,
    u = 66,
    nodiff = 1
  ),
  # Unused since 2026-10-19 (Matt cut the slide: its bias was in one
  # session's level, but read as the instruction answer); kept because the
  # fx_ columns below reuse its geometry.
  # Partial pooling, the general case (multilevel's variance fix; Matt,
  # 2026-10-17, from the vault handoff "Partial pooling bias-variance
  # trade-off", three columns, no towers): one small session's answer
  # across many runs, its format's average a dashed line (ref). On its own:
  # centred, widely spread. Multilevel: pulled two-thirds of the way (the
  # handoff's backstage setting: between-session spread 5, within 10, 2
  # builds), so a third of the spread, a little off-centre. Just the
  # format's average: all the way, no spread, well off-centre. Squared
  # distance from the true answer (off-centre^2 + spread^2): 4 / 1.33 / 2;
  # mean distance over the 7 rows 1.49 / 0.94 / 1.41. The old placement
  # (shift 0.5, spread 1) gave 1.25 vs 1.0 for full pull, so full pull
  # would have looked best.
  # Headings (Matt, 2026-10-18): "As its own effect" (each session a fixed
  # effect, no pooling), "Not an effect at all" (sessions left out of the
  # model: every session gets its format's average, complete pooling)
  own = list(
    head = "As its own effect",
    shift = 0,
    spread = 2,
    u = 30,
    nodiff = 1.41,
    ref = "format's average"
  ),
  pooled = list(
    head = "Multilevel",
    shift = 0.94,
    spread = 0.67,
    u = 30,
    nodiff = 1.41,
    ref = "format's average"
  ),
  fmt_only = list(
    head = "Not an effect at all",
    shift = 1.41,
    spread = 0,
    u = 30,
    nodiff = 1.41,
    ref = "format's average"
  ),
  # The count model's Bias fix (Section 3's return), the general case by
  # hand. Option E (Matt, 2026-10-19; vault note "2026-10-19 Count model
  # return - what it fixes"): the answer is errors per format; the
  # transformed model (normal on log(errors + 1), converted back to errors,
  # the usual way to report it) centres too low; the count model, its
  # answer averaged over sessions and people, centres on the true answer.
  # A plain normal model would centre on it too (same format averages), so
  # it is not the comparison. Size from the desktop chat's 300 repeats with
  # the deck's design: the transform sits 0.36 (deck's normal generator) to
  # 0.9 (count generator) run-to-run spreads low, so one spread here (was
  # 3.3 spreads, against a plain normal model). Spread 1 in both columns
  # (was 0.6) so one spread shows (60 px). One change: the centre.
  # Transformed bricks from -2.3 to +0.3 units; leftmost 138 px left of the
  # line.
  glm_trans = list(
    head = "Transformed model",
    head_col = pal$orange[["light"]], # normal models light orange (Matt)
    shift = -1,
    spread = 1,
    u = 60
  ),
  glm_count = list(
    head = "Count model",
    head_col = pal$orange[["fill"]],
    shift = 0,
    spread = 1,
    u = 60
  ),
  # The prior's Coverage fix (Section 4's return; Matt, 2026-10-19): the
  # count model's format answer, the general case for few sessions, by
  # hand (not simulated). Same bricks; one change: the plate. One guess of
  # the spread treated as known: plates a little short (the linear model's
  # plug-in plate reaches the truth 87% of runs against 95%; the usual
  # count-model plate is expected to fall short the same way), so rows 1
  # and 7 miss. A prior on the spread: honest plates (1.96), all reach it,
  # "about as often as they claim". Checked: every hit or miss clears the
  # line by at least 0.2 units (rows 1, 5, 7 at 1.1). Headings in the
  # colours of slide 37's pieces: the yellow brick (one guess) and the
  # green prior. Headings say "how much sessions differ", not "spread"
  # (Matt, 2026-10-19 late: "spread" is the run-to-run bracket of 7-9).
  bayes_known = list(
    head = c("One guess of", "how much sessions differ"),
    head_col = pal$yellow[["fill"]],
    shift = 0,
    spread = 1,
    plate = 1.1,
    u = 44
  ),
  bayes_prior = list(
    head = c("A prior on", "how much sessions differ"),
    head_col = pal$green[["fill"]],
    shift = 0,
    spread = 1,
    plate = 1.96,
    u = 44
  ),
  # A prior on the format answer: the Bayesian piece's Variance fix (Matt,
  # 2026-10-19, from the vault handoff "Sensible prior bias-variance
  # trade-off"), the general case with thin data, as the cut partial-pooling
  # columns ("own" / "pooled" / "fmt_only") but
  # for the format answer, pulled toward "no difference" by the prior.
  # Normal prior at "no difference", normal data: the answer is the data's
  # answer times w = prior^2 / (prior^2 + noise^2), so the pull ((1 - w) of
  # the way) and the spread (w times) come from one w. Those columns' geometry
  # (no difference 1.41 from the true answer, spread 2 with no pull);
  # sensible w = 0.6: centre 0.56, spread 1.2; very strong: w near 0, drawn
  # at "no difference" with no spread. Squared distance from the true
  # answer (off-centre^2 + spread^2): 4 / 1.76 / 2; mean distance over the
  # 7 rows 1.49 / 0.99 / 1.41. The middle column beats the right one only
  # for w below 2/3 and is best at w = 1/3 (the size of the "pooled" pull);
  # 0.6 keeps the pull visibly small, unlike slide 20's collider column.
  # prior = c(spread in units, height in px), green, on the bell strip,
  # centred on "no difference": widths from w (noise 2: w 0.6 -> 2.45),
  # very wide (5; cut at the column's edges, a low hump, never flat; 8 read
  # as flat in a test render) and
  # narrow (0.35, w 0.03) by hand; heights by hand (a sketch).
  fx_none = list(
    head = "Almost no prior",
    shift = 0,
    spread = 2,
    u = 30,
    nodiff = 1.41,
    prior = c(5, 16)
  ),
  fx_sensible = list(
    head = "Sensible prior",
    shift = 0.56,
    spread = 1.2,
    u = 30,
    nodiff = 1.41,
    prior = c(2.45, 28)
  ),
  fx_strong = list(
    head = "Very strong prior",
    shift = 1.41,
    spread = 0,
    u = 30,
    nodiff = 1.41,
    prior = c(0.35, 48)
  )
)
repeat_ys <- 122 + (seq_along(repeat_answers) - 1) * 52 # plate tops
repeat_bell_y <- 500 # bell baseline
repeat_bell_h <- 44 # bell height
repeat_mark_y <- 518 # bracket / average marker

# One row: a plate from x1 to x2 with studs along its top, and a one-stud
# brick sitting on it, centred at x; y = top of the plate. unobserved = an
# imagined run: translucent with a dashed outline, as the DAG's unobserved
# bricks. Plate and brick are separate so a column can show bricks alone,
# add plates later, or recolour a plate (every plate part has class
# plate-part; brick_dag.css, .miss).
repeat_studs <- function(x, x1, x2) {
  gap <- 16 # stud spacing on the plate
  n <- max(1, floor((x2 - x1 - 8) / gap) + 1)
  sx <- (x1 + x2) / 2 - ((n - 1) * gap) / 2 + (0:(n - 1)) * gap - 4.5
  # Studs under the brick are left out: a translucent brick would show them
  sx[sx + 9 < x - 12 | sx > x + 12]
}
svg_repeat_plate <- function(x, x1, x2, y, unobserved = FALSE) {
  g <- pal$grey
  op <- if (unobserved) ' fill-opacity="0.55"' else ""
  da <- if (unobserved) ' stroke-dasharray="3 2"' else ""
  c(
    sprintf(
      '<rect class="plate-part" x="%.1f" y="%.1f" width="9" height="6" rx="1.5" fill="%s" stroke="%s" stroke-width="1"%s/>',
      repeat_studs(x, x1, x2),
      y - 5,
      g[["fill"]],
      g[["dark"]],
      op
    ),
    sprintf(
      '<rect class="plate-part" x="%.1f" y="%.1f" width="%.1f" height="12" rx="2" fill="%s" stroke="%s" stroke-width="1.5"%s%s/>',
      x1,
      y,
      x2 - x1,
      g[["fill"]],
      g[["dark"]],
      op,
      da
    )
  )
}
svg_repeat_brick <- function(x, y, unobserved = FALSE) {
  b <- pal$blue
  op <- if (unobserved) ' fill-opacity="0.55"' else ""
  da <- if (unobserved) ' stroke-dasharray="3 2"' else ""
  c(
    sprintf(
      '<rect x="%.1f" y="%.1f" width="10" height="6" rx="1.5" fill="%s" stroke="%s" stroke-width="1"%s/>',
      x - 5,
      y - 25,
      b[["fill"]],
      b[["dark"]],
      op
    ),
    sprintf(
      '<rect x="%.1f" y="%.1f" width="24" height="20" rx="3" fill="%s" stroke="%s" stroke-width="1.5"%s%s/>',
      x - 12,
      y - 20,
      b[["fill"]],
      b[["dark"]],
      op,
      da
    )
  )
}
svg_repeat_row <- function(x, x1, x2, y, unobserved = FALSE) {
  c(
    svg_repeat_plate(x, x1, x2, y, unobserved),
    svg_repeat_brick(x, y, unobserved)
  )
}

# A bell centred at x with spread sd (px), sitting on base, h tall, drawn
# to `reach` spreads either side (3.2; less where space is tight); its middle (1.96 spreads either side, the
# length of an honest plate or of the spread bracket) is shaded
svg_bell <- function(x, sd, base, h, col, reach = 3.2) {
  curve <- function(z) {
    sprintf("%.1f %.1f", x + z * sd, base - h * exp(-z^2 / 2))
  }
  zs <- seq(-reach, reach, length.out = 65)
  zm <- seq(-1.96, 1.96, length.out = 41)
  c(
    sprintf(
      '<path d="M %.1f %g L %s L %.1f %g Z" fill="%s" fill-opacity="0.18" stroke="none"/>',
      x - 1.96 * sd,
      base,
      paste(curve(zm), collapse = " L "),
      x + 1.96 * sd,
      base,
      col
    ),
    sprintf(
      '<path d="M %s" fill="none" stroke="%s" stroke-width="2" stroke-linejoin="round"/>',
      paste(curve(zs), collapse = " L "),
      col
    ),
    sprintf(
      '<line x1="%.1f" y1="%g" x2="%.1f" y2="%g" stroke="%s" stroke-width="1.5"/>',
      x - reach * sd,
      base,
      x + reach * sd,
      base,
      col
    )
  )
}

# A prior on the format answer (green, priors): a bell centred at x with
# spread sd (px), h tall, on the bell strip's baseline, cut at the
# column's edges (from, to), so a very wide prior shows as a low hump,
# never flat. Not shaded: it is not a plate's bell.
svg_prior <- function(x, sd, h, base = repeat_bell_y, from = 8, to = 392) {
  xs <- seq(max(from, x - 3.2 * sd), min(to, x + 3.2 * sd), length.out = 81)
  col <- pal$green[["fill"]]
  c(
    sprintf(
      '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="1.5"/>',
      from,
      base,
      to,
      base,
      col
    ),
    sprintf(
      '<path d="M %s" fill="none" stroke="%s" stroke-width="3.5" stroke-linejoin="round" stroke-linecap="round"/>',
      paste(
        sprintf("%.1f %.1f", xs, base - h * exp(-((xs - x) / sd)^2 / 2)),
        collapse = " L "
      ),
      col
    )
  )
}

# Spread bracket: a dimension line from x1 to x2 with upright end ticks
# and "spread" under it (ink). Never a plate.
svg_spread <- function(x1, x2, y = repeat_mark_y) {
  c(
    sprintf(
      '<path d="M %.1f %g V %g M %.1f %g H %.1f M %.1f %g V %g" fill="none" stroke="%s" stroke-width="2.5" stroke-linecap="round"/>',
      x1,
      y - 8,
      y + 8,
      x1,
      y,
      x2,
      x2,
      y - 8,
      y + 8,
      note_col
    ),
    svg_note((x1 + x2) / 2, y + 22, "spread", size = 16)
  )
}
# Average marker: an ink triangle pointing up at x, "average" under it
svg_average <- function(x, y = repeat_mark_y) {
  c(
    sprintf(
      '<path d="M %.1f %g L %.1f %g L %.1f %g Z" fill="%s"/>',
      x,
      y - 9,
      x + 8,
      y + 6,
      x - 8,
      y + 6,
      note_col
    ),
    svg_note(x, y + 22, "average", size = 16)
  )
}

# A piece that is static (at = 0), a fragment at index `at` (delay = CSS
# transition-delay in s, for row-by-row builds; cls = extra fragment
# classes, e.g. " fade-in-then-out"), or absent (NA)
repeat_frag <- function(svg, at, delay = 0, cls = "") {
  if (is.na(at)) {
    return(NULL)
  }
  svg <- paste(svg, collapse = "")
  if (at == 0) {
    return(svg)
  }
  sprintf(
    '<g class="fragment%s" data-fragment-index="%d"%s>%s</g>',
    cls,
    at,
    if (delay > 0) sprintf(' style="transition-delay: %.2fs"', delay) else "",
    svg
  )
}
# A piece auto-animate holds still between slides (tied left column only)
repeat_id <- function(svg, id, tie) {
  if (!tie) {
    return(paste(svg, collapse = ""))
  }
  sprintf('<g data-id="rp-%s">%s</g>', id, paste(svg, collapse = ""))
}

# Pointers for the zoom: an arrow and label in its object's colour, naming
# the piece and what it means (Matt, 2026-10-17). Colours: the brick's
# fill; the plate's outline (its fill, light grey, is too faint for text
# on the page). The zoom's bell is the plate's colour too.
repeat_pointers <- list(
  list(
    label = '<tspan font-weight="700">brick</tspan>: our best guess',
    col = pal$blue[["fill"]],
    id = "rp-blue"
  ),
  list(
    label = '<tspan font-weight="700">plate</tspan>: how far off our guess could be',
    col = pal$grey[["dark"]],
    id = "rp-grey"
  )
)
repeat_zoom <- 2.5

# One column. left = the tied left column of the bias-to-coverage slides:
# line left of centre (x 170) to leave room for "our experiment" and "if we
# ran it again and again", and data-ids on what stays put. The other
# arguments say when each layer comes in (repeat_frag: 0 static, k
# fragment k, NA absent):
#   rows     the bricks (with heading and line), row by row on one click
#            (0.12 s apart)
#   plates   one plate per brick (column's `plate` either side), row by row
#   miss     plates that miss the line turn red (an empty .miss-mark
#            fragment the CSS keys on)
#   avg      the average marker (avg_out = TRUE: gone at the next click;
#            avg_low = TRUE: at the lower height even without a bracket,
#            level with its neighbours' markers)
#   bracket  the column's bell and its spread bracket (bell = FALSE: the
#            bracket alone, leaving the bell strip to a prior)
#   ownbell  our brick's own bell (the plate's bell, grey) in the bell
#            strip, beside the column's
#   prior    the column's prior on the format answer (green, svg_prior),
#            centred on "no difference"
# zoom = TRUE (left column, first slide): the column opens on our
# experiment alone, repeat_zoom times larger in the middle of the slide
# (the SVG is drawn with overflow visible, so x = 600 is the slide's
# centre), with a short stretch of the line and its own "true answer".
# Fragment 1: the pointers ("brick: our best guess", "plate: how far off
# our guess could be"). Fragment 2: a bell rises around our brick, the
# plate across its shaded middle (the plate comes from how uncertain the
# guess is). Fragment 3: bell, pointers, that "true answer" and the plate
# fade (the bias step has no plates), our brick shrinks into its place
# (Matt, 2026-10-09), and the rest of the column (.grow-in) fades in once
# it has landed (brick_dag.css, .ours-shrink). At full size the short line
# lies exactly on the full one.
repeat_column <- function(
  set,
  left = FALSE,
  zoom = FALSE,
  rows = 0,
  plates = NA,
  miss = NA,
  avg = NA,
  avg_out = FALSE,
  avg_low = FALSE,
  bracket = NA,
  bell = TRUE,
  ownbell = NA,
  prior = NA
) {
  p <- repeat_cols[[set]]
  u <- if (is.null(p$u)) repeat_u else p$u
  cx <- if (left) 170 else 200
  ys <- repeat_ys
  ans <- cx + u * (p$shift + p$spread * repeat_answers)
  centre <- cx + u * p$shift
  obs <- seq_along(ans) == repeat_ours
  half <- if (is.null(p$plate)) NA else u * p$plate
  sd <- u * p$spread
  brick <- function(k) {
    repeat_id(
      svg_repeat_brick(ans[k], ys[k], !obs[k]),
      paste0("brick-", k),
      left
    )
  }
  plate <- function(k) {
    s <- svg_repeat_plate(ans[k], ans[k] - half, ans[k] + half, ys[k], !obs[k])
    if (!is.na(miss) && abs(ans[k] - cx) > half) {
      s <- sprintf('<g class="miss">%s</g>', paste(s, collapse = ""))
    }
    repeat_id(s, paste0("plate-", k), left)
  }
  stagger <- function(k) 0.12 * (k - 1)
  head <- sprintf(
    '<g font-weight="600">%s</g>',
    paste(
      svg_note(
        cx,
        40 - 26 * rev(seq_along(p$head) - 1),
        p$head,
        col = if (is.null(p$head_col)) note_col else p$head_col,
        size = 24
      ),
      collapse = ""
    )
  )
  # "true answer" over the line; with a "no difference" line beside it, the
  # two labels point outwards (either side: "no errors" sits left)
  nd <- if (is.null(p$nodiff)) NA else cx + u * p$nodiff
  out <- if (is.na(nd) || nd > cx) 1 else -1 # +1: the reference is right
  line <- c(
    repeat_id(
      c(
        sprintf(
          '<line x1="%g" y1="82" x2="%g" y2="%g" stroke="%s" stroke-width="3" stroke-linecap="round"/>',
          cx,
          cx,
          repeat_bell_y,
          note_col
        ),
        if (is.na(nd)) {
          svg_note(cx, 66, "true answer", size = 18)
        } else {
          c(
            svg_note(
              cx + 4 * out,
              66,
              "true answer",
              anchor = if (out > 0) "end" else "start",
              size = 18
            ),
            sprintf(
              '<line x1="%.1f" y1="82" x2="%.1f" y2="%g" stroke="%s" stroke-width="2" stroke-dasharray="6 5"/>',
              nd,
              nd,
              repeat_bell_y,
              note_col
            ),
            svg_note(
              nd - 4 * out,
              66,
              if (is.null(p$ref)) "no difference" else p$ref,
              anchor = if (out > 0) "start" else "end",
              size = 18
            )
          )
        }
      ),
      "line",
      left
    )
  )
  side <- cx + 80
  labels <- if (left) {
    c(
      repeat_id(
        svg_note(
          side,
          ys[repeat_ours] - 4,
          "our experiment",
          anchor = "start",
          size = 18
        ),
        "ours",
        left
      ),
      repeat_id(
        c(
          svg_note(
            side,
            ys[2] - 15,
            "if we ran it",
            anchor = "start",
            size = 18
          ),
          svg_note(
            side,
            ys[2] + 7,
            "again and again",
            anchor = "start",
            size = 18
          )
        ),
        "again",
        left
      )
    )
  }
  layers <- c(
    if (!is.na(bracket)) {
      repeat_id(
        repeat_frag(
          c(
            if (bell) {
              svg_bell(centre, sd, repeat_bell_y, repeat_bell_h, note_col)
            },
            svg_spread(centre - 1.96 * sd, centre + 1.96 * sd)
          ),
          bracket
        ),
        "bracket",
        left
      )
    },
    if (!is.na(prior)) {
      repeat_frag(svg_prior(nd, u * p$prior[1], p$prior[2]), prior)
    },
    if (!is.na(ownbell)) {
      repeat_frag(
        svg_bell(
          ans[repeat_ours],
          half / 1.96,
          repeat_bell_y,
          repeat_bell_h,
          pal$grey[["dark"]]
        ),
        ownbell
      )
    },
    if (!is.na(avg)) {
      repeat_frag(
        svg_average(
          centre,
          if (is.na(bracket) && !avg_low) repeat_mark_y else repeat_mark_y + 48
        ),
        avg,
        cls = if (avg_out) " fade-in-then-out" else ""
      )
    },
    if (!is.na(miss) && miss > 0) repeat_frag("", miss, cls = " miss-mark"),
    if (!is.na(miss) && miss == 0) '<g class="miss-mark"></g>'
  )
  plate_svg <- function(k) {
    if (is.na(plates)) NULL else repeat_frag(plate(k), plates, stagger(k))
  }
  if (!zoom) {
    return(c(
      repeat_frag(c(head, line), rows), # arrives with its first row
      labels,
      unlist(lapply(seq_along(ans), function(k) {
        c(
          plate_svg(k),
          repeat_frag(brick(k), rows, if (rows > 0) stagger(k) else 0)
        )
      })),
      layers
    ))
  }
  # zoom: the rest of the column grows in at fragment 3
  grow <- function(svg) {
    sprintf(
      '<g class="fragment" data-fragment-index="3"><g class="grow-in">%s</g></g>',
      paste(svg, collapse = "")
    )
  }
  ax <- ans[repeat_ours]
  y <- ys[repeat_ours]
  pointer <- function(r, d, tx, ty) {
    c(
      sprintf(
        '<path d="%s" fill="none" stroke="%s" stroke-width="1.6" stroke-linecap="round" marker-end="url(#%s)"/>',
        d,
        r$col,
        r$id
      ),
      svg_note(tx, ty, r$label, anchor = "start", col = r$col, size = 16)
    )
  }
  pointers <- c(
    '<defs>',
    sprintf(
      '<marker id="%s" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto-start-reverse"><path d="M1 1 L9 5 L1 9 Z" fill="%s"/></marker>',
      vapply(repeat_pointers, `[[`, "", "id"),
      vapply(repeat_pointers, `[[`, "", "col")
    ),
    '</defs>',
    pointer(
      repeat_pointers[[1]],
      sprintf(
        "M %g %g Q %g %g %g %g",
        ax + 34,
        y - 92,
        ax + 14,
        y - 80,
        ax + 4,
        y - 30
      ),
      ax + 38,
      y - 96
    ),
    pointer(
      repeat_pointers[[2]],
      sprintf(
        "M %g %g Q %g %g %g %g",
        ax + 42,
        y + 62,
        ax + 30,
        y + 52,
        ax + 30,
        y + 17
      ),
      ax + 46,
      y + 70
    )
  )
  # Our experiment: a short stretch of the line (y1 to y2); the bell (in at
  # 2) and plate (both gone at 3) under the brick; its label; and a "true
  # answer" under the line for the large opening view
  y1 <- y - 75
  y2 <- y + 45
  zplate <- u * 1.96 # an honest plate, as in "Honest plates"
  gone_at_3 <- function(svg) {
    sprintf(
      '<g class="fragment fade-out" data-fragment-index="3">%s</g>',
      paste(svg, collapse = "")
    )
  }
  ours <- c(
    sprintf(
      '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="3" stroke-linecap="round"/>',
      cx,
      y1,
      cx,
      y2,
      note_col
    ),
    gone_at_3(repeat_frag(
      svg_bell(ax, zplate / 1.96, y, 60, pal$grey[["dark"]], reach = 2.4),
      2
    )),
    gone_at_3(svg_repeat_plate(ax, ax - zplate, ax + zplate, y)),
    brick(repeat_ours),
    labels[1],
    gone_at_3(svg_note(cx, y2 + 16, "true answer", size = 18)),
    gone_at_3(repeat_frag(pointers, 1))
  )
  # Large view: scale about the viewBox origin, then move the group's centre
  # (row to the end of its label; from the top pointer label to the bottom
  # one) to the middle of the slide
  bx <- (ax - zplate + side + 125) / 2
  by <- (y - 104 + y + 78) / 2
  c(
    grow(c(head, line)),
    sprintf(
      '<g class="fragment custom ours-shrink" data-fragment-index="3" style="--zoom: translate(%.1fpx, %.1fpx) scale(%g)">%s</g>',
      600 - repeat_zoom * bx,
      290 - repeat_zoom * by,
      repeat_zoom,
      paste(ours, collapse = "")
    ),
    grow(c(labels[-1], unlist(lapply(which(!obs), brick)))),
    layers
  )
}

# One column as an SVG; the miss colours are set on it as CSS variables
# (brick_dag.css)
repeat_svg <- function(svg, cls = "") {
  sprintf(
    '<svg class="brick-dag no-highlight brick-repeats%s" viewBox="0 0 400 600" style="--miss-fill: %s; --miss-dark: %s" xmlns="http://www.w3.org/2000/svg">%s</svg>',
    cls,
    pal$red[["fill"]],
    pal$red[["dark"]],
    paste(svg, collapse = "")
  )
}

# One comparison slide's figure: the left column (left third) and the
# right column (middle third), each a list of repeat_column() arguments.
# tie = TRUE: the left column is the tied one of the bias-to-coverage
# slides (repeat_column `left`). Text is HTML in the qmd, after the chunk,
# inside .repeat-row. Use in a chunk with `#| output: asis`.
show_pair <- function(left, right, tie = TRUE) {
  cat(
    "```{=html}\n",
    repeat_svg(do.call(repeat_column, c(left, left = tie)), " repeat-left"),
    repeat_svg(do.call(repeat_column, right)),
    "\n```\n",
    sep = ""
  )
}

# Three columns across the slide, each a list of repeat_column() arguments
# (the sensible-prior slide); text goes above and below the row, in the
# qmd. Use in a chunk with `#| output: asis`.
show_trio <- function(a, b, c) {
  cat(
    "```{=html}\n",
    repeat_svg(do.call(repeat_column, a)),
    repeat_svg(do.call(repeat_column, b)),
    repeat_svg(do.call(repeat_column, c)),
    "\n```\n",
    sep = ""
  )
}

# One column on its own, everything static (the summary slide). Use in a
# chunk with `#| output: asis`.
show_column <- function(set, ...) {
  cat("```{=html}\n", repeat_svg(repeat_column(set, ...)), "\n```\n", sep = "")
}

# ---- how the count model works (Section 3) --------------------------------------
# The general case, drawn by hand (Matt, 2026-10-18: "we don't need to use
# simulated data to make theoretical points"). Errors in a build where
# many people make none and some make one or two (Matt, 2026-10-18; was
# "count only bricks in the wrong colour"), a few more. Each build is one
# brick, stacked over its number of
# errors (a histogram built from bricks); no numbers, "no errors" under the
# first stack, errors growing to the right (as "no errors" sits left on the
# return after it).
# Transformed vs count model (Matt, 2026-10-19, Option E in the vault note
# "2026-10-19 Count model return - what it fixes"): a skewed outcome like
# this is usually transformed; a count model describes it as it is.
#   (Normal models light orange since 2026-10-19 late, Matt: they were
#   yellow, which the legend gives the random effect. "Yellow" below
#   means that light orange.)
#   click 1: the plain normal model's curve (yellow; Matt, 2026-10-18: not
#            ink) with the stacks' own average and spread; the part below
#            no errors (left of the first stack's slot) is red, and the
#            baseline runs on under it: the negative-numbers problem
#            (briefly dropped, restored by Matt, 2026-10-19). It
#            fades at click 2, so one yellow curve is on screen at a time.
#   click 2: the transformed model (yellow: still a normal model, on
#            log(errors + 1)), drawn by hand and exaggerated (Matt,
#            2026-10-19): piled high at the low end, a thin tail, so it
#            sits visibly lower than the count model: a typical build,
#            not the average (slide 31's point).
#   click 3: the count model (orange, the section's colour): a negative
#            binomial with the stacks' average and spread, following the
#            pile and the tail. The yellow line stays, for the comparison.
# The transformed and count models are lines through one point per count
# (no dots; Matt, 2026-10-18). Each curve arrives with a pointer naming
# it, in its colour, as slide 6's brick and plate (Matt, 2026-10-18; they
# replaced the captions). The words "normal model" / "transformed model" /
# "count model" on slides 29 and 31 take the curves' colours exactly
# (brick_dag.css .bell-word / .count-word; column headings via repeat_cols
# head_col).
# Stacks: 25 builds, average 2, spread 2.06; the normal curve puts 11% of
# builds below no errors. Backstage: expected builds at
# 0, 1, 2, 3, 4 errors, count model 6.5, 6.2, 4.5, 3.0, 1.9 (the
# transformed line is hand-drawn; see trans_builds). Converted back, the
# fitted transformed model's average (the usual way to report it) is 1.4
# errors against the stacks' 2.
count_stacks <- c(7, 6, 4, 3, 2, 1, 1, 0, 1) # builds with 0, 1, 2, ... errors
count_geom <- list(x0 = 420, u = 80, base = 470, w = 70, h = 46)

count_elements <- function(bell = 1, trans = 2, shape = 3) {
  g <- count_geom
  k <- seq_along(count_stacks) - 1
  n <- sum(count_stacks)
  m <- sum(k * count_stacks) / n
  s <- sqrt(sum((k - m)^2 * count_stacks) / n)
  px <- function(e) g$x0 + g$u * e
  py <- function(b) g$base - g$h * b # b = height in builds
  # Bottom-up, so each brick covers the studs of the one below
  stacks <- unlist(lapply(k[count_stacks > 0], function(e) {
    unlist(lapply(seq_len(count_stacks[e + 1]), function(j) {
      svg_brick(px(e) - g$w / 2, py(j), g$w, g$h, "blue", "", stud_h = 9)
    }))
  }))
  axis <- function(x1, x2) {
    sprintf(
      '<line x1="%.1f" y1="%g" x2="%.1f" y2="%g" stroke="%s" stroke-width="3" stroke-linecap="round"/>',
      x1,
      g$base,
      x2,
      g$base,
      note_col
    )
  }
  line <- function(ys, col) {
    sprintf(
      '<path d="M %s" fill="none" stroke="%s" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round"/>',
      paste(sprintf("%.1f %.1f", px(k), ys), collapse = " L "),
      col
    )
  }
  # Plain normal model: a smooth curve with the stacks' average and spread
  reach <- 3.2
  es <- seq(m - reach * s, m + reach * s, length.out = 81)
  curve <- function(e) {
    sprintf("%.1f %.1f", px(e), py(n * dnorm(e, m, s)))
  }
  below <- es[es < -0.5]
  bell_svg <- c(
    axis(px(m - reach * s), px(-0.5)),
    sprintf(
      '<path d="M %.1f %g L %s L %.1f %g Z" fill="%s" fill-opacity="0.45" stroke="none"/>',
      px(min(below)),
      g$base,
      paste(curve(c(below, -0.5)), collapse = " L "),
      px(-0.5),
      g$base,
      pal$red[["fill"]]
    ),
    sprintf(
      '<path d="M %s" fill="none" stroke="%s" stroke-width="4.5" stroke-linejoin="round"/>',
      paste(curve(es), collapse = " L "),
      pal$orange[["light"]]
    ),
    svg_note(
      px(-2.6),
      g$base + 30,
      "fewer than no errors",
      col = pal$red[["dark"]],
      size = 24
    )
  )
  # Transformed: drawn by hand, exaggerated to make the point (Matt,
  # 2026-10-19: "it's ok if they are slightly wrong mathematically, I want
  # them to make a point"): it piles higher over no errors and one error
  # and thins out over the tail, so it sits visibly lower than the count
  # model. The idea: the transform gives the long tail less weight, so
  # converted back its answer is a typical build, below the average
  # (slide 31). Builds per count, 0 to 8; about 25 in all. (Fitted
  # honestly, a normal model on log(errors + 1) would be 6.1, 7.0, 4.7,
  # 2.8, 1.7, ...: close to the count model.)
  trans_builds <- c(8, 7.5, 4.5, 2.2, 1.1, 0.6, 0.4, 0.3, 0.2)
  yt <- py(trans_builds)
  trans_svg <- line(yt, pal$orange[["light"]])
  r <- m^2 / (s^2 - m) # negative binomial size, same average and spread
  ys <- py(n * dnbinom(k, size = r, mu = m))
  shape_svg <- line(ys, pal$orange[["fill"]])
  # Pointers, as slide 6's (repeat_pointers): a curved arrow and the curve's
  # name, both in the curve's colour (Matt, 2026-10-18; they replace the
  # captions). Each arrives with its curve. Placed in the empty space:
  # "normal model" upper left, onto the bell's left side (it leaves before
  # the next label takes that space); "transformed model" upper left, its arrow over the
  # first stack onto the yellow line where it rises above the second
  # (inside the first stack there is no clear spot); "count model" upper
  # right, onto the orange line between the first two stacks.
  pointer <- function(id, col, label, tx, ty, d, anchor = "start") {
    c(
      sprintf(
        '<defs><marker id="%s" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto-start-reverse"><path d="M1 1 L9 5 L1 9 Z" fill="%s"/></marker></defs>',
        id,
        col
      ),
      sprintf(
        '<path d="%s" fill="none" stroke="%s" stroke-width="2.5" stroke-linecap="round" marker-end="url(#%s)"/>',
        d,
        col,
        id
      ),
      sprintf(
        '<g font-weight="700">%s</g>',
        svg_note(tx, ty, label, anchor = anchor, col = col, size = 28)
      )
    )
  }
  bx <- px(-1.3) # bell's left side
  by <- py(n * dnorm(-1.3, m, s))
  bell_svg <- c(
    bell_svg,
    pointer(
      "cnt-bell",
      pal$orange[["light"]],
      "normal model",
      bx - 210,
      by - 110,
      sprintf(
        "M %g %g Q %g %g %g %g",
        bx - 120,
        by - 92,
        bx - 30,
        by - 85,
        bx - 6,
        by - 14
      )
    )
  )
  tx <- px(0.75) # yellow line, rising above the second stack
  ty <- yt[1] + 0.75 * (yt[2] - yt[1])
  cx <- px(0.6) # orange line between the first two stacks
  cy <- ys[1] + 0.6 * (ys[2] - ys[1])
  trans_svg <- c(
    trans_svg,
    pointer(
      "cnt-trans",
      pal$orange[["light"]],
      "transformed model",
      px(-1),
      128,
      sprintf(
        "M %g %g Q %g %g %g %g",
        px(-1) + 8,
        128,
        tx - 50,
        112,
        tx - 7,
        ty - 8
      ),
      anchor = "end"
    )
  )
  shape_svg <- c(
    shape_svg,
    pointer(
      "cnt-count",
      pal$orange[["fill"]],
      "count model",
      cx + 150,
      cy - 22,
      sprintf(
        "M %g %g Q %g %g %g %g",
        cx + 140,
        cy - 22,
        cx + 70,
        cy - 36,
        cx + 10,
        cy - 10
      )
    )
  )
  c(
    stacks,
    axis(px(-0.5), px(max(k) + 0.6)),
    svg_note(px(0), g$base + 30, "no errors", size = 24),
    svg_note(px(4.6), g$base + 30, "more errors &#8594;", size = 24),
    repeat_frag(bell_svg, bell, cls = " fade-in-then-out"),
    repeat_frag(trans_svg, trans),
    repeat_frag(shape_svg, shape)
  )
}

# Use in a chunk with `#| output: asis`.
show_counts <- function(bell = 1, trans = 2, shape = 3) {
  cat(
    "```{=html}\n",
    # viewBox top 80 (was 110), so the hand-drawn transformed line's peak
    # (8 builds) fits (Matt, 2026-10-19)
    '<svg class="brick-dag no-highlight brick-counts" viewBox="30 80 1100 440" xmlns="http://www.w3.org/2000/svg">',
    paste(count_elements(bell, trans, shape), collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- the family of models (Section 3, after the Bias return) ------------------
# Match the model to the outcome's shape (Matt, 2026-10-18): the normal and
# count models are two of a family; other outcomes call for other shapes.
# Slide 29's look with lines only (no brick stacks): three panels side by
# side, each one LEGO outcome with its heading (plain words; the model
# names stay in the speaker notes), its own baseline with words at its
# limits (no numbers), and density lines. One panel per click.
#   Time to finish   (gamma, shape 2.5): starts at no time, rises, long
#                    tail; orange (orange = distributions)
#   Share of bricks correct (beta 8, 2): piles near "all", stops at both
#                    ends; orange
#   Number of errors (distributional / sigma regression, beyond
#                    GLMs; Matt, 2026-10-18, replacing "Finished or not",
#                    too simple): the spread depends on format as well as
#                    the average. Two normal curves in the format colours
#                    (picture #17678C, text #488136), each labelled; text
#                    a little to the left (fewer errors) and narrower
#                    (more consistent). Kept by Matt (2026-10-19 late): the
#                    panel shows modelling a difference in distributions;
#                    a same-average count-curve version was tried and
#                    reverted
# Curves are drawn over x in [0, 1] along the baseline and scaled to the
# same peak height, as the bells on slides 6-9 (width is the idea);
# shapes, not values.
family_panels <- list(
  list(
    head = "Time to finish",
    ends = c("no time", "longer &#8594;"),
    curves = list(list(f = function(x) dgamma(10 * x, shape = 2.5)))
  ),
  list(
    head = "Share of bricks correct",
    ends = c("none", "all"),
    curves = list(list(f = function(x) dbeta(x, 8, 2)))
  ),
  list(
    head = "Number of errors",
    ends = c("fewer", "more &#8594;"),
    # label: name beside the curve at half height, on side -1 (left) or +1
    curves = list(
      list(
        f = function(x) dnorm(x, 0.6, 0.13),
        col = format_col[["picture"]],
        label = "picture",
        side = 1,
        at = c(0.6, 0.13)
      ),
      list(
        f = function(x) dnorm(x, 0.38, 0.065),
        col = format_col[["text"]],
        label = "text",
        side = -1,
        at = c(0.38, 0.065)
      )
    )
  )
)

family_elements <- function(frag = 1:3) {
  w <- 340 # baseline length
  gap <- 60
  x0s <- (1200 - 3 * w - 2 * gap) / 2 + (0:2) * (w + gap)
  base <- 420
  peak <- 300
  unlist(lapply(seq_along(family_panels), function(i) {
    p <- family_panels[[i]]
    x0 <- x0s[i]
    px <- function(x) x0 + w * x
    line <- sprintf(
      '<line x1="%.1f" y1="%g" x2="%.1f" y2="%g" stroke="%s" stroke-width="3" stroke-linecap="round"/>',
      x0,
      base,
      x0 + w,
      base,
      note_col
    )
    head <- sprintf(
      '<g font-weight="600">%s</g>',
      svg_note(x0 + w / 2, 70, p$head, size = 26)
    )
    xs <- seq(0, 1, length.out = 161)
    shapes <- unlist(lapply(p$curves, function(cv) {
      col <- if (is.null(cv$col)) pal$orange[["fill"]] else cv$col
      d <- cv$f(xs)
      ys <- base - peak * d / max(d)
      c(
        sprintf(
          '<path d="M %s" fill="none" stroke="%s" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round"/>',
          paste(sprintf("%.1f %.1f", px(xs), ys), collapse = " L "),
          col
        ),
        if (!is.null(cv$label)) {
          # beside the curve at half height (1.18 spreads from its centre)
          lx <- px(cv$at[1] + cv$side * 1.18 * cv$at[2]) + cv$side * 10
          sprintf(
            '<g font-weight="700">%s</g>',
            svg_note(
              lx,
              base - peak / 2,
              cv$label,
              anchor = if (cv$side > 0) "start" else "end",
              col = col,
              size = 24
            )
          )
        }
      )
    }))
    ends <- c(
      svg_note(x0, base + 30, p$ends[1], anchor = "start", size = 22),
      svg_note(x0 + w, base + 30, p$ends[2], anchor = "end", size = 22)
    )
    repeat_frag(c(head, line, shapes, ends), frag[i])
  }))
}

# Use in a chunk with `#| output: asis`.
show_family <- function(frag = 1:3) {
  cat(
    "```{=html}\n",
    '<svg class="brick-dag no-highlight brick-family" viewBox="0 30 1200 445" xmlns="http://www.w3.org/2000/svg">',
    paste(family_elements(frag), collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- frequentist vs Bayesian (Section 4, before the prior) ---------------------
# UNUSED since 2026-10-19: merged into show_answers() (Matt), which carries
# this slide's prior step. Kept for reference.
# The contrast (Matt, 2026-10-19: before the prior goes on the DAG, so
# "prior" lands with context). Two panels, slide 6's zoomed brick and plate
# drawn twice as large (local coordinates scaled by contrast_zoom). No
# true-answer line: in a real study we never see it.
#   click 1  Frequentist: our brick on its plate, two imagined runs above
#            it (translucent, dashed, as on slides 6-9); the plate is a
#            promise about those runs
#   click 2  Bayesian: heading and a broad, low green curve, the prior
#            (what we believed before)
#   click 3  our brick on its plate inside a bell (grey, the plate's bell,
#            as on slide 6's zoom), tall and narrow: after the data, where
#            the true answer probably is
# The prior here is on the answer itself, the general idea; the next slide
# puts it on the spread. A density sketch: the prior wide and low, the
# bell after the data narrower and taller.
contrast_zoom <- 2

contrast_elements <- function(frag = 1:3) {
  s <- contrast_zoom
  u <- repeat_u
  lx <- 130 # our brick, local
  ly <- 150 # its plate top, local
  half <- 1.96 * u # an honest plate
  scaled <- function(svg, tx) {
    sprintf(
      '<g transform="translate(%g %g) scale(%g)">%s</g>',
      tx,
      70 - 20 * s,
      s,
      paste(svg, collapse = "")
    )
  }
  head <- function(x, label) {
    sprintf('<g font-weight="600">%s</g>', svg_note(x, 50, label, size = 30))
  }
  lines <- function(x, l) {
    c(svg_note(x, 400, l[1], size = 24), svg_note(x, 432, l[2], size = 24))
  }
  centres <- c(300, 900)
  tx <- centres - s * lx
  # Frequentist
  runs <- lx + u * c(-0.8, 0.7) # imagined runs, local
  ry <- c(52, 101)
  freq <- c(
    head(centres[1], "Frequentist"),
    scaled(
      c(
        unlist(lapply(1:2, function(k) {
          svg_repeat_row(
            runs[k],
            runs[k] - half,
            runs[k] + half,
            ry[k],
            unobserved = TRUE
          )
        })),
        svg_repeat_row(lx, lx - half, lx + half, ly)
      ),
      tx[1]
    ),
    lines(centres[1], c("The plate is a promise", "about many imagined runs"))
  )
  # Bayesian
  pr <- seq(-5.2, 5.2, length.out = 81)
  prior <- sprintf(
    '<path d="M %s" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
    paste(
      sprintf("%.1f %.1f", lx + pr * u, ly - 26 * exp(-(pr / 2.6)^2 / 2)),
      collapse = " L "
    ),
    pal$green[["fill"]]
  )
  bayes_prior <- c(
    head(centres[2], "Bayesian"),
    scaled(
      c(
        prior,
        svg_note(
          lx - 4.4 * u,
          ly - 34,
          "prior",
          anchor = "start",
          col = pal$green[["dark"]],
          size = 11
        )
      ),
      tx[2]
    )
  )
  bayes_data <- c(
    scaled(
      c(
        svg_bell(lx, half / 1.96, ly, 80, pal$grey[["dark"]], reach = 2.4),
        svg_repeat_row(lx, lx - half, lx + half, ly),
        svg_note(
          lx + 1.1 * u,
          ly - 70,
          "after the data",
          anchor = "start",
          col = pal$grey[["dark"]],
          size = 11
        )
      ),
      tx[2]
    ),
    lines(
      centres[2],
      c(
        "Start from a prior, add the data:",
        "where the true answer probably is"
      )
    )
  )
  c(
    repeat_frag(freq, frag[1]),
    repeat_frag(bayes_prior, frag[2]),
    repeat_frag(bayes_data, frag[3])
  )
}

# Use in a chunk with `#| output: asis`.
show_contrast <- function(frag = 1:3) {
  cat(
    "```{=html}\n",
    '<svg class="brick-dag no-highlight brick-contrast" viewBox="0 0 1200 460" xmlns="http://www.w3.org/2000/svg">',
    paste(contrast_elements(frag), collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- same data, two kinds of answer (Section 4, opens it) ---------------------
# Slide 35, "Do text instructions lead to fewer errors?" (title). Revised
# 2026-10-19 (Matt's brief): the way people intuitively read a frequentist
# result is the Bayesian reading. Two columns with the same brick on the
# same plate (local coordinates, scaled by contrast_zoom); no true-answer
# line (in a real study we never see it). No numbers, no new concepts.
#   click 1  Frequentist: two imagined runs behind our plate (translucent,
#            dashed)
#   click 2  Bayesian: the bell after the data (the posterior; grey, as
#            slide 6's zoom) behind our plate
#   click 3  a dashed "no difference" line through both columns, crossing
#            the plate (as in our study), and the bell's text side shaded
#            in the text format's colour
#   click 4  the shared sentence, italic, below the plots (moved there
#            and the plots shifted up, Matt, 2026-10-19): "Text probably leads to fewer errors."
#   click 5  left verdict: red cross, bold "Tempting, but not allowed.",
#            then "The method catches the truth most of the time. / It
#            can't tell you about this plate."
#   click 6  right verdict: green tick, bold "Allowed.", then "That's
#            exactly what this answers." Marks and bold lines share one
#            height (yv), explanations start at one height (yl).
# (A punchline, "Most people already read results the Bayesian way.", was
# click 7 briefly; removed completely, Matt, 2026-10-19.)
# Removed in the revision: the green prior curve and "prior" (so "prior"
# first appears on slide 36), "<- text: fewer errors", and all earlier
# captions (the frequentist plate's meaning, "Start from a prior...", the
# not-significant line, "Text probably leads... though we can't be sure").
# No difference sits 1.5 spreads right of the brick, inside the plate
# (1.96): the bell puts about 93% on the text side, "probably", not
# "certainly".
answers_elements <- function(frag = 1:6) {
  s <- contrast_zoom
  u <- repeat_u
  lx <- 130 # our brick, local
  ly <- 150 # its plate top, local
  half <- 1.96 * u # an honest plate
  nd <- lx + 1.5 * u # no difference, local
  centres <- c(300, 900)
  scaled <- function(svg, k) {
    sprintf(
      '<g transform="translate(%g %g) scale(%g)">%s</g>',
      centres[k] - s * lx,
      76, # back to 76: the shared sentence sits below the plots (Matt, 2026-10-19)
      s,
      paste(svg, collapse = "")
    )
  }
  head <- function(k, label) {
    sprintf(
      '<g font-weight="600">%s</g>',
      svg_note(centres[k], 80, label, size = 30)
    )
  }
  ours <- svg_repeat_row(lx, lx - half, lx + half, ly)
  nodiff <- c(
    sprintf(
      '<line x1="%g" y1="30" x2="%g" y2="%g" stroke="%s" stroke-width="1.2" stroke-dasharray="4 3"/>',
      nd,
      nd,
      ly + 20,
      note_col
    ),
    svg_note(nd, 21, "no difference", size = 10)
  )
  # Frequentist
  runs <- lx + u * c(-0.8, 0.7)
  ry <- c(52, 101)
  freq_runs <- unlist(lapply(1:2, function(k) {
    svg_repeat_row(
      runs[k],
      runs[k] - half,
      runs[k] + half,
      ry[k],
      unobserved = TRUE
    )
  }))
  # Bayesian: the bell (the posterior), and its text side shaded
  sd <- half / 1.96
  zs <- seq(-2.4, 2.4, length.out = 97)
  bx <- lx + zs * sd
  by <- ly - 80 * exp(-zs^2 / 2)
  left <- bx <= nd
  shade <- sprintf(
    '<path d="M %.1f %g L %s L %.1f %g Z" fill="%s" fill-opacity="0.35" stroke="none"/>',
    bx[1],
    ly,
    paste(
      sprintf(
        "%.1f %.1f",
        c(bx[left], nd),
        c(by[left], ly - 80 * exp(-((nd - lx) / sd)^2 / 2))
      ),
      collapse = " L "
    ),
    nd,
    ly,
    format_col[["text"]]
  )
  bell <- svg_bell(lx, sd, ly, 80, pal$grey[["dark"]], reach = 2.4)
  # The shared sentence, the two verdicts and the punchline
  shared <- sprintf(
    '<text x="600" y="472" text-anchor="middle" dominant-baseline="central" font-size="30" font-style="italic" fill="%s">Text probably leads to fewer errors.</text>',
    note_col
  )
  yv <- 548 # verdict line (marks and bold first lines), both columns
  yl <- 592 # first explanation line, both columns
  verdict <- function(x0, mark, label) {
    sprintf(
      '<g font-weight="700">%s</g>',
      svg_note(x0, yv, label, anchor = "start", size = 26)
    ) |>
      c(mark)
  }
  cross <- function(x, y, r = 22) {
    sprintf(
      '<path d="M %g %g L %g %g M %g %g L %g %g" stroke="%s" stroke-width="7" stroke-linecap="round"/>',
      x - r, y - r, x + r, y + r, x - r, y + r, x + r, y - r,
      pal$red[["fill"]]
    )
  }
  tick <- function(x, y, r = 25) {
    sprintf(
      '<path d="M %g %g L %g %g L %g %g" fill="none" stroke="%s" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>',
      x - r, y + 2, x - r / 3, y + r - 2, x + r, y - r,
      pal$green[["fill"]]
    )
  }
  # Each verdict (mark + bold line) is centred on its column by eye: the
  # bold line's width estimated at 13 px per character (checked rendered)
  lw <- c(26, 8) * 13
  gw <- 44 + 16 + lw # mark, gap, text
  gx <- centres - gw / 2
  left_v <- c(
    verdict(gx[1] + 60, cross(gx[1] + 22, yv), "Tempting, but not allowed."),
    svg_note(
      centres[1],
      yl + c(0, 31),
      c(
        "The method catches the truth most of the time.",
        "It can&#8217;t tell you about this plate."
      ),
      size = 24
    )
  )
  right_v <- c(
    verdict(gx[2] + 60, tick(gx[2] + 22, yv), "Allowed."),
    svg_note(centres[2], yl, "That&#8217;s exactly what this answers.", size = 24)
  )
  c(
    head(1, "Frequentist"),
    head(2, "Bayesian"),
    # Frequentist column: runs (1) and no difference (3) under our plate
    repeat_frag(scaled(freq_runs, 1), frag[1]),
    repeat_frag(scaled(nodiff, 1), frag[3]),
    scaled(ours, 1),
    # Bayesian column: bell (2), shade and no difference (3) under our plate
    repeat_frag(scaled(bell, 2), frag[2]),
    repeat_frag(scaled(shade, 2), frag[3]),
    repeat_frag(scaled(nodiff, 2), frag[3]),
    scaled(ours, 2),
    repeat_frag(shared, frag[4]),
    repeat_frag(left_v, frag[5]),
    repeat_frag(right_v, frag[6])
  )
}

# Use in a chunk with `#| output: asis`.
show_answers <- function(frag = 1:6) {
  cat(
    "```{=html}\n",
    # viewBox 0 50 1200 590: plots, the shared sentence and the verdicts
    # (the punchline was removed, Matt, 2026-10-19)
    '<svg class="brick-dag no-highlight brick-answers" viewBox="0 50 1200 590" xmlns="http://www.w3.org/2000/svg">',
    paste(answers_elements(frag), collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- how the prior works: the spread between sessions (Section 4) -------------
# How much sessions differ, one guess vs a range (IDEAS section 3 visual 1;
# Matt, 2026-10-19), the general case drawn by hand. One baseline, "sessions
# alike" (no spread) at the left, "differ a lot" to the right; no numbers.
#   click 1  the usual fit's one guess: a yellow brick (session level is
#            yellow) on the baseline, treated as known
#   click 2  the prior (green): highest at "alike", falling gently (a
#            half-normal, the shape used in practice: modest differences
#            likely, big ones allowed)
#   click 3  after the data (yellow, light fill): still wide with 6
#            sessions, well above the line at "alike", peaking over the
#            brick (the one guess is the single most likely value),
#            fading by the right end
# Each arrives with a pointer naming it in its colour, as slide 29. Shapes
# only: the curve after the data is the prior times a likelihood of the
# form for 6 session averages (each with its own sampling noise), tuned by
# hand so it peaks near the guess and stays wide; both curves are
# densities on one scale (the curve after the data is a little taller).
# Backstage (handoff section 5): seed 503's guess 1.39, data consistent
# with 0.00 to 2.51.
spread_geom <- list(x0 = 170, u = 200, base = 430, peak = 290, top = 4.3)

spread_elements <- function(frag = 1:3) {
  g <- spread_geom
  px <- function(v) g$x0 + g$u * v
  sv <- seq(0, g$top, length.out = 121)
  prior <- dnorm(sv, 0, 2.2)
  lik <- (sv^2 + 1.5)^(-2) * exp(-13.84 / (2 * (sv^2 + 1.5)))
  post <- prior * lik
  prior <- prior / sum(prior)
  post <- post / sum(post)
  k <- g$peak / max(post)
  path <- function(d) {
    paste(sprintf("%.1f %.1f", px(sv), g$base - k * d), collapse = " L ")
  }
  guess <- sv[which.max(post)] # the one guess sits under the peak
  pointer <- function(id, col, label, tx, ty, d) {
    c(
      sprintf(
        '<defs><marker id="%s" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto-start-reverse"><path d="M1 1 L9 5 L1 9 Z" fill="%s"/></marker></defs>',
        id,
        col
      ),
      sprintf(
        '<path d="%s" fill="none" stroke="%s" stroke-width="2.5" stroke-linecap="round" marker-end="url(#%s)"/>',
        d,
        col,
        id
      ),
      sprintf(
        '<g font-weight="700">%s</g>',
        svg_note(tx, ty, label, anchor = "start", col = col, size = 28)
      )
    )
  }
  bx <- px(guess)
  brick <- c(
    svg_brick(bx - 35, g$base - 46, 70, 46, "yellow", "", stud_h = 9),
    pointer(
      "spr-guess",
      pal$yellow[["fill"]],
      "one guess",
      bx + 110,
      g$base - 55,
      sprintf(
        "M %g %g Q %g %g %g %g",
        bx + 104,
        g$base - 55,
        bx + 70,
        g$base - 52,
        bx + 44,
        g$base - 28
      )
    )
  )
  py_at <- function(d, v) g$base - k * d[which.min(abs(sv - v))]
  prior_svg <- c(
    sprintf(
      '<path d="M %s" fill="none" stroke="%s" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round"/>',
      path(prior),
      pal$green[["fill"]]
    ),
    pointer(
      "spr-prior",
      pal$green[["fill"]],
      "prior",
      px(3.25),
      py_at(prior, 3.1) - 80,
      sprintf(
        "M %g %g Q %g %g %g %g",
        px(3.22),
        py_at(prior, 3.1) - 80,
        px(3.1) - 10,
        py_at(prior, 3.1) - 70,
        px(3.1),
        py_at(prior, 3.1) - 10
      )
    )
  )
  post_svg <- c(
    sprintf(
      '<path d="M %.1f %g L %s L %.1f %g Z" fill="%s" fill-opacity="0.18" stroke="none"/>',
      px(0),
      g$base,
      path(post),
      px(g$top),
      g$base,
      pal$yellow[["fill"]]
    ),
    sprintf(
      '<path d="M %s" fill="none" stroke="%s" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round"/>',
      path(post),
      pal$yellow[["fill"]]
    ),
    pointer(
      "spr-post",
      pal$yellow[["fill"]],
      "after the data",
      px(2.2),
      g$base - g$peak - 30,
      sprintf(
        "M %g %g Q %g %g %g %g",
        px(2.2) - 6,
        g$base - g$peak - 30,
        px(1.85),
        g$base - g$peak - 24,
        px(1.75),
        py_at(post, 1.75) - 8
      )
    )
  )
  c(
    sprintf(
      '<line x1="%.1f" y1="%g" x2="%.1f" y2="%g" stroke="%s" stroke-width="3" stroke-linecap="round"/>',
      px(0),
      g$base,
      px(g$top),
      g$base,
      note_col
    ),
    svg_note(px(0), g$base + 30, "sessions alike", anchor = "start", size = 24),
    svg_note(
      px(g$top),
      g$base + 30,
      "differ a lot &#8594;",
      anchor = "end",
      size = 24
    ),
    repeat_frag(post_svg, frag[3]),
    repeat_frag(prior_svg, frag[2]),
    repeat_frag(brick, frag[1])
  )
}

# Use in a chunk with `#| output: asis`.
show_spread <- function(frag = 1:3) {
  cat(
    "```{=html}\n",
    '<svg class="brick-dag no-highlight brick-spread" viewBox="120 90 1000 390" xmlns="http://www.w3.org/2000/svg">',
    paste(spread_elements(frag), collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- why switch to Bayesian (Section 4, the section's summary) ----------------
# Three benefits of switching, one small panel each, one per click (Matt,
# 2026-10-19, grilled first): the slide sells the whole approach, not just
# the prior on the spread. Each panel calls back to its full-size picture
# earlier in the section; the line under it (Matt's set A) carries any
# condition. Panels as slide 32's (340 wide, 60 apart); no numbers.
#   1 "Honest plates, particularly when data are thin" (slide 38; Matt,
#     2026-10-19, was "even when"): the same brick
#     twice against the true-answer line; the usual fit's plate short and
#     missing (red), the Bayesian plate longer and reaching it. One change:
#     the plate. Labels "Frequentist" (ink; was "usual fit", Matt
#     2026-10-19 late: one name on screen) / "Bayesian" (green, priors).
#     Clearances 25 px either way.
#   2 "Says where the true answer probably is" (slide 35): our brick on its
#     plate inside its bell, a dashed "no difference" line; the part of the
#     bell on the "text: fewer errors" side shaded in the text format's
#     colour: a Bayesian fit can say how likely it is that text helps.
#   3 "Uses what we already know, openly" (slide 37): the prior on the
#     spread, slide 37's half-normal (highest at "alike", falling gently).
benefit_lines <- list(
  c("Honest plates,", "particularly when data are thin"),
  c("Says where the true", "answer probably is"),
  c("Uses what we already", "know, openly")
)

benefit_elements <- function(frag = 1:3) {
  w <- 340
  gap <- 60
  x0s <- (1200 - 3 * w - 2 * gap) / 2 + (0:2) * (w + gap)
  base <- 300
  under <- function(i) {
    svg_note(
      x0s[i] + w / 2,
      base + 82 + c(0, 30),
      benefit_lines[[i]],
      size = 24
    )
  }
  red_plate <- function(svg) {
    svg <- gsub(pal$grey[["fill"]], pal$red[["fill"]], svg, fixed = TRUE)
    gsub(pal$grey[["dark"]], pal$red[["dark"]], svg, fixed = TRUE)
  }
  # 1 honest plates: rows drawn at the columns' size around a local origin
  # (brick at 0, plate top at 0), then scaled up 1.6x to match the other
  # panels. Local: true answer at +70; short plate +-45 (misses by 25),
  # long plate +-95 (reaches past it by 25).
  zoom <- 1.6
  bx <- x0s[1] + 160 # the same brick in both rows
  cx <- bx + zoom * 70 # true answer
  row <- function(svg, y) {
    sprintf(
      '<g transform="translate(%g %g) scale(%g)">%s</g>',
      bx,
      y,
      zoom,
      paste(svg, collapse = "")
    )
  }
  p1 <- c(
    sprintf(
      '<line x1="%g" y1="120" x2="%g" y2="%g" stroke="%s" stroke-width="3" stroke-linecap="round"/>',
      cx,
      cx,
      base + 10,
      note_col
    ),
    svg_note(cx, 104, "true answer", size = 18),
    svg_note(x0s[1], 140, "Frequentist", anchor = "start", size = 20),
    row(
      c(red_plate(svg_repeat_plate(0, -45, 45, 0)), svg_repeat_brick(0, 0)),
      200
    ),
    svg_note(
      x0s[1],
      232,
      "Bayesian",
      anchor = "start",
      col = pal$green[["dark"]],
      size = 20
    ),
    row(svg_repeat_row(0, -95, 95, 0), 290),
    under(1)
  )
  # 2 says where the true answer probably is
  cx <- x0s[2] + w / 2 - 30 # our brick
  sd <- 48
  nd <- cx + 75 # "no difference"
  zs <- seq(-3.2, 3.2, length.out = 97)
  bx2 <- cx + zs * sd
  by2 <- base - 170 * exp(-zs^2 / 2)
  left <- bx2 <= nd
  shade <- sprintf(
    '<path d="M %.1f %g L %s L %.1f %g Z" fill="%s" fill-opacity="0.35" stroke="none"/>',
    bx2[1],
    base,
    paste(
      sprintf(
        "%.1f %.1f",
        c(bx2[left], nd),
        c(by2[left], base - 170 * exp(-((nd - cx) / sd)^2 / 2))
      ),
      collapse = " L "
    ),
    nd,
    base,
    format_col[["text"]]
  )
  p2 <- c(
    shade,
    sprintf(
      '<path d="M %s" fill="none" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>',
      paste(sprintf("%.1f %.1f", bx2, by2), collapse = " L "),
      pal$grey[["dark"]]
    ),
    sprintf(
      '<line x1="%.1f" y1="%g" x2="%.1f" y2="%g" stroke="%s" stroke-width="2.5" stroke-linecap="round"/>',
      x0s[2],
      base,
      x0s[2] + w,
      base,
      note_col
    ),
    sprintf(
      '<line x1="%.1f" y1="120" x2="%.1f" y2="%g" stroke="%s" stroke-width="2" stroke-dasharray="6 5"/>',
      nd,
      nd,
      base + 10,
      note_col
    ),
    svg_note(nd, 104, "no difference", size = 18),
    svg_repeat_row(cx, cx - 1.96 * sd, cx + 1.96 * sd, base),
    sprintf(
      '<g font-weight="700">%s</g>',
      svg_note(
        nd - 10,
        base + 30,
        "&#8592; text: fewer errors",
        anchor = "end",
        col = format_col[["text"]],
        size = 18
      )
    ),
    under(2)
  )
  # 3 uses what we already know: slide 37's prior
  g <- spread_geom
  sv <- seq(0, g$top, length.out = 121)
  pr <- dnorm(sv, 0, 2.2)
  px3 <- x0s[3] + w * sv / g$top
  py3 <- base - 170 * pr / max(pr)
  p3 <- c(
    sprintf(
      '<line x1="%.1f" y1="%g" x2="%.1f" y2="%g" stroke="%s" stroke-width="2.5" stroke-linecap="round"/>',
      x0s[3],
      base,
      x0s[3] + w,
      base,
      note_col
    ),
    sprintf(
      '<path d="M %s" fill="none" stroke="%s" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round"/>',
      paste(sprintf("%.1f %.1f", px3, py3), collapse = " L "),
      pal$green[["fill"]]
    ),
    sprintf(
      '<g font-weight="700">%s</g>',
      svg_note(
        x0s[3] + 0.55 * w,
        base - 150,
        "prior",
        anchor = "start",
        col = pal$green[["dark"]],
        size = 22
      )
    ),
    svg_note(x0s[3], base + 30, "sessions alike", anchor = "start", size = 18),
    svg_note(
      x0s[3] + w,
      base + 30,
      "differ a lot &#8594;",
      anchor = "end",
      size = 18
    ),
    under(3)
  )
  c(
    repeat_frag(p1, frag[1]),
    repeat_frag(p2, frag[2]),
    repeat_frag(p3, frag[3])
  )
}

# Use in a chunk with `#| output: asis`.
show_benefits <- function(frag = 1:3) {
  cat(
    "```{=html}\n",
    '<svg class="brick-dag no-highlight brick-benefits" viewBox="0 85 1200 345" xmlns="http://www.w3.org/2000/svg">',
    paste(benefit_elements(frag), collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- what each piece fixes ----------------------------------------------------
# One tower per problem from "What can go wrong" (slides 6-9) (Matt, 2026-10-09): a grey
# base brick with the problem's technical name and its plain words below,
# and the section bricks that fix it stacked on top in talk order (colours
# and labels as in the section map). One click per section; each click adds
# that section's brick to every tower it fixes. Mapping (handoff 2.9):
#   Bias     <- Building the model (leave out build-1 errors), GLM (each
#               format's answer centres on the true answer, where a
#               transformed model's centres too low; slide 31, Option E,
#               Matt, 2026-10-19; was "no impossible predictions")
#   Variance <- Bayesian (a sensible prior on the format answer, slide 38;
#               Matt, 2026-10-19). Not Multilevel since 2026-10-19 (Matt):
#               partial pooling trades bias for spread in one session's
#               level, not in the instruction answer (300 repeats: centre
#               -0.94 vs -0.93 counting builds, spread 1.79 vs 1.87), so
#               its columns slide was cut
#   Coverage <- Building the model (sessions counted), Multilevel (random
#               intercept), Bayesian (prior on the spread). Not GLM since
#               2026-10-18 (Matt): the "spread grows with the average"
#               picture was cut, so no slide shows it
# Bricks stack as a running bond, as in the
# map; no dimming, so the towers can be compared. viewBox 1200 x 560.
# Plain lines (Matt, 2026-10-17): the summary slide's lines, one per
# problem, its key word bold; one or two lines each. Copied word for word
# from the summary slide (10) as Matt reworded it (2026-10-19). All three
# goals since 2026-10-19 late (Matt; "Bias your answers" read as an
# instruction, "honest" is Coverage's word): centre / vary / cover bold.
fix_towers <- list(
  bias = list(
    name = "Bias",
    plain = 'Answers <tspan font-weight="700">centre</tspan> on the truth',
    fixes = c("build", "glm")
  ),
  variance = list(
    name = "Variance",
    plain = 'Answers <tspan font-weight="700">vary</tspan> no more than they need to',
    fixes = "bayes"
  ),
  coverage = list(
    name = "Coverage",
    plain = c(
      'Plates <tspan font-weight="700">cover</tspan> the truth',
      "as often as they claim"
    ),
    fixes = c("build", "multilevel", "bayes")
  )
)
fix_steps <- c(build = 2, multilevel = 3, glm = 4, bayes = 5) # 1 = the bases

fix_elements <- function() {
  w <- 270
  h <- 76
  sw <- 0.10
  sh <- 16
  d <- (0.16 + sw) * w # shift = left stud's right edge, as in the map
  gap <- 50
  x0s <- (1200 - 3 * (w + d) - 2 * gap) / 2 + (0:2) * (w + d + gap)
  y_base <- 430
  out <- list()
  for (t in seq_along(fix_towers)) {
    ft <- fix_towers[[t]]
    x0 <- x0s[t]
    base <- c(
      svg_brick(
        x0,
        y_base,
        w,
        h,
        "grey",
        ft$name,
        size = 30,
        stud_w = sw,
        stud_h = sh,
        n_studs = 3
      ),
      svg_note(
        x0 + w / 2,
        y_base + h + 30 + 26 * (seq_along(ft$plain) - 1),
        ft$plain,
        size = 22
      )
    )
    out <- c(out, list(el(1, base)))
    # Bottom-up, so each brick is drawn over the studs of the one below;
    # the base sits left, then right, left, ...
    for (k in seq_along(ft$fixes)) {
      s <- map_sections[[ft$fixes[k]]]
      brick <- svg_brick(
        x0 + (k %% 2 == 1) * d,
        y_base - k * h,
        w,
        h,
        s[["col"]],
        s[["label"]],
        size = 22,
        stud_w = sw,
        stud_h = sh,
        n_studs = 3
      )
      out <- c(out, list(el(fix_steps[[ft$fixes[k]]], brick)))
    }
  }
  out
}

# The three towers with their fragments; no dimming. Use in a chunk with
# `#| output: asis`. vb: the viewBox; the recap (slide 42) crops the empty
# band above the tallest tower (top studs at 186, lowest text about 570),
# so its caption fits at the same scale as slide 11.
show_fixes <- function(shown = 1, frag = 2:5, vb = "0 40 1200 560") {
  parts <- render_pieces(fix_elements(), shown, frag)
  cat(
    "```{=html}\n",
    sprintf(
      '<svg class="brick-dag no-highlight brick-fixes" viewBox="%s" xmlns="http://www.w3.org/2000/svg">',
      vb
    ),
    paste(parts[!is.na(parts)], collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- returns: our one dataset, before and after a piece --------------------------
# Back to the problems on slides 6-9, on our one dataset (Matt, 2026-10-09):
# each row is one analysis of the same data, so rows are solid (observed),
# with the true answer as a line. A sketch with no numbers: rows are placed
# by hand, keeping what our data show (handoff section 5), with each miss
# or reach made easy to see.
# A return is a heading (the technical name, "Coverage"; Matt, 2026-10-17)
# and one or two pairs. A pair is one question with its own
# true-answer line and two rows: the problem (step 2), then the fix (step
# 3). at / reach = brick position / plate half-length in units of u px,
# relative to the true answer.
#   coverage (slide 18): learning as two separate piles (plate far too
#     long) -> each person against themselves (short, reaches it); data:
#     -1.82 to +0.29 vs -1.10 to -0.43. Its format pair (120 builds -> 6
#     sessions; data -3.16 to -1.18 vs -5.62 to +1.82, truth -1) was cut
#     (Matt, 2026-10-20): the format plate's point is made on slide 26 only,
#     so one pair, in the one-pair layout.
#   (The build-1 errors return is no longer one dataset: it is a pair of
#   columns of repeats, show_pair("build1_out", "build1_in"), so it can show
#   the bias as well as the coverage; Matt, 2026-10-17.)
return_sets <- list(
  coverage = list(
    head = "Coverage",
    name = NA,
    pairs = list(
      list(
        sub = "Learning",
        u = 60,
        rows = list(
          list(label = "two separate piles", at = 0.25, reach = 1.6),
          list(label = "each person against themselves", at = 0.25, reach = 0.5)
        )
      )
    )
  ),
  # Multilevel's Coverage fix, the last slide of Section 2 (Matt,
  # 2026-10-17: the piece, how it works, then what it fixes; it follows
  # the partial-pooling figure): the model gets the format plate right
  # without counting sessions by hand. Since 2026-10-20 the only return
  # with the format plate (slide 18's format pair cut, Matt). Labelled "Instruction format" so it
  # isn't read as the same answer as the figure (session levels). Data: 120
  # builds -3.16 to -1.18; multilevel (plug-in) -4.57 to +0.61; truth -1.
  # (Partial pooling's bias-for-spread trade is in each session's level, not
  # the format answer, so multilevel has no Variance fix here; its columns
  # slide was cut, Matt 2026-10-19.)
  ml_coverage = list(
    head = "Coverage",
    name = NA,
    pairs = list(
      list(
        sub = "Instruction format",
        u = 40,
        rows = list(
          list(label = "counting 120 builds", at = -1.3, reach = 0.8),
          list(label = "multilevel model", at = -1, reach = 2.6)
        )
      )
    )
  )
)

# Pieces of one return. Steps: 1 heading, subheadings, lines; 2 the
# problem rows; 3 the fixed rows. Two layouts (return_layout):
#   one pair:  600 px, true-answer line at +170, rows either side, labels
#              to the right from +310. The viewBox is cropped to the pair,
#              so it fills the slide at about twice the size.
#   two pairs: 300 px each, labels above their rows, rows centred in the
#              pair; the 600-wide viewBox fills the slide at the same size
#              as one pair (Matt, 2026-10-09: "make the figure bigger"). A
#              label crossing its true-answer line gets an outline in page_bg
#              that breaks the line behind it.
return_layout <- function(n) {
  if (n == 1) {
    list(
      w = 600,
      x_start = 300,
      vb = "300 0 600 300",
      above = FALSE,
      head_y = c(28, 56),
      sub_y = 102,
      line_y = c(120, 262),
      true_y = 282,
      ys = c(165, 230) # plate tops: problem row, fixed row
    )
  } else {
    list(
      w = 300,
      x_start = 0,
      vb = sprintf("0 0 %d 296", 300 * n),
      above = TRUE,
      head_y = c(22, 48),
      sub_y = 84,
      line_y = c(100, 262),
      true_y = 280,
      ys = c(160, 238)
    )
  }
}

# A centred label with an outline in the page colour (drawn under the
# letters), so a line behind it breaks around the text
svg_halo_note <- function(x, y, label, size) {
  sprintf(
    '<text x="%.1f" y="%.1f" text-anchor="middle" dominant-baseline="central" font-size="%d" fill="%s" stroke="%s" stroke-width="7" stroke-linejoin="round" paint-order="stroke">%s</text>',
    x,
    y,
    size,
    note_col,
    page_bg,
    label
  )
}

return_elements <- function(set) {
  r <- return_sets[[set]]
  n <- length(r$pairs)
  L <- return_layout(n)
  x0s <- L$x_start + (seq_len(n) - 1) * L$w
  mid_x <- L$x_start + n * L$w / 2
  out <- list(
    el(
      1,
      c(
        sprintf(
          '<g font-weight="600">%s</g>',
          svg_note(mid_x, L$head_y[1], r$head, size = 24)
        ),
        if (!is.na(r$name)) {
          sprintf(
            '<g font-style="italic">%s</g>',
            svg_note(mid_x, L$head_y[2], r$name, size = 22)
          )
        }
      )
    )
  )
  for (k in seq_len(n)) {
    p <- r$pairs[[k]]
    # labels above: centre the rows' full extent in the pair
    ends <- unlist(lapply(p$rows, function(w) w$at + c(-1, 1) * w$reach))
    tx <- if (L$above) {
      x0s[k] + L$w / 2 - p$u * (min(ends) + max(ends)) / 2
    } else {
      x0s[k] + 170
    }
    out <- c(
      out,
      list(
        el(
          1,
          c(
            if (!is.na(p$sub)) {
              svg_note(
                if (L$above) x0s[k] + L$w / 2 else tx,
                L$sub_y,
                p$sub,
                size = 22
              )
            },
            sprintf(
              '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="3" stroke-linecap="round"/>',
              tx,
              L$line_y[1],
              tx,
              L$line_y[2],
              note_col
            ),
            svg_note(tx, L$true_y, "true answer", size = 18)
          )
        )
      )
    )
    for (j in 1:2) {
      w <- p$rows[[j]]
      a <- tx + p$u * w$at
      y <- L$ys[j]
      label <- if (L$above) {
        svg_halo_note(x0s[k] + L$w / 2, y - 44, w$label, size = 17)
      } else {
        svg_note(x0s[k] + 310, y - 4, w$label, anchor = "start", size = 20)
      }
      out <- c(
        out,
        list(
          el(
            j + 1,
            c(svg_repeat_row(a, a - p$u * w$reach, a + p$u * w$reach, y), label)
          )
        )
      )
    }
  }
  out
}

# Use in a chunk with `#| output: asis`. offset: the number of fragments on
# the slide before the figure's first click (slide 18: the fragment div the
# figure sits in).
show_return <- function(set, shown = 1, frag = 2:3, offset = 0) {
  parts <- render_pieces(return_elements(set), shown, frag, offset)
  cat(
    "```{=html}\n",
    sprintf(
      '<svg class="brick-dag no-highlight brick-return" viewBox="%s" xmlns="http://www.w3.org/2000/svg">',
      return_layout(length(return_sets[[set]]$pairs))$vb
    ),
    paste(parts[!is.na(parts)], collapse = ""),
    "</svg>\n```\n",
    sep = ""
  )
}

# ---- title slide background -------------------------------------------------
# LEGO border for the title slide, after figs/title_background.png with fewer
# bricks (Matt, 2026-10-09): bricks seen from above, palette fills and
# outlines, one stud per grid unit. The deck's page colour shows through
# (the SVG has no background).
# Each corner cluster sits in its own 600 x 350 box (a quarter of the slide)
# pinned to its corner of the screen (preserveAspectRatio), so no brick is
# cropped and the middle stays clear whatever the screen's shape. The outer
# SVG has no size of its own: the slide background stretches it over the
# whole window (data-background-size: 100% 100% in the YAML).
# Bricks are placed by hand in grid units (u = 40) counted from the
# cluster's corner: c from the side edge, r from the top or bottom edge;
# w x h in units.
tb <- function(c, r, w, h, col) data.frame(c, r, w, h, col)
title_corners <- list(
  tl = rbind(
    tb(0, 0, 2, 2, "red"),
    tb(2, 0, 1, 2, "orange"),
    tb(3, 0, 2, 1, "blue"),
    tb(3, 1, 1, 1, "yellow"),
    tb(0, 2, 2, 1, "green"),
    tb(0, 3, 1, 1, "yellow"),
    tb(9, 0, 1, 2, "blue"),
    tb(10, 0, 1, 1, "green")
  ),
  tr = rbind(
    tb(0, 0, 1, 3, "yellow"),
    tb(1, 0, 2, 1, "blue"),
    tb(3, 0, 1, 2, "red"),
    tb(1, 1, 2, 2, "green"),
    tb(4, 0, 1, 1, "orange"),
    tb(0, 3, 1, 1, "blue")
  ),
  bl = rbind(
    tb(0, 0, 2, 2, "orange"),
    tb(2, 0, 2, 1, "yellow"),
    tb(2, 1, 1, 2, "red"),
    tb(4, 0, 1, 1, "green"),
    tb(0, 2, 1, 2, "blue"),
    tb(1, 2, 1, 1, "yellow")
  ),
  br = rbind(
    tb(0, 0, 2, 2, "red"),
    tb(2, 0, 1, 2, "blue"),
    tb(3, 0, 2, 1, "yellow"),
    tb(0, 2, 2, 1, "green"),
    tb(0, 3, 1, 1, "orange"),
    tb(3, 1, 1, 1, "green"),
    tb(9, 0, 2, 1, "orange")
  )
)

# One brick seen from above: body, then per stud a shadow (dark, offset down
# and right) under the stud
svg_top_brick <- function(x, y, w, h, col, u = 40) {
  p <- pal[[col]]
  body <- sprintf(
    '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="3" fill="%s" stroke="%s" stroke-width="1.5"/>',
    x + 0.75,
    y + 0.75,
    w * u - 1.5,
    h * u - 1.5,
    p[["fill"]],
    p[["dark"]]
  )
  cx <- x + (rep(seq_len(w), times = h) - 0.5) * u
  cy <- y + (rep(seq_len(h), each = w) - 0.5) * u
  r <- 0.3 * u
  shadow <- sprintf(
    '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>',
    cx + 0.05 * u,
    cy + 0.07 * u,
    r,
    p[["dark"]]
  )
  stud <- sprintf(
    '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" stroke="%s" stroke-width="1"/>',
    cx,
    cy,
    r,
    p[["fill"]],
    p[["dark"]]
  )
  paste(c(body, shadow, stud), collapse = "")
}

title_bricks <- function(u = 40) {
  qw <- 600
  qh <- 350
  # ax, ay = which side the cluster is pinned to ("Min" = left / top)
  corner <- function(name, ax, ay, x, y) {
    b <- title_corners[[name]]
    bx <- if (ax == "Min") b$c * u else qw - (b$c + b$w) * u
    by <- if (ay == "Min") b$r * u else qh - (b$r + b$h) * u
    bricks <- mapply(
      svg_top_brick,
      bx,
      by,
      b$w,
      b$h,
      b$col,
      MoreArgs = list(u = u)
    )
    sprintf(
      '<svg x="%s" y="%s" width="50%%" height="50%%" viewBox="0 0 %d %d" preserveAspectRatio="x%sY%s meet">%s</svg>',
      x,
      y,
      qw,
      qh,
      ax,
      ay,
      paste(bricks, collapse = "")
    )
  }
  paste0(
    '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%">',
    corner("tl", "Min", "Min", "0", "0"),
    corner("tr", "Max", "Min", "50%", "0"),
    corner("bl", "Min", "Max", "0", "50%"),
    corner("br", "Max", "Max", "50%", "50%"),
    "</svg>"
  )
}

# Called from the deck's setup chunk, so the file is written at render
save_title_bricks <- function(file = file.path("figs", "title_bricks.svg")) {
  dir.create(dirname(file), showWarnings = FALSE)
  writeLines(title_bricks(), file)
}
