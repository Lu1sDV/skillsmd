# ofelia

Claude Code skill for [Ofelia](https://github.com/mcuadros/ofelia) — a modern, lightweight Docker job scheduler (cron replacement for containers).

## What it covers

- All four job types: `job-exec`, `job-run`, `job-local`, `job-service-run`
- INI file and Docker label configuration
- Docker Compose integration patterns
- Cron scheduling syntax (Go robfig/cron)
- Middleware: overlap prevention, Slack, email, save-to-disk
- Docker socket proxy setup
- Docker Swarm service jobs
- Common mistakes and gotchas

## Installation

### Claude Code Plugin

```
/plugin install ofelia@Lu1sDV/skillsmd
```

### npx

```bash
npx skills add Lu1sDV/skillsmd ofelia
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/ofelia ~/.claude/skills/
```

### Verify

```
What skills are available?
```

## Structure

```
ofelia/
├── SKILL.md              # Main skill — overview, quick ref, config patterns, gotchas
├── README.md             # This file
└── references/
    └── job-parameters.md # Complete parameter tables for all job types and middleware
```

## Usage examples

- "Set up Ofelia to run database backups every night at 2 AM"
- "Add a scheduled cache clear to my Docker Compose setup"
- "Configure Ofelia to send Slack notifications on job failures"
- "Debug why my Ofelia job-exec isn't finding the target container"
