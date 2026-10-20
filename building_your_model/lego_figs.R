# lego_figs.R ------------------------------------------------------------------
# Data figures for the LEGO running example (Oct 20 workshop):
#   seq_b_cloud_plots()  B as distributions (in the deck, Matt 2026-10-09)
#   seq_b_plots()   B: 120 builds vs 12 sessions, columns (parked, kept)
#   seq_a_plots()   A: the same session, building twice (not in the deck)
#   shrink_plots()  partial pooling (session estimates pulled to their format)
# Spec and backstage numbers: SIMULATIONS_lego_example.md. One dataset
# (seed 503, 6 sessions) feeds them all.
#
# How it works
# - Each figure is a list of ggplots, one per click, on fixed scales, so
#   nothing moves between clicks except what the click changes.
#   show_steps() saves them as SVGs in figs/ and stacks them (.r-stack):
#   image k > 1 fades in over image k - 1 at fragment index k - 1 (opaque
#   backgrounds in page_bg). Captions sit in the slide (.dag-note) with the same
#   fragment indices.
# - No numbers on slides: no ticks or values, words only; design counts are
#   fine. Colours from `pal` / `format_col` (source brick_dag.R first):
#   naive analysis red, correct analysis blue, multilevel estimates yellow
#   (the random-intercept colour); raw data, labels and reference lines in
#   ink (= note_col, the palette's dark blue). Fading = transparency
#   of the same colour; no new colours.
# ---------------------------------------------------------------------------

library(ggplot2)
library(patchwork)

fig_font <- "sans"
fig_dir <- "figs"
ink <- note_col # raw data, format averages
fade <- 0.2 # alpha for pieces pushed into the background

# ---- data -------------------------------------------------------------------
# sim_lego as in SIMULATIONS_lego_example.md; u_s (the true session effect) is
# kept as a column, which does not change the random draws.
sim_lego <- function(
  seed,
  sizes,
  b0 = 8,
  b_format = -1,
  b_learn = -1,
  sd_session = 2,
  sd_person = 2,
  sd_resid = 1
) {
  set.seed(seed)
  n_sessions <- length(sizes)
  format <- rep(0:1, each = n_sessions / 2) # first half picture, second text
  rows <- lapply(seq_len(n_sessions), function(s) {
    u_s <- rnorm(1, 0, sd_session)
    do.call(
      rbind,
      lapply(seq_len(sizes[s]), function(p) {
        u_p <- rnorm(1, 0, sd_person)
        data.frame(
          session = s,
          participant = paste0(s, "_", p),
          format = format[s],
          build = 0:1,
          u_s = u_s,
          errors = pmax(
            0,
            round(
              b0 +
                b_format * format[s] +
                b_learn * (0:1) +
                u_s +
                u_p +
                rnorm(2, 0, sd_resid)
            )
          )
        )
      })
    )
  })
  do.call(rbind, rows)
}

# 6 sessions, 3 per format (Matt, 2026-10-09; was 12): 30 + 30 = 60 people,
# 120 builds. Unequal sizes so shrinkage shows (4 vs 16). Seed 503 chosen in
# the 2026-10-09 search (HANDOFF_brick_dag_2026-10-19_evening.md section 5): 120-builds interval below zero,
# 6-sessions interval across it, the two differences within 0.3, sessions
# spread in both formats, all six improve from build 1 to 2, and the
# smallest session starts closer to its format's average than the biggest
# but is pulled further.
lego_sizes <- c(4, 16, 10, 14, 6, 10)
lego <- sim_lego(seed = 503, sizes = lego_sizes)

# ---- shared pieces ----------------------------------------------------------

fig_theme <- function() {
  theme_void(base_size = 18, base_family = fig_font) +
    theme(
      plot.background = element_rect(fill = page_bg, colour = NA),
      axis.title.y = element_text(
        angle = 90,
        colour = ink,
        margin = margin(r = 8)
      ),
      plot.title = element_text(
        hjust = 0.5,
        colour = ink,
        size = 18,
        margin = margin(b = 6)
      ),
      plot.caption = element_text(colour = ink, size = 12),
      plot.margin = margin(8, 14, 8, 14),
      legend.position = "none"
    )
}

