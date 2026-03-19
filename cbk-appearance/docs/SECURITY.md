# Security posture

## Threat model
Clients are hostile. Appearance preview is local convenience only. Persistence is server-owned.

## Controls
- Session nonce to bind one open session to one save attempt
- Server-side normalization of every field
- Allowed model allowlist
- Save rate limiting
- Server-issued authoritative appearance sync event
- Authoritative reapply on resource sync/spawn, with optional periodic enforcement
- Optional first-join auto-open only when no saved record exists
- Optional routing bucket isolation while the editor is open
- Runtime per-model drawable and texture profile validation before save
- No reward/currency/inventory coupling
- No client-side persistence authority

## Runtime variation profiles
- The client builds drawable and texture limits for each configured allowed model and syncs them to the server.
- The server normalizes those profiles and uses them to clamp incoming saves for the matching model.
- If `Config.EnableVariationProfileValidation` is enabled and no synced profile exists for the requested model, the save is rejected.
- This is stronger than static max-value validation, but it is still not perfect cryptographic authority because FiveM ped variation natives remain client-executed.

## Remaining hardening ideas
- Add admin audit log hooks for appearance changes
- Add optional spawn manager integration for first-spawn orchestration
- Add more aggressive anomaly logging around rejected saves and missing model profiles
