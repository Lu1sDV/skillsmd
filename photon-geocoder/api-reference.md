# Photon API Reference

## Forward Search (`/api`) Parameters

| Param | Type | Description |
|-------|------|-------------|
| `q` | string | **Required.** Search term |
| `lang` | string | Response language (ISO 639-1: `en`, `it`, `de`, `fr`...). Falls back to `Accept-Language` header, then local name |
| `limit` | int | Max results (server may cap this; default max typically 50) |
| `lat`, `lon` | float | Location bias center — results near this point ranked higher |
| `zoom` | int | Bias radius (map zoom level, default 16). Lower = wider radius |
| `location_bias_scale` | float | 0.0 (ignore prominence) to 1.0 (prominence = location weight). Default 0.2 |
| `bbox` | string | Bounding box filter: `minLon,minLat,maxLon,maxLat` |
| `osm_tag` | string | Tag filter (repeatable). See [Tag Filtering](#tag-filtering) |
| `layer` | string | Layer filter (repeatable). See [Layers](#layers) |
| `include` | string | Category include filter (comma-separated, repeatable) |
| `exclude` | string | Category exclude filter (comma-separated, repeatable) |
| `dedupe` | 0\|1 | Deduplication. Default: enabled. Set `0` to return all matches |

## Structured Search (`/structured`) Parameters

```
GET /structured?city=berlin&street=Unter%20den%20Linden&housenumber=2&countrycode=DE
```

Split address into components for more targeted results. All `/api` parameters also work here.

| Param | Description |
|-------|-------------|
| `countrycode` | ISO 3166-1 alpha-2 (`IT`, `DE`, `US`...) |
| `state` | State/region |
| `county` | County/province |
| `city` | City name |
| `district` | City district or suburb |
| `postcode` | Postal code |
| `street` | Street name |
| `housenumber` | House number |

**Best for:** Geocoding well-formatted addresses from forms or databases where components are already separated.

## Reverse Geocoding (`/reverse`) Parameters

| Param | Type | Description |
|-------|------|-------------|
| `lat` | float | **Required.** Latitude |
| `lon` | float | **Required.** Longitude |
| `radius` | float | Search radius in km (0–5000) |
| `limit` | int | Max results |
| `lang` | string | Response language |
| `osm_tag` | string | Tag filter (repeatable) |
| `layer` | string | Layer filter (repeatable) |

### Find Nearest POIs

```
GET /reverse?lat=45.46&lon=9.19&osm_tag=amenity:pharmacy&limit=5
```

## Response Schema (GeoJSON)

```json
{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [13.3889, 52.5170]
  },
  "properties": {
    "name": "Berlin",
    "street": "Unter den Linden",
    "housenumber": "1",
    "postcode": "10117",
    "district": "Mitte",
    "city": "Berlin",
    "state": "Berlin",
    "country": "Germany",
    "countrycode": "DE",
    "osm_key": "place",
    "osm_value": "city",
    "osm_type": "N",
    "osm_id": 240109189,
    "extent": [minLon, maxLat, maxLon, minLat],
    "extra": {}
  }
}
```

**Key properties:** `name`, `street`, `housenumber`, `postcode`, `city`, `district`, `state`, `county`, `country`, `countrycode`, `osm_key`, `osm_value`, `osm_type` (N=Node, W=Way, R=Relation), `osm_id`, `extent` (bounding box if available), `extra` (additional OSM tags if imported).

**Coordinates** are `[longitude, latitude]` (GeoJSON standard).

## Tag Filtering

Use `osm_tag` parameter (repeatable) to filter by OSM tags:

| Syntax | Meaning |
|--------|---------|
| `osm_tag=key:value` | Include places with this tag |
| `osm_tag=!key:value` | Exclude places with this tag |
| `osm_tag=key` | Include places with this key (any value) |
| `osm_tag=:value` | Include places with this value (any key) |
| `osm_tag=!key` | Exclude places with this key |
| `osm_tag=:!value` | Exclude places with this value |

**Common useful tags:**

| What | Tag |
|------|-----|
| Restaurants | `amenity:restaurant` |
| Pharmacies | `amenity:pharmacy` |
| Hotels | `tourism:hotel` |
| Museums | `tourism:museum` |
| Train stations | `railway:station` |
| Shops | `shop` |
| Streets | `highway` |
| Cities | `place:city` |

Full tag list: [taginfo.openstreetmap.org](https://taginfo.openstreetmap.org/projects/nominatim#tags)

## Layers

Filter by geographic layer (repeatable `layer` param):

| Layer | What it matches |
|-------|----------------|
| `house` | Individual addresses |
| `street` | Streets and roads |
| `locality` | Named places, hamlets |
| `district` | City districts, suburbs |
| `city` | Cities, towns, villages |
| `county` | Counties, provinces |
| `state` | States, regions |
| `country` | Countries |
| `other` | Natural features, POIs |

**Tip:** For address autocomplete, use `layer=house&layer=street` to exclude countries/states from results.

## TypeScript Types

```typescript
interface PhotonFeature {
  type: "Feature";
  geometry: { type: "Point"; coordinates: [number, number] };
  properties: {
    name?: string;
    street?: string;
    housenumber?: string;
    postcode?: string;
    district?: string;
    city?: string;
    county?: string;
    state?: string;
    country?: string;
    countrycode?: string;
    osm_key?: string;
    osm_value?: string;
    osm_type?: "N" | "W" | "R";
    osm_id?: number;
    extent?: [number, number, number, number];
    extra?: Record<string, string>;
  };
}

interface PhotonResponse {
  type: "FeatureCollection";
  features: PhotonFeature[];
}

async function geocode(
  query: string,
  opts?: { lat?: number; lon?: number; lang?: string; limit?: number }
): Promise<PhotonResponse> {
  const params = new URLSearchParams({ q: query });
  if (opts?.lat != null && opts?.lon != null) {
    params.set("lat", String(opts.lat));
    params.set("lon", String(opts.lon));
  }
  if (opts?.lang) params.set("lang", opts.lang);
  if (opts?.limit) params.set("limit", String(opts.limit));

  const res = await fetch(`https://photon.komoot.io/api?${params}`);
  if (!res.ok) throw new Error(`Photon error: ${res.status}`);
  return res.json();
}
```

## Self-Hosting Setup

Requires Java 21+. Download from [GitHub releases](https://github.com/komoot/photon/releases).

```bash
# Download pre-built database (world ~95GB, or use country extract)
wget -O photon-db.tar.bz2 https://download1.graphhopper.com/public/photon-db-latest.tar.bz2
pbzip2 -d photon-db.tar.bz2 && tar xf photon-db.tar

# Run server
java -jar photon.jar serve -listen-ip 0.0.0.0 -listen-port 2322 -cors-any
```

Key server flags: `-default-language`, `-max-results`, `-query-timeout`, `-cors-any`/`-cors-origin`.
