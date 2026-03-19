# cbk-appearance API

## Client exports

### OpenCreator()
Requests the server to open the creator for the current player. The client syncs variation profiles first when runtime profile validation is enabled.

### ApplyAppearance(appearance)
Applies a normalized appearance payload client-side.

### GetAppearance()
Returns the current local appearance payload.

## Server exports

### GetSavedAppearance(source)
Returns the server-side saved appearance payload for the given player source.

### HasSavedAppearance(source)
Returns whether the target player currently has a saved database record.

### ApplySavedAppearance(source)
Pushes the saved appearance back to the target client for authoritative reapply.

## Server events

### cbk_appearance:server:requestOpen
Requests a normal editor open for the current player.

### cbk_appearance:server:requestAuthoritativeAppearance
Requests the current authoritative saved appearance for the current player.

### cbk_appearance:server:checkAutoOpen
Checks whether the current player has a saved appearance and opens the editor automatically when `Config.AutoOpenIfNoSavedAppearance` is enabled.

### cbk_appearance:server:syncVariationProfiles(profiles)
Internal event used by the client to send normalized runtime drawable and texture limits for each allowed model.

### cbk_appearance:server:save(payload, nonce)
Saves the current editor payload if the session nonce is valid and rate limits allow it.

## Client events

### cbk_appearance:client:open(appearance, sessionNonce)
Server instructs the client to open creator.

### cbk_appearance:client:saveResult(ok, appearance, err)
Server returns save result.

### cbk_appearance:client:applyAuthoritativeAppearance(appearance)
Server instructs the client to apply the saved authoritative appearance.

## Security notes

- The UI only previews locally.
- Only server-side validated payloads are persisted.
- Save requests are session-bound using a nonce.
- Save requests are rate-limited.
- Model choice is restricted to the configured allowlist.
- Runtime variation profile validation can reject saves if a required model profile is missing.
