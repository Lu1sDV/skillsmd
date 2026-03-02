# web-performance-optimization skill

Claude Code skill for systematic web performance diagnosis and optimization.

## What it covers

- Core Web Vitals (LCP, INP, CLS, TBT, FCP) with debugging workflows
- Quick wins prioritized by time investment (1hr/1day/1week)
- Performance budgets and runtime optimization patterns
- Modern browser APIs: View Transitions, Speculation Rules, Server Components, Islands Architecture
- Framework-specific patterns: Next.js, React, Vue, Vite, Astro, SvelteKit
- Backend optimization (TTFB, caching, database queries)
- Monitoring setup: Lighthouse CI, RUM, APM, performance dashboards

## Install

Copy `web-performance-optimization/` into `~/.claude/skills/`.

Or install via:

```bash
npx skills add Lu1sDV/skillsmd
```

## Structure

```
web-performance-optimization/
  SKILL.md                              # Entry point with decision flowchart
  references/
    quick-wins.md                       # Time-boxed optimizations with ROI ratings
    core-web-vitals.md                  # Metric-specific deep dives and debugging
    optimization-techniques.md          # Backend, image, JS, CSS, caching patterns
    modern-patterns-2025.md             # View Transitions, Speculation Rules, RSC, Islands
    framework-specific.md               # Next.js, React, Vue, Vite, Astro, SvelteKit
    monitoring.md                       # Lighthouse CI, RUM, APM, performance budgets
```

## Triggers

Activates when improving Lighthouse scores, reducing page load times, debugging performance bottlenecks, optimizing Core Web Vitals for SEO, or implementing modern browser performance APIs like View Transitions and Speculation Rules.
