"""
T-test Trap Presentation  ·  plain-language Manim version
==========================================================
Render:   manim-slides render ttest_slides.py TTestTrap
Present:  manim-slides present TTestTrap

Clip structure note: every slide that has multiple clips avoids sandwiching
short-duration clips between longer ones — PyAV 16 / FFmpeg 7's concat demuxer
fails with EINVAL when a 1-frame intermediate clip is present.
  - Heading `self.add()` calls carry NO wait; the heading appears at the start
    of the first following animation.
  - Terminal `self.wait()` calls (directly before next_slide) use 0.5 s to
    guarantee ≥ 30 frames and a valid DTS range for the concat muxer.
"""

from manim import *
from manim_slides import Slide
import numpy as np

# ── bell-curve constants ──────────────────────────────────────────────────────
MEAN_A     = -2.0
MEAN_B     =  2.0
SIGMA_LOW  =  0.6
SIGMA_HIGH =  1.5
CURVE_BASE = -2.0   # y-position of the distribution baseline

# Scale so peak = 1.8 manim units above CURVE_BASE when sigma == SIGMA_LOW
C_NORM = SIGMA_LOW * np.sqrt(2 * np.pi) * 1.8


def bell(x, mu, sigma):
    """Gaussian PDF scaled for visual clarity."""
    return (
        C_NORM
        * np.exp(-0.5 * ((x - mu) / sigma) ** 2)
        / (sigma * np.sqrt(2 * np.pi))
        + CURVE_BASE
    )


# ── presentation ─────────────────────────────────────────────────────────────

