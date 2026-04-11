# feature-engineering

Time series feature engineering skill for Claude Code. Covers calendar features, cyclical encoding, rolling window statistics, differencing, scaling, and sunlight features — using feature_engine, skforecast, and astral.

## What It Does

- **Calendar features**: Extract month, week, day_of_week, hour from datetime index (manual pandas or automated `DatetimeFeatures`)
- **Cyclical encoding**: Sin/cos encoding for periodic features so hour 23 stays near hour 0
- **Rolling statistics**: 9 rolling window statistics (mean, std, min, max, sum, median, ratio_min_max, coef_variation, ewm) via skforecast `RollingFeatures`
- **Differencing**: Built-in stationarity transforms with automatic inverse on predictions
- **Scaling**: StandardScaler/MinMaxScaler integration for target and exogenous variables
- **Sunlight features**: Sunrise, sunset, daylight hours via astral for energy/transport domains

## Structure

```
feature-engineering/
├── SKILL.md                              # Main skill — techniques, code patterns, quick reference
├── README.md                             # This file
└── references/
    └── rolling-stats-reference.md        # Full RollingFeatures API: constructor, all 9 stats, window behavior, config patterns
```

## Installation

### Via Plugin Marketplace

```bash
# Add the skillsmd plugin source
/plugin marketplace add Lu1sDV/skillsmd

# Install the skill
/plugin install feature-engineering@Lu1sDV/skillsmd
```

### Via npx

```bash
npx skills add Lu1sDV/skillsmd feature-engineering
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/feature-engineering ~/.claude/skills/
```

### Verify

```
What skills are available?
```

## Usage

The skill activates when working on time series forecasting and the conversation involves exogenous variables, calendar features, rolling statistics, cyclical encoding, differencing, or feature scaling.

```
Add calendar features to my forecasting pipeline
```

```
My forecast accuracy has plateaued — what features could help?
```

```
Set up rolling window statistics for this skforecast model
```

```
Encode hour and day_of_week as cyclical features
```

## Key Libraries

| Library | Used For |
|---------|----------|
| feature_engine | `DatetimeFeatures`, `CyclicalFeatures` |
| skforecast | `RollingFeatures`, `ForecasterRecursive`, differencing |
| astral | Sunrise/sunset/daylight hours |
| sklearn | `StandardScaler`, `MinMaxScaler` |
| lightgbm | `LGBMRegressor` (example estimator) |