# One interval: a thick line and its point estimate, labelled underneath
fig_interval <- function(x, lo, hi, est, col, label, label_y) {
  list(
    annotate(
      "segment",
      x = x,
      xend = x,
      y = lo,
      yend = hi,
      colour = col,
      linewidth = 2.6,
      lineend = "round"
    ),
    annotate("point", x = x, y = est, colour = col, size = 5),
    annotate(
      "text",
      x = x,
      y = label_y,
      label = label,
      colour = col,
      size = 5.6,
      family = fig_font,
      lineheight = 0.9
    )
  )
}

# Dashed reference line with a word label at its right end
fig_zero <- function(x_right, label, y = 0) {
  list(
    annotate(
      "segment",
      x = -Inf,
      xend = Inf,
      y = y,
      yend = y,
      linetype = "dashed",
      colour = ink,
      linewidth = 0.7
    ),
    annotate(
      "text",
      x = x_right,
      y = y + 0.45,
      label = label,
      hjust = 1,
      colour = ink,
      size = 4.6,
      family = fig_font
    )
  )
}

# Saves one SVG per click and stacks them. Use in a chunk with
# `#| output: asis`. The ?v= stamp stops the browser showing a cached image
# after a re-render.
show_steps <- function(name, plots, width = 11.5, height = 4.9) {
  dir.create(fig_dir, showWarnings = FALSE)
  files <- sprintf("%s/%s_%d.svg", fig_dir, name, seq_along(plots))
  for (i in seq_along(plots)) {
    ggsave(
      files[i],
      plots[[i]],
      width = width,
      height = height,
      device = svglite::svglite,
      bg = page_bg
    )
  }
  n <- length(files)
  frag <- c(
    "",
    sprintf(' class="fragment" data-fragment-index="%d"', seq_len(n - 1))
  )
  imgs <- sprintf(
    '<img src="%s?v=%s" alt=""%s>',
    files,
    format(Sys.time(), "%Y%m%d%H%M%S"),
    frag
  )
  cat(
    "```{=html}\n",
    '<div class="r-stack lego-fig">',
    paste(imgs, collapse = ""),
    "</div>\n```\n",
    sep = ""
  )
}

