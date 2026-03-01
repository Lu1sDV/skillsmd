---
name: photon-geocoder
description: Use when geocoding addresses, reverse geocoding coordinates, building address autocomplete, or integrating location search with OpenStreetMap data via Photon API (photon.komoot.io). Triggers on "photon", "geocode", "reverse geocode", "OSM address search".
---

# Photon Geocoder API

Open-source geocoder for OpenStreetMap data. Free public instance at `photon.komoot.io` (rate-limited) or self-hosted via `java -jar photon.jar serve` on port 2322.

## When to Use

- Converting addresses/place names to coordinates (forward geocoding)
- Converting coordinates to addresses (reverse geocoding)
- Building search-as-you-type address autocomplete
- Filtering places by OSM tags, layers, or categories
- Need free, no-API-key geocoding with multilingual support

**Not for:** Routing/directions (use OSRM/GraphHopper), map tile rendering, POI databases.

## Quick Reference

| Endpoint | Purpose | Required Params |
|----------|---------|-----------------|
| `GET /api` | Forward search | `q` (search term) |
| `GET /structured` | Structured address search | At least one of: `city`, `street`, `postcode`, etc. |
| `GET /reverse` | Reverse geocode | `lat`, `lon` |
| `GET /status` | Health check + data date | None |

**Public instance:** `https://photon.komoot.io` (add `/api?q=...`)
**Self-hosted default:** `http://localhost:2322`

## Autocomplete Pattern

```
GET /api?q=via+rom&lat=41.89&lon=12.49&zoom=14&limit=5&lang=it&layer=street&layer=house
```

Use `lat`/`lon`/`zoom` for location bias, `layer` to restrict to streets/houses, `limit=5` for fast responses. Fire on each keystroke with debounce (200-300ms).

## Location-Biased Search

```
GET /api?q=farmacia&lat=45.46&lon=9.19&zoom=14&location_bias_scale=0.1&osm_tag=amenity:pharmacy&limit=5
```

Low `location_bias_scale` (0.1) strongly prefers nearby results over globally prominent ones.

## Reverse Geocoding

```
GET /reverse?lat=52.51&lon=13.39&radius=1
```

Required: `lat`, `lon`. Optional: `radius` (km, 0-5000), `limit`, `lang`, `osm_tag`, `layer`.

## Response Format (GeoJSON)

All endpoints return GeoJSON `FeatureCollection`. Key properties per feature: `name`, `street`, `housenumber`, `postcode`, `city`, `district`, `state`, `county`, `country`, `countrycode`, `osm_key`, `osm_value`, `osm_type` (N=Node, W=Way, R=Relation), `osm_id`, `extent`, `extra`.

**Coordinates are `[longitude, latitude]`** (GeoJSON standard).

See `api-reference.md` for full response schema, parameter tables, tag/layer filters, and TypeScript types.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Coordinates as `[lat, lon]` | GeoJSON is `[longitude, latitude]` |
| Hammering public instance | Rate-limit requests; self-host for production |
| Not URL-encoding query | Encode spaces and special chars (`encodeURIComponent`) |
| Using `bbox` with `lat/lon` bias | `bbox` is a hard filter; `lat/lon` is soft ranking. Pick one strategy |
| Filtering by category group only | `include=food` errors; need at least two levels: `include=food.shop` |
| Expecting routing/directions | Photon is geocoding only; use OSRM/GraphHopper for routing |

## Self-Hosting

Requires Java 21+. Download from [GitHub releases](https://github.com/komoot/photon/releases). See `api-reference.md` for setup commands and server flags.
