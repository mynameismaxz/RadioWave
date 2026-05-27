# Changelog

## 1.0.1

- Added a personalized For You discovery feed based on locally stored listening history.
- Added listening history persistence in `shared_preferences`; the data stays on device.
- Switched Radio Browser networking to `dio` while keeping mirror racing, request deduplication, and TTL caching.
- Updated Android Auto/media notification behavior to use a single play/pause control.
- Added broader service and widget test coverage for favorites, Radio Browser requests, Android Auto browsing, listening history, and For You sorting.
- Added generated launcher icons and current Flutter/Dart guidance docs.

## 1.0.0

- Initial production-preparation release for RadioWave.
- Includes Radio Browser discovery, country filtering, favorites, custom stations, sleep timer, equalizer controls, Android Auto media browsing, and responsive web/mobile UI.