# ---- B: 120 builds vs 12 sessions ---------------------------------------------
# Left: errors per build by format. Right: the difference text - picture with
# a dashed "no difference" line. Clicks (images 1-4):
#   1 builds by format, format averages; the 120-builds interval (red)
#   2 session columns (plates in the format greys) appear behind the builds
# Builds sit at their session's position from the start, so no dot moves
# between clicks; a click only adds structure around them (Matt, 2026-10-09).
#   3 one average per session (blue); builds fade
#   4 the 12-sessions interval (blue) beside the red one
# The red interval is on from the start (the spec had both at step 4): with no
# numbers on the slide, it is what makes "looks convincing" visible.
# PARKED and written for the 12-session design: its layout (columns 1-13,
# six per format) needs reworking before reuse with 6 sessions.
seq_b_plots <- function(d = lego) {
  set.seed(11)
  d$slot <- d$session + d$format # picture 1-6, text 8-13 (gap at 7)
  d$x_col <- d$slot + runif(nrow(d), -0.3, 0.3)
  d$y <- d$errors + runif(nrow(d), -0.22, 0.22) # integers overlap otherwise
  grp <- data.frame(
    x0 = c(0.55, 7.55),
    x1 = c(6.45, 13.45),
    mid = c(3.5, 10.5),
    mean = as.numeric(tapply(d$errors, d$format, mean)),
    label = c("Picture", "Text")
  )
  sm <- aggregate(errors ~ session + format, data = d, FUN = mean)
  sm$slot <- sm$session + sm$format
  cols <- data.frame(
    xmin = sm$slot - 0.42,
    xmax = sm$slot + 0.42,
    fill = format_col[sm$format + 1]
  )
  naive <- t.test(errors ~ factor(format, levels = 1:0), data = d)
  sess <- t.test(
    errors ~ factor(format, levels = 1:0),
    data = sm,
    var.equal = TRUE
  )

  left <- function(k) {
    p <- ggplot()
    if (k >= 2) {
      p <- p +
        geom_rect(
          data = cols,
          aes(xmin = xmin, xmax = xmax, ymin = -0.5, ymax = 15.9),
          fill = cols$fill,
          alpha = 0.5
        )
    }
    p <- p +
      geom_point(
        data = d,
        aes(x = x_col, y = y),
        colour = ink,
        alpha = if (k >= 3) fade else 0.75,
        size = 2.2
      ) +
      geom_segment(
        data = grp,
        aes(x = x0, xend = x1, y = mean, yend = mean),
        colour = ink,
        linewidth = 1.6,
        alpha = if (k >= 3) 0.5 else 1
      ) +
      annotate(
        "text",
        x = grp$mid,
        y = -1.4,
        label = grp$label,
        colour = ink,
        size = 6.2,
        family = fig_font
      )
    if (k >= 3) {
      p <- p +
        geom_point(
          data = sm,
          aes(slot, errors),
          colour = pal$blue[["fill"]],
          size = 6
        )
    }
    p +
      scale_x_continuous(limits = c(0.3, 13.7)) +
      scale_y_continuous(limits = c(-2, 16)) +
      coord_cartesian(clip = "off") +
      labs(y = "Errors per build") +
      fig_theme()
  }

  right <- function(k) {
    p <- ggplot() +
      fig_zero(3.3, "no difference") +
      fig_interval(
        1,
        naive$conf.int[1],
        naive$conf.int[2],
        diff(rev(naive$estimate)),
        pal$red[["fill"]],
        "120\nbuilds",
        -5
      )
    if (k >= 4) {
      p <- p +
        fig_interval(
          2,
          sess$conf.int[1],
          sess$conf.int[2],
          diff(rev(sess$estimate)),
          pal$blue[["fill"]],
          "12\nsessions",
          -5
        )
    }
    p +
      scale_x_continuous(limits = c(0.4, 3.3)) +
      scale_y_continuous(limits = c(-5.8, 2.6)) +
      coord_cartesian(clip = "off") +
      labs(title = "Difference between formats", y = NULL) +
      fig_theme()
  }

  lapply(1:4, function(k) {
    left(k) +
      right(k) +
      plot_layout(widths = c(2.6, 1)) +
      plot_annotation(
        caption = "One simulated dataset, chosen to show the idea",
        theme = fig_theme()
      )
  })
}

