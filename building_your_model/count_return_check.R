# count_return_check.R --------------------------------------------------------
# Backstage check for slide 31 (count model's Bias return), desktop chat
# 2026-10-19. Not used by the deck. Vault note: "2026-10-19 Count model
# return - what it fixes".
# Compares, with session and participant effects:
#   raw  normal model on errors
#   log  normal model on log(errors + 1), back-transformed (exp(.) - 1)
#   nbc  NB GLMM, exp(fixed effects) (session/person effects at 0)
#   nbm  NB GLMM, averaged over sessions and people: exp(fixed + var/2)
# on seed 503 and over 300 repeats from two generators: sim_lego (the deck's,
# normal, rounded, floored) and sim_count (NB, k = 8, log-scale session and
# person SD 0.25; the chat's choice). Output: per-format averages, difference,
# ratio, and the shift of the picture average in run-to-run SDs.
# Needs lme4 and glmmTMB. Takes a few minutes.
# ---------------------------------------------------------------------------

suppressMessages({library(lme4); library(glmmTMB)})
sim_lego <- function(seed, sizes, b0 = 8, b_format = -1, b_learn = -1,
                     sd_session = 2, sd_person = 2, sd_resid = 1) {
  set.seed(seed)
  n_sessions <- length(sizes)
  format <- rep(0:1, each = n_sessions / 2)
  rows <- lapply(seq_len(n_sessions), function(s) {
    u_s <- rnorm(1, 0, sd_session)
    do.call(rbind, lapply(seq_len(sizes[s]), function(p) {
      u_p <- rnorm(1, 0, sd_person)
      data.frame(session = s, participant = paste0(s, "_", p), format = format[s],
        build = 0:1, u_s = u_s,
        errors = pmax(0, round(b0 + b_format * format[s] + b_learn * (0:1) +
          u_s + u_p + rnorm(2, 0, sd_resid))))
    }))
  })
  do.call(rbind, rows)
}
# count generator matched to the deck's: NB, log-scale session/person effects
sim_count <- function(seed, sizes, mu0 = 8, ratio = 6.5/7.5, learn = 6.5/7.5,
                      sd_s = 0.25, sd_p = 0.25, k = 8) {
  set.seed(seed)
  ns <- length(sizes); format <- rep(0:1, each = ns / 2)
  do.call(rbind, lapply(seq_len(ns), function(s) {
    us <- rnorm(1, 0, sd_s)
    do.call(rbind, lapply(seq_len(sizes[s]), function(p) {
      up <- rnorm(1, 0, sd_p)
      mu <- mu0 * ratio^format[s] * learn^(0:1) * exp(us + up)
      data.frame(session = s, participant = paste0(s, "_", p), format = format[s],
                 build = 0:1, errors = rnbinom(2, size = k, mu = mu))
    }))
  }))
}
sizes <- c(4, 16, 10, 14, 6, 10)

fit3 <- function(d) {
  f <- errors ~ format + build + (1 | session) + (1 | participant)
  a <- suppressMessages(lmer(f, data = d)); b <- fixef(a)
  d$ly <- log(d$errors + 1)
  l <- suppressMessages(lmer(ly ~ format + build + (1 | session) + (1 | participant), data = d)); lb <- fixef(l)
  n <- suppressWarnings(glmmTMB(f, data = d, family = nbinom2)); nb <- fixef(n)$cond
  vc <- sum(sapply(VarCorr(n)$cond, function(v) v[1]))
  eta <- function(cf, fm) unname(cf[1] + cf[2] * fm + cf[3] * 0.5)
  c(
    raw_pic = eta(b, 0), raw_txt = eta(b, 1),
    log_pic = exp(eta(lb, 0)) - 1, log_txt = exp(eta(lb, 1)) - 1,
    nbc_pic = exp(eta(nb, 0)), nbc_txt = exp(eta(nb, 1)),
    nbm_pic = exp(eta(nb, 0) + vc / 2), nbm_txt = exp(eta(nb, 1) + vc / 2))
}
summ <- function(M, truth, lab) {
  M <- as.data.frame(M)
  cat("\n==", lab, "== true picture", round(truth[1], 2), "text", round(truth[2], 2),
      "diff", round(truth[2] - truth[1], 2), "ratio", round(truth[2] / truth[1], 3), "\n")
  for (m in c("raw", "log", "nbc", "nbm")) {
    ok <- is.finite(M$nbm_pic) & M$nbm_pic < 100; p <- M[[paste0(m, "_pic")]][ok]; t <- M[[paste0(m, "_txt")]][ok]
    cat(sprintf("%-4s picture %5.2f  text %5.2f  diff %5.2f (sd %4.2f)  ratio %5.3f | picture bias/sd %5.2f\n",
      m, mean(p), mean(t), mean(t - p), sd(t - p), mean(t / p), (mean(p) - truth[1]) / sd(p)))
  }
}

# 1. seed 503 itself
d <- sim_lego(503, sizes)
cat("seed 503: picture mean", round(mean(d$errors[d$format == 0]), 2), "text", round(mean(d$errors[d$format == 1]), 2),
    "overall", round(mean(d$errors), 2), "var", round(var(d$errors), 2), "zeros", sum(d$errors == 0), "\n")
print(round(fit3(d), 2))

# 2. repeats; truth from a big sample of each generator
big <- function(gen) { x <- do.call(rbind, lapply(1:200, function(i) gen(10^6 + i, rep(50, 6)))); tapply(x$errors, x$format, mean) }
R <- 300
tr <- big(sim_lego)
M <- t(sapply(1:R, function(i) fit3(sim_lego(i, sizes))))
cat("\nNB fit failures:", sum(!is.finite(M[, "nbm_pic"])), "\n")
summ(M, tr, "deck generator (normal, rounded, floored)")
tr2 <- big(sim_count)
M2 <- t(sapply(1:R, function(i) fit3(sim_count(i, sizes))))
summ(M2, tr2, "matched count generator (NB, k=8)")
