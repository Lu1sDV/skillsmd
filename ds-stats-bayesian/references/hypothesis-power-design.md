# Hypothesis Testing, Power Analysis & Experimental Design

End-to-end guide for study design (pre-collection), sample-size/power planning, and hypothesis testing with assumption checks, effect sizes, and APA reporting.

---

## 1. Experimental Design (Pre-Data Collection)

Three foundational principles (Fisher):
- **Randomization**: Assigns treatments randomly so known/unknown confounders balance in expectation—required for causal claims.
- **Replication**: Independent repetition at the level treatment is assigned. **Pseudoreplication** (e.g., 3 mice × 100 cells treated as $n = 300$ instead of $n = 3$) invalidates inference.
- **Blocking / local control**: Group similar units (batch, day, site, plate, litter) and randomize within blocks to remove nuisance variation from error.

### Design Selection Tree

| Goal & Unit Structure | Design | Key Considerations |
|---|---|---|
| Compare conditions, independent units, no nuisance factor | Completely randomized | Simple randomization can imbalance small $n$; use permuted blocks |
| Compare conditions with known nuisance factor (day, batch, site) | Randomized block / Stratified block | Randomize within each block/stratum; include block in analysis model |
| Each unit receives all conditions sequentially | Crossover / Repeated-measures | Require washout period; watch carryover and period effects |
| Can only randomize intact groups (clinics, classrooms) | Cluster-randomized | Cluster is the experimental unit; account for ICC in power and model |
| Quantify main effects + interactions for $k$ factors ($k \le 4$) | Full $2^k$ factorial | Estimates all main effects and interactions |
| Screen many factors ($5+$) cheaply | Fractional factorial / Plackett-Burman | Check resolution and alias structure before concluding no effect |
| Optimize response over continuous factors (curvature) | Response-surface (CCD / Box-Behnken) | Use `face="inscribed"` or `"faced"` if ranges are physical limits (default `"circumscribed"` places axial points outside low/high); never clip rows; reserve independent center runs for pure error |
| Explore deterministic/simulation space | Latin hypercube | Space-filling over continuous domain |

- **DOE tooling**: `pydoe==1.5.0` (lowercase `import pydoe`; `pyDOE3` was archived May 2026). Randomize run/plate order to defeat drift and edge/thermal gradients; for split-plots or batched CCDs, randomize only within permitted block boundaries.
- **Allocation**: Archive software versions and seeds; restrict access to seed/future assignments during enrollment. Match the analysis model to blocks, strata, clusters, and nesting.

---

## 2. Statistical Power & Sample Size

Four locked quantities: **sample size ($n$)**, **effect size**, **$\alpha$**, and **power ($1 - \beta$)**. Standard helpers cover superiority tests only; equivalence, noninferiority, and sequential designs require dedicated calculations.

### Choosing Effect Sizes (Order of Preference)

1. **SESOI (Smallest Effect Size of Interest)**: Smallest effect that matters scientifically or clinically—most defensible.
2. **Pilot / prior-study estimate**: Account for uncertainty and publication/significance inflation using a sensitivity range rather than an arbitrary shrinkage factor.
3. **Cohen's benchmarks**: Last resort only; state explicitly.

> **Never compute post-hoc ("observed") power.** It is a circular function of the p-value. For completed studies, report a **sensitivity analysis** (minimum detectable effect, MDE, at achieved $n$) and the confidence interval around the observed effect.

### Closed-Form Power (`statsmodels.stats.power`)

```python
import math
from statsmodels.stats.power import (
    tt_ind_solve_power, FTestAnovaPower, NormalIndPower, TTestPower
)
from statsmodels.stats.proportion import proportion_effectsize

# Two independent means (returns n1; n2 = ceil(ratio * n1); recheck realized integer ratio)
n1 = tt_ind_solve_power(effect_size=0.5, alpha=0.05, power=0.80, ratio=1.0, alternative="two-sided")

# Sensitivity / MDE for fixed n1=30 per group
mde_d = tt_ind_solve_power(effect_size=None, nobs1=30, alpha=0.05, power=0.80, ratio=1.0)

# One-way ANOVA: parameter is k_groups; effect_size is Cohen's f = sqrt(eta2 / (1 - eta2))
# WARNING: solve_power returns TOTAL sample size, not per-group
n_total = FTestAnovaPower().solve_power(effect_size=0.25, k_groups=3, alpha=0.05, power=0.80)
per_group = math.ceil(n_total / 3)

# Two proportions (auto-convert to Cohen's h)
h = proportion_effectsize(0.40, 0.55)
n1_prop = NormalIndPower().solve_power(effect_size=h, alpha=0.05, power=0.80, ratio=1.0)
```
- Paired / one-sample t-test (`TTestPower`): `n` counts pairs/units. One-sided alternatives require signed effect sizes and `"larger"`/`"smaller"`.

### Simulation Power & Design Adjustments

