# SearchLab — Flutter Advanced Search Demo

Interactive educational app for a cultural catalog. No backend required.

## Run

```bash
flutter create --platforms=android,ios,windows .
flutter pub get
flutter run
```

For Windows desktop, use `flutter run -d windows` (Windows desktop tooling required). For Android use an emulator/device. For web, run `flutter create --platforms=web .` and `flutter run -d chrome`; the current app uses only in-memory caching.

## Implemented

- Search by title/author; center/category filtering; sorting
- Fake paginated API (120 demo books), infinite scrolling
- Debouncing, Dio CancelToken, generation guard; toggle switches
- Configurable simulated latency, offline and failure modes
- Memory cache and stale-while-revalidate on first page
- Two simulated user profiles with isolated in-memory favorites
- Cubit state management, loading/error/empty/retry

## Explicitly not yet implemented

- Persistent Drift/SQLite cache and offline search of persisted records
- Real API / OAuth authentication / secure token storage
- Multi-select/range filters, query normalization, advanced relevance
- Automated tests and full Clean Architecture split
- Instrumented deterministic race-condition demo

## Demo walkthrough

1. Search for `Artificial`, select center, change sort.
2. Network tab: turn off debounce; type quickly and observe request counter (refresh tab to view latest counter).
3. Turn protections back on; use latency slider and change filters rapidly.
4. Cache tab: populate online cache, toggle offline, refresh search, inspect `offline cache` source.
5. Favorite a book, switch between User A and User B.

This is a runnable starter lab, not a production application.