# ---- B, simplified: distributions (in the deck since 2026-10-09) -----------------
# Matt, 2026-10-09: replaces seq_b_plots() on the slide (kept above in case
# the columns version comes back). One horizontal axis, errors per build (no
# values), laid out like a raincloud: the formats' curves in the middle, the
# difference curve above them, the sessions as small curves underneath.
# Clicks (images 1-4; Matt, 2026-10-09: one piece per click):
#   1 the two formats as normal curves (picture blue, text green, means
#     marked)
#   2 above them, the difference of the means as a small normal curve (red:
#     builds counted as 120 separate pieces of evidence), with its "no
#     difference" line (drawn only within the difference band)
#   3 each session as its own small curve underneath (3 picture, 3 text;
#     pooled within-session spread), its average a yellow bar (a circle
#     read as something else)
#   4 the 6 session averages as the data: the difference curve grows wider
#     (yellow); the red one and the session curves fade, the averages stay
# Colours (Matt, 2026-10-09): picture blue, text green (format_col);
# everything session-level yellow; no "simulated dataset" footnote (it is
# in the speaker notes).
# The difference is drawn on the errors axis, anchored so that "no
# difference" is the picture mean (dashed line), as in a Gardner-Altman
# estimation plot; its spread is the standard error. Curves in a layer are
# equal-area, so the wider difference curve is also lower.
# Seed 503: standard error 0.50 (120 builds) vs 1.34 (6 session means).
seq_b_cloud_plots <- function(d = lego) {
  fm <- tapply(d$errors, d$format, mean)
  fsd <- tapply(d$errors, d$format, sd)
  sm <- aggregate(errors ~ session + format, data = d, FUN = mean)
  naive <- t.test(errors ~ factor(format, levels = 1:0), data = d)
  sess <- t.test(
    errors ~ factor(format, levels = 1:0),
    data = sm,
    var.equal = TRUE
  )
  anchor <- fm[["0"]] # picture mean = "no difference"
  within_sd <- sqrt(
    sum(tapply(d$errors, d$session, function(e) sum((e - mean(e))^2))) /
      (nrow(d) - nrow(sm))
  )
  xlim <- range(c(fm - 3 * fsd, fm + 3 * fsd))
  fcol <- format_col[c("picture", "text")] # by format 0, 1
  ycol <- pal$yellow # session level: averages and the sessions' answer

  # One bell curve as a ribbon on y = base: centre m, spread s, drawn out to
  # `trim` spreads either side (so small curves don't run across the width)
  bell <- function(m, s, base, peak, trim = Inf) {
    x <- seq(
      max(xlim[1], m - trim * s),
      min(xlim[2], m + trim * s),
      length.out = 300
    )
    data.frame(
      x = x,
      ymin = base,
      ymax = base + peak * exp(-0.5 * ((x - m) / s)^2)
    )
  }
  fill_of <- function(df, fill, alpha) {
    geom_ribbon(
      data = df,
      aes(x = x, ymin = ymin, ymax = ymax),
      fill = fill,
      alpha = alpha
    )
  }
  line_of <- function(df, col, alpha = 1) {
    geom_line(
      data = df,
      aes(x = x, y = ymax),
      colour = col,
      linewidth = 0.9,
      alpha = alpha
    )
  }

  # Layers (y): difference band from 8.6, formats 5.4-8.0, sessions below
  # with a gap (three picture rows, then three text rows, tops under 5.0).
  # Peaks are equal-area within a layer: peak ~ 1 / spread.
  fmt_base <- 5.4
  fmt <- lapply(c("0", "1"), function(f) {
    bell(fm[[f]], fsd[[f]], fmt_base, 2.6 * min(fsd) / fsd[[f]])
  })
  eff_base <- 8.6
  eff <- list(
    naive = bell(
      anchor + diff(rev(naive$estimate)),
      naive$stderr,
      eff_base,
      1.3,
      trim = 4
    ),
    sess = bell(
      anchor + diff(rev(sess$estimate)),
      sess$stderr,
      eff_base,
      1.3 * naive$stderr / sess$stderr,
      trim = 4
    )
  )
  ses_peak <- 0.6
  rows <- c(4.4, 3.75, 3.1, 2.2, 1.55, 0.9)
  sm$base <- rows[order(order(sm$format, sm$session))]
  ses <- lapply(seq_len(nrow(sm)), function(r) {
    bell(sm$errors[r], within_sd, sm$base[r], ses_peak, trim = 2.5)
  })
  # half-width of a session's yellow bar (Matt, 2026-10-09: narrower)
  bar_w <- 0.0005 * diff(xlim)

  # k = 1 formats; 2 + difference (120 builds); 3 + sessions; 4 + the
  # sessions' wider difference
  lapply(1:4, function(k) {
    p <- ggplot() +
      annotate(
        "text",
        x = xlim[1] - 0.04 * diff(xlim),
        y = c(eff_base + 0.5, mean(rows[1:3]), mean(rows[4:6])),
        label = c("Difference", "Picture\nsessions", "Text\nsessions"),
        hjust = 1,
        colour = c(ink, fcol),
        size = 5.4,
        family = fig_font,
        lineheight = 0.9,
        alpha = c(if (k >= 2) 1 else 0, rep(if (k >= 3) 1 else 0, 2))
      )
    # formats: both fills, then both outlines and means on top
    p <- p +
      fill_of(fmt[[2]], fcol[[2]], 0.28) +
      fill_of(fmt[[1]], fcol[[1]], 0.28) +
      line_of(fmt[[2]], fcol[[2]]) +
      line_of(fmt[[1]], fcol[[1]]) +
      annotate(
        "segment",
        x = fm,
        xend = fm,
        y = fmt_base,
        yend = sapply(fmt, function(f) max(f$ymax)),
        colour = fcol,
        linewidth = 1
      ) +
      annotate(
        "text",
        x = c(fm[["0"]] + 2.3 * fsd[["0"]], fm[["1"]] - 2.3 * fsd[["1"]]),
        y = fmt_base + 0.8,
        label = c("Picture", "Text"),
        hjust = c(0, 1),
        colour = fcol,
        size = 6.6,
        family = fig_font
      )
    # difference: "no difference" only within its own band (drawn up from
    # the picture mean it read as part of that mean, Matt 2026-10-09), the
    # 120-builds curve (red), then the 6 session averages (yellow)
    if (k >= 2) {
      p <- p +
        annotate(
          "segment",
          x = anchor,
          xend = anchor,
          y = eff_base - 0.15,
          yend = 10.05,
          linetype = "dashed",
          colour = ink,
          linewidth = 0.7
        ) +
        annotate(
          "text",
          x = anchor + 0.2,
          y = 9.7,
          label = "no difference",
          hjust = 0,
          colour = ink,
          size = 5,
          family = fig_font
        ) +
        fill_of(eff$naive, pal$red[["fill"]], if (k == 4) 0.12 else 0.35) +
        line_of(eff$naive, pal$red[["fill"]], if (k == 4) 0.35 else 1)
    }
    if (k == 4) {
      p <- p +
        fill_of(eff$sess, ycol[["fill"]], 0.45) +
        line_of(eff$sess, ycol[["dark"]])
    }
    # sessions underneath as soft fills in their format's colour, top row
    # first so lower rows overlap it; each session's average a yellow bar
    if (k >= 3) {
      for (r in seq_len(nrow(sm))) {
        p <- p +
          fill_of(
            ses[[r]],
            fcol[[sm$format[r] + 1]],
            if (k == 4) 0.08 else 0.22
          )
      }
      p <- p +
        geom_rect(
          data = sm,
          aes(
            xmin = errors - bar_w,
            xmax = errors + bar_w,
            ymin = base,
            ymax = base + ses_peak
          ),
          fill = ycol[["fill"]],
          colour = ycol[["fill"]],
          linewidth = 0.6
        )
    }
    p +
      annotate(
        "text",
        x = xlim[2],
        y = 0.15,
        label = paste("more errors", intToUtf8(0x2192)),
        hjust = 1,
        colour = ink,
        size = 5,
        family = fig_font
      ) +
      coord_cartesian(xlim = xlim, ylim = c(0, 10.2), clip = "off") +
      labs(y = NULL) +
      fig_theme() +
      theme(plot.margin = margin(8, 14, 8, 120))
  })
}