- **When to simulate**: Logistic/Poisson regression, mixed-effects/repeated-measures, cluster-randomized trials, survival (`lifelines` requires `pandas<3`), mediation, or multi-way interactions.
- **Protocol**: Simulate from assumed data-generating process -> fit exact planned model -> repeat $\ge 1{,}000$ times ($5{,}000\text{--}10{,}000$ near 80% power). Verify Type I error under the null first; report Monte Carlo CI; verify candidate $n$ from bisection with a fresh seed and more replicates.
- **Adjustments people forget**:
  - **Multiplicity**: Power primary/co-primary endpoints at corrected $\alpha$ (e.g., $\alpha/m$ or simulated FWER/FDR).
  - **Attrition**: $n_{\text{enroll}} = \lceil n_{\text{analyzed}} / (1 - \text{dropout\_rate}) \rceil$ (e.g., 20% dropout -> enroll 25% more).
  - **Clustering**: $\text{DEFF} = 1 + (m - 1) \cdot \text{ICC}$ is a planning approximation for equal-size parallel clusters; simulate for unequal clusters, few clusters, or repeated-measures.
- **Deliverable**: Always report a **sensitivity range / power curve** across plausible effect sizes, never a single point estimate.

---

## 3. Hypothesis Testing, Assumptions & Reporting

```bash
uv pip install "pingouin==0.7.0" "scipy==1.18.1" "statsmodels==0.15.0" pandas matplotlib seaborn
```

### Test Selection Quick Reference

| Question | Parametric / Default | Non-Parametric / Alternative | Key Caveats |
|---|---|---|---|
| 2 independent groups (means) | `pg.ttest(a, b, correction=True)` (Welch) | `pg.mwu(a, b)` (rank contrast, `RBC`) | `correction='auto'` checks sample-size equality, not variance; prespecify `correction=True` |
| 2 paired groups | `pg.ttest(a, b, paired=True)` | `pg.wilcoxon(a, b)` | Diagnose normality on differences; Wilcoxon assumes symmetric paired differences |
| 3+ independent groups | `pg.welch_anova` + `pg.pairwise_gameshowell` | `pg.anova` + `pg.pairwise_tukey`, or `pg.kruskal` | Pooled ANOVA requires justified equal variance; `pairwise_tukey` returns Hedges' $g$ |
| Correlation | `pg.corr(x, y, method='pearson')` | `pg.corr(x, y, method='spearman')` | Choose by scientific question (linear vs. monotone rank), not normality pretest |
| Bayesian 2-group | PyMC shared/unequal-var Normal model | `arviz.summary(..., ci_prob=0.95)` | Pingouin omits `BF10` for 1-sided t-tests; 2-sided `BF10` is not Welch's model |

### Pingouin 0.7.0+ API & Assumption Rules

- **Column names (0.6+)**: `p_val`, `cohen_d`, `CI95`, `p_unc`. `pg.ttest` returns **absolute** `cohen_d`; compute signed $d$ with `pg.compute_effsize(a, b, eftype='cohen')` and its CI with `pg.compute_esci(stat=d, nx=len(a), ny=len(b), eftype='cohen', confidence=0.95)` (`compute_effsize_from_t` does not return a CI).
- **Assumption checks**:
  - Non-significant Shapiro-Wilk or Levene's test does **not** prove normality or equal variance; there is no universal $n = 30$ robustness rule.
  - Shapiro-Wilk p-values become unreliable above $5{,}000$ observations.
  - Inspect raw plots (histograms, Q-Q, box plots) alongside design; do **not** switch tests automatically at a diagnostic p-value threshold.
  - Independence is established by study design, never by a diagnostic test.

### Common Effect Size Benchmarks

| Test | Effect Size | Small | Medium | Large |
|---|---|---|---|---|
| T-test | Cohen's $d$ | 0.20 | 0.50 | 0.80 |
| ANOVA | $\eta^2_p$ | 0.01 | 0.06 | 0.14 |
| Correlation | $r$ | 0.10 | 0.30 | 0.50 |
| Regression | $R^2$ | 0.02 | 0.13 | 0.26 |
| Chi-square ($2\times 2$) | Cramér's $V$ | 0.10 | 0.30 | 0.50 |

### APA Reporting & Statistical Integrity

Every report must include:
1. **Descriptives**: $M$, $SD$, $n$ per group (or median/IQR for rank methods).
2. **Test statistics**: Test name, statistic, $df$, exact $p$ (`p = .034`, `p < .001` only below .001).
3. **Effect size + CI**: Lead interpretation with magnitude and 95% CI, not p-value alone.
4. **Assumption checks & missing data**: Tests/plots inspected, actions taken, row exclusions and missingness mechanism.
5. **Integrity**: Distinguish confirmatory vs. exploratory analyses; report all planned tests (including non-significant ones); apply and name multiplicity corrections (Tukey HSD, Holm, or Benjamini-Hochberg FDR); set and record seeds and package versions.
