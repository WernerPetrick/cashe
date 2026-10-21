# 0003 — Custom-scheme claim links and OpenStreetMap tiles

- Status: accepted
- Date: 2026-10-20

## Context

ADR 0002 gives every gift a one-time claim link, and the app must open it. Universal links (https App Links on Android, Universal Links on iOS) need a domain we control that serves `assetlinks.json` and `apple-app-site-association`. We don't have one yet.

The place picker uses `flutter_map`, which needs a tile source.

## Decision

- Claim links use the custom scheme **`cashe://claim/<token>`** (`config/cashe.yml` → `claim_url_base`). Android registers it with an intent filter; iOS with `CFBundleURLTypes`.
- The `app_links` package receives the links. Flutter's built-in router deep linking is turned off (`flutter_deeplinking_enabled` / `FlutterDeepLinkingEnabled` = false), because it would route `cashe://claim/<token>` as `/<token>`.
- Some messaging apps don't make custom-scheme links tappable, so the app also has a **"Paste gift link"** screen. It accepts the full link or just the token.
- If someone opens a claim link while signed out, the app signs them in first and then continues with the claim.
- Map tiles come from **OpenStreetMap's standard tile server**, with the app's package name as its user agent and the required attribution on the map. That's fine for development and the demo's light traffic; OSM's tile usage policy rules out heavy production use.
- The place picker never asks for the device's location (location is for the unlock screen only). It searches for places around the centre of the visible map.

## Consequences

- Moving to https links later means changing `claim_url_base`, adding the domain's verification files, and adding an https intent filter. The app's link handling stays the same.
- Before real production traffic, switch to a tile provider that allows it (for example MapTiler or Stadia, with an API key passed as a dart-define).
