# CBK Appearance #
as of 04/18/2026

Standalone GTA Online-style appearance creator/editor for FiveM.

Current resource version: `v1.7.0`

## Features
- Standalone resource with no framework dependency
- Freemode male and female support through a configurable model allowlist
- Heritage blending, 20 face feature sliders, hair, eye color, overlays, clothing, and props
- Camera presets for `full`, `head`, `torso`, `feet`, `left`, and `right`
- Camera orbit and zoom from buttons, mouse drag, mouse wheel, and keyboard look input
- Server-side save validation, session nonces, and rate limiting
- Server-authoritative appearance reapply on spawn and resource sync
- Optional first-join auto-open when no saved appearance exists
- Optional extended editor mode for extra overlays, clothing components, and props
- Per-model drawable and texture clamping using synced runtime variation profiles
- Optional creator routing bucket isolation

## Requirements
- FiveM server with OneSync enabled
- `oxmysql`

## Install
1. Import sql/cbk-appearance.sql
2. Place `cbk-appearance` in your `resources` folder
3. Ensure `oxmysql` starts before `cbk-appearance`
4. Add `ensure cbk-appearance` to your server config

## Usage
- Open the editor with `/appearance`
- Save writes a normalized appearance payload to the `cbk_appearance` table
- Cancel restores the pre-editor baseline
- If `Config.AutoOpenIfNoSavedAppearance` is enabled, players without a saved record are prompted automatically once per session

## Controls
- Section buttons switch editor categories
- Camera buttons switch between preset views
- `Orbit` buttons rotate the camera around the player
- `Zoom In` and `Zoom Out` change camera distance
- Mouse drag or right-drag orbits the camera
- Mouse wheel zooms when not hovering the controls grid or form inputs
- `Esc` closes the creator and cancels unsaved changes

## Configuration
Main settings live in shared/config.lua

Important options:
- `Config.Command`: chat command used to open the creator
- `Config.DefaultModel`: fallback freemode model
- `Config.AllowFemaleModel`: disables female model selection when false
- `Config.AllowedModelNames`: allowed model names used for UI choices and variation sync
- `Config.SaveCooldownMs`: save cooldown per player
- `Config.ServerAuthoritative`: enables server-owned appearance re-sync
- `Config.AuthoritativeReapplyMs`: interval for periodic authoritative reapply outside the editor
- `Config.EnableVariationProfileValidation`: clamps saves against runtime male/female drawable and texture limits
- `Config.AutoOpenIfNoSavedAppearance`: opens the creator automatically for players without a saved record
- `Config.ShowExtendedEditorOptions`: shows the extended overlay, clothing, and prop controls
- `Config.BasicEditorOverlaySlots` / `Config.ExtendedEditorOverlaySlots`: controls which overlay IDs appear in each mode
- `Config.BasicEditorComponentSlots` / `Config.ExtendedEditorComponentSlots`: controls which clothing component slots appear in each mode
- `Config.BasicEditorPropSlots` / `Config.ExtendedEditorPropSlots`: controls which prop slots appear in each mode
- `Config.EnableRoutingBucketIsolation`: temporarily moves players to `Config.CreatorBucket` while editing

## Persistence And Authority
- Data is stored by player identifier in the `cbk_appearance` table
- Saves are validated and normalized on the server
- The server reapplies the saved appearance after spawn, resource start, and periodic authority checks
- The UI still previews locally, but persistence and final saved state remain server-owned

## Security
- Save requests are session-bound with a nonce
- Model choice is restricted to the configured allowlist
- Saves are rate-limited
- Per-model variation profiles clamp drawables and textures before persistence
- Saves can be rejected if the required variation profile has not been synced yet

More detail:
- docs/API.md
- docs/SECURITY.md

## Client Exports
- `exports['cbk-appearance']:OpenCreator()`
- `exports['cbk-appearance']:ApplyAppearance(appearance)`
- `exports['cbk-appearance']:GetAppearance()`

## Server Exports
- `exports['cbk-appearance']:GetSavedAppearance(source)`
- `exports['cbk-appearance']:HasSavedAppearance(source)`
- `exports['cbk-appearance']:ApplySavedAppearance(source)`

## Notes
- Hair stays separate from clothing component slot `2`
- Runtime variation profiles are synced per allowed model and cached per player session
- If extended editor mode is disabled, the UI falls back to the smaller curated slot set
