# photon-geocoder skill

Claude Code skill for working with [Photon](https://github.com/komoot/photon) — an open-source geocoder for OpenStreetMap data.

## What it covers

- Forward geocoding (address/place name to coordinates)
- Reverse geocoding (coordinates to address)
- Search-as-you-type address autocomplete
- Location-biased search and OSM tag filtering
- GeoJSON response parsing
- Self-hosting Photon via Java JAR
- Common mistakes and gotchas

## Install

Copy `photon-geocoder/` into `~/.claude/skills/`.

Or install via:

```bash
npx skills add Lu1sDV/skillsmd
```

## Triggers

Activates when geocoding addresses, reverse geocoding coordinates, building address autocomplete, or integrating location search with OpenStreetMap data via the Photon API.