# ---- A: the same session, building twice -----------------------------------------
# NOT IN THE DECK (Matt, 2026-10-09): sequence A is explained on the DAG
# alone. Kept in case it comes back.
# Left: errors per build; build 1 open circles, build 2 filled. Right: each
# session's change (build 2 - build 1) on the SAME scale as the left (equal
# y span), so the tight cluster is visibly narrower. Clicks (images 1-5):
#   1 all builds with the build-1 average (dashed) and build-2 average (solid)
#   2 session columns (ordered low to high) appear behind the builds
#   3 each session's build-1 average joined to its build-2 average (blue)
#   4 only the changes: right panel fills, left fades
#   5 two intervals: 120 builds (red) vs each session against itself (blue)
# As in B, builds sit at their session's position from the start (build 1 on
# the left of each column, build 2 on the right), so no dot moves between
# clicks (Matt, 2026-10-09). The naive comparison is shown by its two average
# lines rather than as two piles.
# Written for the 12-session design: rework the layout before reuse.
seq_a_plots <- function(d = lego) {
  set.seed(12)
  rank <- rank(tapply(d$errors, d$session, mean), ties.method = "first")
  d$slot <- rank[as.character(d$session)]
  d$x_col <- d$slot +
    ifelse(d$build == 0, -0.2, 0.2) +
    runif(nrow(d), -0.1, 0.1)
  d$y <- d$errors + runif(nrow(d), -0.22, 0.22)
  avg <- data.frame(
    mean = as.numeric(tapply(d$errors, d$build, mean)),
    lty = c("dashed", "solid")
  )
  m <- aggregate(errors ~ session + build, data = d, FUN = mean)
  m <- reshape(m, idvar = "session", timevar = "build", direction = "wide")
  m$slot <- rank[as.character(m$session)]
  m$change <- m$errors.1 - m$errors.0
  builds_ci <- t.test(errors ~ factor(build, levels = 1:0), data = d)
  sess_ci <- t.test(m$change)
  shape <- c(`0` = 21, `1` = 16) # build 1 open, build 2 filled

  left <- function(k) {
    a <- if (k >= 4) fade else 1 # whole panel steps back at click 4
    p <- ggplot()
    if (k >= 2) {
      p <- p +
        annotate(
          "rect",
          xmin = 1:12 - 0.42,
          xmax = 1:12 + 0.42,
          ymin = -0.5,
          ymax = 15.9,
          fill = "#D2D2D2", # neutral column backing (parked figure)
          alpha = 0.5 * a
        )
    }
    p <- p +
      geom_point(
        data = d,
        aes(x = x_col, y = y, shape = factor(build)),
        colour = ink,
        fill = page_bg, # hollow marker
        stroke = 1,
        alpha = if (k >= 3) fade * a else 0.75,
        size = 2.2
      ) +
      scale_shape_manual(values = shape)
    # the naive comparison: one average per build across all 120 builds
    if (k <= 2) {
      p <- p +
        annotate(
          "segment",
          x = 0.55,
          xend = 12.45,
          y = avg$mean,
          yend = avg$mean,
          linetype = avg$lty,
          colour = ink,
          linewidth = 1.4,
          alpha = if (k == 2) 0.5 else 1
        )
    }
    # key: marker and average-line style per build
    p <- p +
      annotate(
        "point",
        x = c(3.4, 7.4),
        y = -1.4,
        shape = c(21, 16),
        colour = ink,
        fill = page_bg, # hollow marker
        stroke = 1,
        size = 3,
        alpha = a
      ) +
      annotate(
        "segment",
        x = c(3.7, 7.7),
        xend = c(4.5, 8.5),
        y = -1.4,
        yend = -1.4,
        linetype = avg$lty,
        colour = ink,
        linewidth = 1.1,
        alpha = a
      ) +
      annotate(
        "text",
        x = c(4.7, 8.7),
        y = -1.4,
        label = c("build 1", "build 2"),
        hjust = 0,
        colour = ink,
        size = 5.6,
        family = fig_font,
        alpha = a
      )
    if (k >= 3) {
      p <- p +
        geom_segment(
          data = m,
          aes(x = slot - 0.2, xend = slot + 0.2, y = errors.0, yend = errors.1),
          colour = pal$blue[["fill"]],
          linewidth = 1.6,
          alpha = a
        ) +
        geom_point(
          data = m,
          aes(slot - 0.2, errors.0),
          shape = 21,
          fill = page_bg, # hollow marker
          colour = pal$blue[["fill"]],
          stroke = 1.6,
          size = 3.6,
          alpha = a
        ) +
        geom_point(
          data = m,
          aes(slot + 0.2, errors.1),
          colour = pal$blue[["fill"]],
          size = 3.6,
          alpha = a
        )
    }
    p +
      scale_x_continuous(limits = c(0.3, 12.7)) +
      scale_y_continuous(limits = c(-2, 16)) +
      coord_cartesian(clip = "off") +
      labs(y = "Errors per build") +
      fig_theme()
  }

  # Same y span as the left panel (18), centred on zero
  right <- function(k) {
    p <- ggplot() + fig_zero(4.6, "no change")
    if (k >= 4) {
      set.seed(13)
      p <- p +
        geom_point(
          data = m,
          aes(x = 1 + runif(nrow(m), -0.2, 0.2), y = change),
          colour = pal$blue[["fill"]],
          size = 3.6
        )
    }
    if (k >= 5) {
      p <- p +
        fig_interval(
          2,
          builds_ci$conf.int[1],
          builds_ci$conf.int[2],
          diff(rev(builds_ci$estimate)),
          pal$red[["fill"]],
          "120\nbuilds",
          -5.5
        ) +
        fig_interval(
          3.4,
          sess_ci$conf.int[1],
          sess_ci$conf.int[2],
          sess_ci$estimate,
          pal$blue[["fill"]],
          "session vs\nitself",
          -5.5
        )
    }
    p +
      scale_x_continuous(limits = c(0.4, 4.6)) +
      scale_y_continuous(limits = c(-9, 9)) +
      coord_cartesian(clip = "off") +
      labs(title = "Change from build 1 to build 2", y = NULL) +
      fig_theme()
  }

  lapply(1:5, function(k) {
    left(k) +
      right(k) +
      plot_layout(widths = c(2.2, 1)) +
      plot_annotation(
        caption = "One simulated dataset, chosen to show the idea",
        theme = fig_theme()
      )
  })
}

