# Google Play Data Safety Draft

Use this as a starting point when filling the Play Console Data safety form.

## Current App Behavior

- No account creation.
- No ads SDK.
- No analytics SDK.
- No crash reporting SDK.
- Favorites, custom stations, playback state, theme, equalizer settings, and listening history for the For You feed are stored locally with `shared_preferences`.
- Station discovery uses the public Radio Browser API.
- Playback connects directly to selected third-party stream URLs, including some HTTP streams.

## Suggested Data Safety Answers

- Data collected: No, assuming no analytics or crash reporting SDK is added before release.
- Data shared: No, by the app developer. The app connects users to third-party radio stream providers when playback is requested.
- Security practices: Data is not transmitted by RadioWave-owned backend services because there is no RadioWave backend.
- Data deletion: Users can remove favorites/custom stations in app. Uninstalling the app removes locally stored preferences and listening history.

## Before Submission

- Add the final hosted Privacy Policy URL.
- Re-check this draft if analytics, crash reporting, login, purchases, or any backend service is added.
- Confirm the target audience and content rating in Play Console.
