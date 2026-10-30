# 0006 — Real-world place search with Photon

- Status: accepted
- Date: 2026-10-30

## Context

When creating a spot, step 2 ("Where can this be spent?") has a search box. It only filtered places already saved in Cashe, so a real shop, school or café could only be added by finding it on the map and long-pressing. People expect to type a place's name and find it.

That needs an outside place search. The map already uses OpenStreetMap tiles (ADR 0003). The privacy rules say the device's location is only used on the unlock screen.

## Decision

- Use **komoot's public Photon API** (`https://photon.komoot.io/api/`), a search over OpenStreetMap data. It needs no key and no new gem, allows search-as-you-type, and can bias results toward a point.
- The app never calls Photon directly. It calls **`GET /api/v1/place_searches?q=…&near=lat,lng`**, and Rails asks Photon (`PlaceSearch::Photon` in `lib/place_search/`, behind `Places::Search`). It returns at most 8 `{ name, address, latitude, longitude }` results. The endpoint is rate-limited to 30 searches a minute per user, and answers 503 `place_search_unavailable` when Photon can't be reached.
- `near` is the **map's centre** (step 2 uses the place picker's starting point), never the device's location. It is filtered from the logs like other coordinates. Photon receives only the query and that centre.
- Tuning: `zoom=10` and `location_bias_scale=0.1` put nearby results first but still find places elsewhere. A bounding box would hide every place outside the starting city. Streets (`osm_tag=!highway`) are left out: a whole street is no centre for a geofence, and they crowded out real places for words like "school".
- A result is not a Cashe place yet. Tapping one opens the existing "New place" sheet, with its name filled in, at the result's point. The user sets the zone and dwell time, and `POST /places` saves it. Saved places that match the query are still listed first.
- The app searches once typing pauses (400 ms) and only for 3+ characters. Shorter queries only filter saved places.
- The URL is configurable with `CASHE_PLACE_SEARCH_URL` (`config/cashe.yml`).

## Consequences

- Coverage is OpenStreetMap's: well-known shops, schools and cafés are there, but many small businesses and house numbers (especially in South Africa) are missing. Long-press on the map still covers those. Category words ("bicycle shop") match names, not shop types, so they work poorly.
- The public Photon instance is fair-use only, with no guarantees. That's fine for the demo. Before real traffic, self-host Photon or move to a commercial geocoder (Mapbox, Google Places); only `PlaceSearch::Photon` would change.
- Search queries reach komoot. They hold no personal data beyond what the user types, together with the map centre.