# ---- partial pooling (shrinkage) ---------------------------------------------------
# Each session's own average vs the multilevel model's estimate for it
# (errors ~ format + build + (1 | session) + (1 | participant), at the
# average build). Sessions sit in their format block (a tint of the format's
# colour), as in B; the dashed line is the model's format average. Circle
# size = session size. Layout follows the number of sessions.
# Clicks (images 1-3):
#   1 each session's own average (open circles)
#   2 the model's estimates (yellow), each pulled toward its format average
#   3 only the smallest and the biggest session: the small one moves further
#     although it started closer to the average
# Seed 503 (6 sessions): the 4-person session is pulled 43% of the way, the
# 16-person one 16%; both are picture sessions, and the small one starts
# closer. After McElreath (Statistical Rethinking).
shrink_plots <- function(d = lego, sizes = lego_sizes) {
  fit <- lme4::lmer(
    errors ~ format + build + (1 | session) + (1 | participant),
    data = d
  )
  fe <- lme4::fixef(fit)
  re <- lme4::ranef(fit)$session[, 1]
  s <- aggregate(errors ~ session + format, data = d, FUN = mean)
  s$n <- sizes
  n_per <- nrow(s) / 2
  s$slot <- s$session + s$format # picture 1..n_per, text after a gap
  s$line <- fe[[1]] + fe[[2]] * s$format + fe[[3]] * 0.5
  s$ml <- s$line + re
  s$focus <- s$n %in% range(s$n)
  blocks <- data.frame(
    xmin = c(0.5, n_per + 1.5),
    xmax = c(n_per + 0.5, 2 * n_per + 1.5),
    mid = c((n_per + 1) / 2, (3 * n_per + 3) / 2),
    line = unique(s$line),
    col = format_col[c("picture", "text")],
    label = c("Picture", "Text")
  )
  ylim <- range(c(s$errors, s$ml)) + c(-1, 1)

  lapply(1:3, function(k) {
    a <- if (k == 3) ifelse(s$focus, 1, 0.15) else rep(1, nrow(s))
    p <- ggplot() +
      geom_rect(
        data = blocks,
        aes(xmin = xmin, xmax = xmax, ymin = ylim[1], ymax = ylim[2]),
        fill = blocks$col,
        alpha = 0.15
      ) +
      geom_segment(
        data = blocks,
        aes(x = xmin + 0.1, xend = xmax - 0.1, y = line, yend = line),
        colour = blocks$col,
        linetype = "dashed",
        linewidth = 1
      ) +
      annotate(
        "text",
        x = blocks$mid,
        y = ylim[1] - 0.45,
        label = blocks$label,
        colour = blocks$col,
        size = 6.6,
        family = fig_font
      )
    if (k >= 2) {
      p <- p +
        geom_segment(
          data = s,
          aes(x = slot, xend = slot, y = errors, yend = ml),
          colour = pal$yellow[["dark"]],
          linewidth = 1.4,
          alpha = a
        )
    }
    p <- p +
      geom_point(
        data = s,
        aes(slot, errors, size = n),
        shape = 21,
        fill = page_bg, # hollow marker
        colour = ink,
        stroke = 1.4,
        alpha = if (k >= 2) a * 0.6 else a
      )
    if (k >= 2) {
      p <- p +
        geom_point(
          data = s,
          aes(slot, ml, size = n),
          shape = 21,
          fill = pal$yellow[["fill"]],
          colour = pal$yellow[["dark"]],
          stroke = 1.2,
          alpha = a
        )
    }
    p +
      scale_size(range = c(3, 9)) +
      coord_cartesian(
        xlim = c(0.3, 2 * n_per + 1.7),
        ylim = ylim,
        clip = "off"
      ) +
      labs(
        y = "Session's average errors" #,
        #caption = "After McElreath, Statistical Rethinking"
      ) +
      fig_theme() +
      # The format labels sit under the blocks, outside the panel: the
      # bottom margin makes room for them (the credit line used to; since
      # 2026-10-09 the credit sits beside the slide number instead, via
      # brick_dag.css); the caption margin keeps a restored credit line
      # clear of them
      theme(
        plot.caption = element_text(margin = margin(t = 26)),
        plot.margin = margin(8, 14, 40, 14)
      )
  })
}
