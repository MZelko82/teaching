"""
p-value Presentation  ·  plain-language version
================================================
Render:   manim-slides render pvalue_slides.py PValue
Present:  manim-slides present PValue
"""

from manim import *
from manim_slides import Slide
import numpy as np


# ── constants ────────────────────────────────────────────────────────────────

RNG_SEED   = 42
N_DOTS     = 80        # dots in the simulation histogram
DOT_RADIUS = 0.12      # manim units — sized so the tallest column clears the text


# ── helpers ──────────────────────────────────────────────────────────────────

def make_coin(correct: bool) -> VGroup:
    """Single coin circle: green ✓ or red ✗."""
    color  = GREEN_C if correct else RED_C
    symbol = "✓"     if correct else "✗"
    circle = Circle(radius=0.36, color=color, fill_opacity=0.22, stroke_width=2.5)
    label  = Text(symbol, font_size=22, color=color)
    return VGroup(circle, label)


# ── presentation ─────────────────────────────────────────────────────────────

class PValue(Slide):

    def construct(self):

        # ════════════════════════════════════════════════════════════════════
        # Slide 1 — Title
        # ════════════════════════════════════════════════════════════════════
        title    = Text("What really is a p-value anyway?", font_size=60, weight=BOLD)
        # subtitle = Text("...and what is it not?", font_size=32, color=GRAY_B)
        # subtitle.next_to(title, DOWN, buff=0.4)
        # VGroup(title, subtitle).center()
        VGroup(title).center()
        # self.add(title, subtitle)
        self.add(title)
        self.wait(0.01)
        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 2 — The Coin Story
        # ════════════════════════════════════════════════════════════════════
        #self.play(FadeOut(title, subtitle))
        self.play(FadeOut(title))
        claim = Text(
            "Your friend claims she can\npredict coin flips.",
            font_size=42, weight=BOLD, line_spacing=1.2,
        ).to_edge(UP, buff=0.5)
        self.add(claim)

        # Row of 10 coins — 8 correct (green ✓), 2 wrong (red ✗)
        coins = VGroup(*[make_coin(i < 8) for i in range(10)])
        coins.arrange(RIGHT, buff=0.18).center().shift(DOWN * 0.3)

        self.play(LaggedStart(
            *[FadeIn(c, shift=DOWN * 0.25) for c in coins],
            lag_ratio=0.12,
        ))

        score = Text("8 out of 10 correct", font_size=30, color=YELLOW_B)
        score.next_to(coins, DOWN, buff=0.45)
        self.add(score)

        question = Text(
            "Could this just be luck?",
            font_size=38, weight=BOLD,
        ).next_to(score, DOWN, buff=0.55)
        self.add(question)
        self.wait(0.01)
        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 3 — The Boring World + Falling Dots
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(claim, coins, score, question))

        framing = Text(
            "Imagine a world where she has no ability at all.",
            font_size=34, weight=BOLD,
        ).to_edge(UP, buff=0.5)
        sub = Text(
            "What scores would a purely random guesser get?",
            font_size=27, color=GRAY_B,
        ).next_to(framing, DOWN, buff=0.2)
        self.add(framing, sub)

        # ── number line ───────────────────────────────────────────────────
        nl = NumberLine(
            x_range=[0, 10, 1],
            length=9.5,
            include_numbers=True,
            numbers_to_include=list(range(11)),
            label_direction=DOWN,
        ).shift(DOWN * 3.2)

        nl_label = Text(
            "Number of correct guesses (out of 10)",
            font_size=21, color=GRAY_B,
        ).next_to(nl, DOWN, buff=0.45)

        self.add(nl_label)
        self.play(Create(nl))

        # ── build dot positions ───────────────────────────────────────────
        np.random.seed(RNG_SEED)
        outcomes   = np.random.binomial(10, 0.5, N_DOTS)
        col_counts = [0] * 11
        all_dots   = []   # list of (Dot, k)

        for k in outcomes:
            x   = nl.n2p(k)[0]
            y   = nl.get_center()[1] + DOT_RADIUS * (2 * col_counts[k] + 1) + 0.05
            dot = Dot(point=np.array([x, y, 0]), radius=DOT_RADIUS, color=BLUE_C)
            all_dots.append((dot, k))
            col_counts[k] += 1

        # Store final positions, then send every dot off the top of the screen
        final_pos = [d.get_center().copy() for d, _ in all_dots]
        dot_mobs  = [d for d, _ in all_dots]
        for dot, fp in zip(dot_mobs, final_pos):
            dot.move_to(np.array([fp[0], 5.5, 0]))

        self.add(*dot_mobs)

        # ── THE ANIMATION: dots fall one by one into their bins ───────────
        self.play(
            LaggedStart(
                *[dot.animate.move_to(fp) for dot, fp in zip(dot_mobs, final_pos)],
                lag_ratio=0.04,
            ),
            run_time=5.0,
        )
        self.next_slide()   # pause — audience absorbs the full distribution

        # ── Reveal the tail ≥ 8 ──────────────────────────────────────────
        tail_dots  = [d for d, k in all_dots if k >= 8]
        other_dots = [d for d, k in all_dots if k <  8]
        n_tail     = len(tail_dots)

        self.play(
            *[d.animate.set_opacity(0.18) for d in other_dots],
            *[d.animate.set_color(RED_C)  for d in tail_dots],
            run_time=0.9,
        )

        # Score-8 marker arrow
        score_8_x   = nl.n2p(8)[0]
        score_8_top = nl.get_center()[1] + DOT_RADIUS * (2 * col_counts[8]) + 0.4
        arrow = Arrow(
            start=np.array([score_8_x, score_8_top + 0.8, 0]),
            end  =np.array([score_8_x, score_8_top,       0]),
            color=RED_B, stroke_width=3, buff=0.05,
        )
        she_label = Text("She scored 8", font_size=22, color=RED_B)
        she_label.next_to(arrow, UP, buff=0.05)

        self.add(she_label)
        self.play(GrowArrow(arrow))

        tail_note = Text(
            f"In our simulation, {n_tail} out of {N_DOTS} random\n"
            f"guessers scored 8 or more  ({100 * n_tail / N_DOTS:.0f}%).",
            font_size=23, color=RED_C, line_spacing=1.2,
        ).to_corner(UR, buff=0.45)
        self.play(FadeOut(framing, sub), FadeIn(tail_note))

        # p-value box (theoretical value)
        # p_text = Text("p ≈ 0.055", font_size=48, color=RED_C, weight=BOLD)
        # p_text.to_corner(DR, buff=0.65).shift(UP * 0.6)
        # p_rect = SurroundingRectangle(p_text, color=RED_C, buff=0.22, corner_radius=0.1)
        # self.add(p_text, p_rect)
        # self.wait(1.0)
        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 5 — Figurative callback animation
        # ════════════════════════════════════════════════════════════════════
        

        self.play(FadeOut(
            nl, nl_label,
            arrow, she_label, tail_note, # p_text, p_rect,
            *dot_mobs,
        ))

        s5_label = Text(
            "Small p-value  →  rare in the boring world",
            font_size=32, color=YELLOW_B, weight=BOLD,
        ).to_edge(UP, buff=0.5)
        self.add(s5_label)

        # ── Rebuild same histogram at smaller scale (callback to slide 3) ──
        np.random.seed(RNG_SEED)          # reset so we get identical dot positions
        outcomes_cb   = np.random.binomial(10, 0.5, N_DOTS)
        dot_r_cb      = 0.10
        nl_cb = NumberLine(
            x_range=[0, 10, 1],
            length=7.5,
            include_numbers=True,
            numbers_to_include=list(range(11)),
            label_direction=DOWN,
        ).shift(DOWN * 1.8)

        col_counts_cb = [0] * 11
        cb_dots       = []
        for k in outcomes_cb:
            x   = nl_cb.n2p(k)[0]
            y   = nl_cb.get_center()[1] + dot_r_cb * (2 * col_counts_cb[k] + 1) + 0.04
            dot = Dot(point=np.array([x, y, 0]), radius=dot_r_cb, color=GRAY_C)
            cb_dots.append((dot, k))
            col_counts_cb[k] += 1

        cb_dot_mobs = [d for d, _ in cb_dots]

        # Appear left → right (sweep, not falling — this is a callback)
        sorted_dots = sorted(cb_dot_mobs, key=lambda d: d.get_center()[0])
        self.play(
            Create(nl_cb),
            LaggedStart(*[FadeIn(d) for d in sorted_dots], lag_ratio=0.03),
            run_time=1.8,
        )

        # Oval over the centre cluster (k = 3–7)
        nl_y         = nl_cb.get_center()[1]
        top_of_k5    = nl_y + dot_r_cb * (2 * col_counts_cb[5]) + 0.04
        oval_center  = np.array([nl_cb.n2p(5)[0], (nl_y + top_of_k5) / 2, 0])
        boring_oval  = Ellipse(
            width=5.5, height=top_of_k5 - nl_y + 0.4,
            color=GRAY_B, fill_opacity=0.08, stroke_width=1.5,
        ).move_to(oval_center)

        boring_label = Text(
            "Most outcomes\nland here", font_size=24, color=GRAY_B, line_spacing=1.1,
        ).next_to(boring_oval, LEFT, buff=0.2)

        self.play(Create(boring_oval))
        self.add(boring_label)
        self.wait(0.01)
        self.next_slide()

        # ── Reveal the tail ───────────────────────────────────────────────
        cb_tail  = [d for d, k in cb_dots if k >= 8]
        cb_other = [d for d, k in cb_dots if k <  8]

        self.play(
            *[d.animate.set_opacity(0.15) for d in cb_other],
            boring_oval.animate.set_stroke(opacity=0.1).set_fill(opacity=0.02),
            FadeOut(boring_label),
            run_time=0.7,
        )
        self.play(
            *[d.animate.set_color(RED_C).set_opacity(1.0) for d in cb_tail],
            run_time=0.4,
        )
        self.play(
            LaggedStart(
                *[Flash(d, color=RED_C, flash_radius=0.22, line_length=0.12, num_lines=8)
                  for d in cb_tail],
                lag_ratio=0.12,
            ),
            run_time=1.0,
        )

        tail_box   = SurroundingRectangle(
            VGroup(*cb_tail), color=RED_C, buff=0.2, corner_radius=0.08, stroke_width=2,
        )
        rare_label = Text(
            "Rare\nSmall p-value", font_size=24, color=RED_C,
            line_spacing=1.1, weight=BOLD,
        ).next_to(tail_box, RIGHT, buff=0.25)
        rare_label.shift(UP * 0.5)

        self.play(Create(tail_box))
        self.add(rare_label)
        self.wait(0.01)
        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 4 — General principle
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(
            s5_label, nl_cb, boring_oval, tail_box, rare_label, *cb_dot_mobs,
        ))
        

        s4_title = Text("The general idea", font_size=40, weight=BOLD).to_edge(UP, buff=0.5)
        self.add(s4_title)

        steps = [
            ("1.", "Assume the boring explanation is true — nothing is happening."),
            ("2.", "Ask: how often would pure chance produce a result this extreme?"),
            ("3.", "That probability is the p-value."),
        ]
        step_group = VGroup()
        for num, body in steps:
            bullet = Text(num,  font_size=30, color=YELLOW_B, weight=BOLD)
            text   = Text(body, font_size=27)
            row    = VGroup(bullet, text).arrange(RIGHT, buff=0.3)
            step_group.add(row)
        step_group.arrange(DOWN, aligned_edge=LEFT, buff=0.5).center().shift(DOWN * 0.2)

        self.play(LaggedStart(
            *[FadeIn(r, shift=RIGHT * 0.3) for r in step_group],
            lag_ratio=0.5,
        ))

        self.next_slide()

        # ════════════════════════════════════════════════════════════════════
        # Slide 6 — Misconceptions (plain language)
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(s4_title, step_group))

        s5_title = Text(
            "What the p-value is NOT", font_size=40, weight=BOLD, color=RED_C,
        ).to_edge(UP, buff=0.4)
        self.add(s5_title)

        misconceptions = [
            (
                "The probability the boring explanation is true",
                "Since it assumes the boring explanation, it can't judge whether it's true.",
            ),
            (
                "The probability your result was due to chance",
                "Chance is the starting assumption, not something being measured.",
            ),
            (
                "A measure of how big or important the effect is",
                "A huge study can yield a tiny p for a completely trivial effect.",
            ),
        ]

        rows = VGroup()
        for wrong, note in misconceptions:
            cross     = Text("✗ ", font_size=28, color=RED_C)
            wrong_mob = Text(wrong, font_size=26, color=RED_C)
            top_row   = VGroup(cross, wrong_mob).arrange(RIGHT, buff=0.1)
            note_mob  = Text(note, font_size=21, color=GRAY_B)
            note_mob.next_to(top_row, DOWN, buff=0.06, aligned_edge=LEFT)
            note_mob.shift(RIGHT * 0.45)
            rows.add(VGroup(top_row, note_mob))

        rows.arrange(DOWN, aligned_edge=LEFT, buff=0.5).center().shift(DOWN * 0.1)

        for row in rows:
            self.play(FadeIn(row, shift=RIGHT * 0.3))
            self.next_slide()

        # # ════════════════════════════════════════════════════════════════════
        # # Slide 7 — Summary
        # # ════════════════════════════════════════════════════════════════════
        # self.play(FadeOut(s5_title, rows))

        # s6_title = Text(
        #     "The p-value is the probability of seeing a result\n"
        #     "this extreme if there were truly nothing going on.",
        #     font_size=40, weight=BOLD,
        # )
        # s6_title.scale_to_fit_width(config.frame_width - 2.0)  # 1-unit margin each side
        # s6_title.to_edge(UP, buff=1.3)
        # self.add(s6_title)
        # self.wait(0.01)
        # self.next_slide()

        # reminder = Text(
        #     "It does not tell you whether your hypothesis is true.",
        #     font_size=40, weight=BOLD, color=BLUE_C,
        # ).next_to(s6_title, DOWN, buff=2.3)
        # reminder.scale_to_fit_width(config.frame_width - 2.0)
        # self.add(reminder)
        # self.wait(0.01)
        # self.next_slide()
        # ════════════════════════════════════════════════════════════════════
        # Slide 7 — Summary
        # ════════════════════════════════════════════════════════════════════
        self.play(FadeOut(s5_title, rows))

        s6_title = Text(
            "The p-value is the probability of seeing a result\n"
            "this extreme if there were truly nothing going on.",
            font_size=40,
            weight=BOLD,
        )

        reminder = Text(
            "It does not tell you whether your hypothesis is true.",
            font_size=40,
            weight=BOLD,
            color=BLUE_C,
        )

        # Ensure both fit width BEFORE arranging
        for mob in (s6_title, reminder):
            mob.scale_to_fit_width(config.frame_width - 2.0)

        # Arrange vertically with controlled spacing
        texts = VGroup(s6_title, reminder)
        texts.arrange(DOWN, buff=2.3)

        # Center the entire block on screen
        texts.move_to(ORIGIN)

        self.add(texts)
        self.wait(0.01)
        self.next_slide()