class TTestTrap(Slide):

    def construct(self):

        # ════════════════════════════════════════════════════════════════════
        # Slide 1 — Title
        # ════════════════════════════════════════════════════════════════════
        title = Text("The Panadol Problem", font_size=60, weight=BOLD)
        sub   = Text(
            "Why the t-test shouldn't be your first choice",
            font_size=30, color=GRAY_B,
        )
        VGroup(title, sub).arrange(DOWN, buff=0.5).center()
        self.play(FadeIn(title), FadeIn(sub))
        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 2 — The Reflex
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(title, sub))

        heading2 = Text("The reflex", font_size=40, weight=BOLD).to_edge(UP, buff=0.5)
        self.add(heading2)
        # No wait here — heading appears at the start of the first FadeIn clip.

        reflex_lines = [
            Text("You have a headache.", font_size=34),
            Text("You reach for Panadol.", font_size=34, color=YELLOW_B),
            Text(
                "You didn't diagnose anything.  You didn't rule anything out.",
                font_size=28, color=GRAY_B,
            ),
            Text("It was just... the thing you reach for.", font_size=32),
        ]
        VGroup(*reflex_lines).arrange(DOWN, buff=0.5).center().shift(DOWN * 0.3)
        for mob in reflex_lines:
            mob.scale_to_fit_width(config.frame_width - 2.0)

        for mob in reflex_lines:
            self.play(FadeIn(mob, shift=DOWN * 0.2))
            self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 3 — That's the t-test
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(heading2, *reflex_lines))

        heading3 = Text("That's the t-test", font_size=40, weight=BOLD).to_edge(UP, buff=0.5)
        self.add(heading3)

        analogy_lines = [
            Text("Two groups.  Any question.  Any data.", font_size=34),
            Text("\"I'll just run a t-test.\"", font_size=36, color=YELLOW_B),
            Text(
                "Panadol works for one specific type of pain.\n"
                "The t-test works for one very specific type of data.",
                font_size=28, color=GRAY_B, line_spacing=1.3,
            ),
        ]
        VGroup(*analogy_lines).arrange(DOWN, buff=0.55).center().shift(DOWN * 0.2)
        for mob in analogy_lines:
            mob.scale_to_fit_width(config.frame_width - 2.0)

        for mob in analogy_lines:
            self.play(FadeIn(mob, shift=DOWN * 0.2))
            self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 4 — What the t-test needs
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(heading3, *analogy_lines))

        heading4 = Text("What the t-test needs", font_size=40, weight=BOLD).to_edge(UP, buff=0.5)
        self.add(heading4)

        assumptions = [
            "Normally distributed data",
            "Equal variance in both groups",
            "Truly independent observations",
            "Continuous measurements",
        ]
        rows4 = VGroup()
        for text in assumptions:
            check = Text("✓", font_size=28, color=GREEN_C)
            label = Text(text, font_size=28)
            rows4.add(VGroup(check, label).arrange(RIGHT, buff=0.3))
        rows4.arrange(DOWN, aligned_edge=LEFT, buff=0.4).center().shift(DOWN * 0.4)

        for row in rows4:
            self.play(FadeIn(row, shift=RIGHT * 0.3))
            self.next_slide()

        all_label = Text(
            "All of them.  At the same time.",
            font_size=30, color=YELLOW_B, weight=BOLD,
        ).next_to(rows4, DOWN, buff=0.5)
        self.play(FadeIn(all_label, shift=DOWN * 0.2))
        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 5 — What happens when violated
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(heading4, rows4, all_label))

        heading5 = Text(
            "What happens when they're violated",
            font_size=40, weight=BOLD,
        ).to_edge(UP, buff=0.5)
        self.add(heading5)

        violations = [
            ("Non-normality",       "→  unreliable p-values with small samples"),
            ("Unequal variance",    "→  inflated false positive rate"),
            ("Non-independence",    "→  your n is smaller than you think"),
            ("Count / proportion",  "→  the model is simply wrong"),
        ]
        rows5 = VGroup()
        for label, consequence in violations:
            l_mob = Text(label,       font_size=27, color=RED_C,  weight=BOLD)
            c_mob = Text(consequence, font_size=27, color=GRAY_B)
            rows5.add(VGroup(l_mob, c_mob).arrange(RIGHT, buff=0.3))
        rows5.arrange(DOWN, aligned_edge=LEFT, buff=0.4).center().shift(DOWN * 0.2)

        for row in rows5:
            self.play(FadeIn(row, shift=RIGHT * 0.3))
            self.next_slide()

        warning5 = Text(
            "The t-test doesn't warn you.  It just gives you a number.",
            font_size=28, color=YELLOW_B, weight=BOLD,
        ).next_to(rows5, DOWN, buff=0.45)
        warning5.scale_to_fit_width(config.frame_width - 2.0)
        self.play(FadeIn(warning5, shift=DOWN * 0.2))
        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 6 — The Variance Problem  (KEY ANIMATION)
        # Shows two bell curves: same mean difference, variance grows →
        # distributions overlap → t-test denominator bloats.
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(heading5, rows5, warning5))

        heading6 = Text(
            "Even when it's valid, there's a problem",
            font_size=40, weight=BOLD,
        ).to_edge(UP, buff=0.5)
        framing6 = Text(
            "The t-test sees one source of variation —\n"
            "the difference between your two groups.",
            font_size=32, line_spacing=1.3,
        ).center()
        framing6.scale_to_fit_width(config.frame_width - 2.0)
        self.add(heading6, framing6)
        self.wait(0.5)   # terminal wait — 30 frames at 60 fps
        self.next_slide()

        # ── build bell curves: low variance ──────────────────────────────
        self.play(FadeOut(framing6))

        baseline = Line(
            np.array([-6.5, CURVE_BASE, 0]),
            np.array([ 6.5, CURVE_BASE, 0]),
            color=GRAY_B, stroke_width=1.5,
        )
        bell_A_low = FunctionGraph(
            lambda x: bell(x, MEAN_A, SIGMA_LOW),
            x_range=[-7, 7, 0.05], color=BLUE_C, stroke_width=3,
        )
        bell_B_low = FunctionGraph(
            lambda x: bell(x, MEAN_B, SIGMA_LOW),
            x_range=[-7, 7, 0.05], color=GREEN_C, stroke_width=3,
        )
        label_A = Text("Group A", font_size=24, color=BLUE_C).move_to(
            np.array([MEAN_A, CURVE_BASE - 0.45, 0])
        )
        label_B = Text("Group B", font_size=24, color=GREEN_C).move_to(
            np.array([MEAN_B, CURVE_BASE - 0.45, 0])
        )
        diff_arrow = DoubleArrow(
            np.array([MEAN_A, CURVE_BASE - 0.9, 0]),
            np.array([MEAN_B, CURVE_BASE - 0.9, 0]),
            color=YELLOW_B, stroke_width=2.5, buff=0.1,
        )
        diff_label = Text("mean difference (stays fixed)", font_size=20, color=YELLOW_B)
        diff_label.next_to(diff_arrow, DOWN, buff=0.12)

        caption_low = Text(
            "Low variance: groups look distinct.",
            font_size=28, color=GRAY_B,
        ).next_to(heading6, DOWN, buff=0.35)
        caption_low.scale_to_fit_width(config.frame_width - 2.0)

        self.add(baseline)
        self.play(Create(bell_A_low), Create(bell_B_low), run_time=1.0)
        self.add(label_A, label_B)
        self.play(Create(diff_arrow))
        self.add(diff_label, caption_low)
        self.wait(0.5)   # terminal wait
        self.next_slide()

        # ── animate: variance grows, curves widen and flatten ────────────
        bell_A_high = FunctionGraph(
            lambda x: bell(x, MEAN_A, SIGMA_HIGH),
            x_range=[-7, 7, 0.05], color=BLUE_C, stroke_width=3,
        )
        bell_B_high = FunctionGraph(
            lambda x: bell(x, MEAN_B, SIGMA_HIGH),
            x_range=[-7, 7, 0.05], color=GREEN_C, stroke_width=3,
        )
        caption_high = Text(
            "More variance: same difference, but the groups now overlap.",
            font_size=28, color=GRAY_B,
        ).next_to(heading6, DOWN, buff=0.35)
        caption_high.scale_to_fit_width(config.frame_width - 2.0)

        self.play(
            Transform(bell_A_low, bell_A_high),
            Transform(bell_B_low, bell_B_high),
            FadeOut(caption_low),
            FadeIn(caption_high),
            run_time=2.0,
        )
        self.next_slide()

        # ── noise note then lump label ────────────────────────────────────
        noise_note = Text(
            "But your data has variation from many places:\n"
            "individual differences,  batch effects,  run-to-run noise...",
            font_size=27, color=GRAY_B, line_spacing=1.2,
        ).next_to(heading6, DOWN, buff=0.35)
        noise_note.scale_to_fit_width(config.frame_width - 1.5)

        lump_text = Text(
            "The t-test lumps it all together as \"error\".",
            font_size=30, color=RED_C, weight=BOLD,
        ).next_to(heading6, DOWN, buff=0.35)
        lump_text.scale_to_fit_width(config.frame_width - 2.0)

        self.play(FadeOut(caption_high), FadeIn(noise_note))
        self.next_slide()

        self.play(FadeOut(noise_note), FadeIn(lump_text))
        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 7 — That costs you power
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(
            heading6, baseline, bell_A_low, bell_B_low,
            label_A, label_B, diff_arrow, diff_label, lump_text,
        ))

        heading7 = Text("That costs you power", font_size=40, weight=BOLD).to_edge(UP, buff=0.5)
        self.add(heading7)
        # No wait — heading visible at start of next clip.

        # ── text fraction ─────────────────────────────────────────────────
        numer_text = Text("difference between groups",    font_size=26, color=YELLOW_B, weight=BOLD)
        denom_text = Text("all the variation in your data", font_size=26, color=RED_C,    weight=BOLD)
        bar_width  = max(numer_text.width, denom_text.width) + 0.4
        frac_bar   = Line(LEFT * bar_width / 2, RIGHT * bar_width / 2, color=WHITE, stroke_width=2)

        numer_text.next_to(frac_bar, UP,   buff=0.18)
        denom_text.next_to(frac_bar, DOWN, buff=0.18)
        fraction = VGroup(numer_text, frac_bar, denom_text)
        fraction.center().shift(RIGHT * 1.0 + UP * 0.8)

        t_label = Text("t  =", font_size=44, weight=BOLD)
        t_label.next_to(fraction, LEFT, buff=0.4)

        self.add(t_label, frac_bar, numer_text)
        self.wait(0.5)   # terminal wait
        self.next_slide()

        self.play(FadeIn(denom_text, shift=DOWN * 0.2))
        self.next_slide()

        consequence7 = Text(
            "A larger denominator  →  smaller t  →  harder to detect real effects.",
            font_size=27, color=GRAY_B,
        ).center().shift(DOWN * 1.2)
        consequence7.scale_to_fit_width(config.frame_width - 1.5)
        self.play(FadeIn(consequence7, shift=DOWN * 0.3))
        self.next_slide()

        punchline7 = Text(
            "Effects that exist become invisible —\n"
            "not because the biology is wrong,\n"
            "but because the test is carrying baggage it cannot put down.",
            font_size=26, color=GRAY_B, line_spacing=1.3,
        ).center().shift(DOWN * 2.8)
        punchline7.scale_to_fit_width(config.frame_width - 2.0)
        self.play(FadeIn(punchline7, shift=DOWN * 0.3))
        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 8 — When should you use a t-test?
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(heading7, t_label, frac_bar, numer_text, denom_text,
                          consequence7, punchline7))

        heading8 = Text(
            "So when should you use a t-test?",
            font_size=38, weight=BOLD,
        ).to_edge(UP, buff=0.5)
        self.add(heading8)

        conditions = [
            "When your data genuinely meets the assumptions.",
            "When there are no other meaningful sources of variation.",
            "When two groups is really all there is.",
        ]
        rows8 = VGroup()
        for c in conditions:
            arrow = Text("→", font_size=28, color=GREEN_C)
            label = Text(c, font_size=28)
            rows8.add(VGroup(arrow, label).arrange(RIGHT, buff=0.3))
        rows8.arrange(DOWN, aligned_edge=LEFT, buff=0.45).center().shift(DOWN * 0.2)

        for row in rows8:
            self.play(FadeIn(row, shift=RIGHT * 0.3))
            self.next_slide()

        callback8 = Text(
            "Panadol is a good drug — for the right condition.\n"
            "The t-test is a good test — for the right data.",
            font_size=28, color=YELLOW_B, weight=BOLD, line_spacing=1.3,
        ).next_to(rows8, DOWN, buff=0.5)
        callback8.scale_to_fit_width(config.frame_width - 2.0)
        self.play(FadeIn(callback8, shift=DOWN * 0.2))
        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 9 — The Take-home
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(heading8, rows8, callback8))

        main9 = Text(
            "The t-test is not a safe default.\n"
            "It is a specific choice with real requirements.",
            font_size=38, weight=BOLD, line_spacing=1.3,
        )
        main9.scale_to_fit_width(config.frame_width - 2.0)
        main9.center().shift(UP * 1.2)

        q1 = Text("Ask not \"can I use a t-test?\"", font_size=32, color=GRAY_B)
        q2 = Text("but \"should I?\"", font_size=40, color=YELLOW_B, weight=BOLD)
        VGroup(q1, q2).arrange(DOWN, buff=0.3).center().shift(DOWN * 0.6)

        self.add(main9)
        self.wait(0.5)   # terminal wait
        self.next_slide()

        self.play(FadeIn(q1, shift=DOWN * 0.2), FadeIn(q2, shift=DOWN * 0.2))
        self.next_slide()

        quote9 = Text(
            "Start with the question.\nLet the data tell you the test.",
            font_size=28, color=GRAY_B, slant=ITALIC, line_spacing=1.3,
        ).center().shift(DOWN * 2.5)
        quote9.scale_to_fit_width(config.frame_width - 3.0)
        self.play(FadeIn(quote9))
        self.next_slide()
