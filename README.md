
<div align="center">

# 🔎 SearchLab

### Filtering & Advanced Search in Flutter

**An interactive Flutter playground for exploring responsive search experiences, asynchronous requests, pagination, caching, and concurrency safety.**

Built as an educational technical demo around a **cultural catalog** featuring books, authors, and cultural institutions.

[![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![State Management](https://img.shields.io/badge/State%20Management-Cubit-6C47B6)](https://pub.dev/packages/flutter_bloc)
[![Status](https://img.shields.io/badge/Status-Educational%20Prototype-orange)](#project-status)

</div>

## Overview

SearchLab is a small Flutter application designed to **demonstrate how search features behave under realistic UI and network conditions**.

Instead of relying on a deployed backend, it uses a simulated asynchronous catalog API with configurable latency, cancellation, and network failures.

The goal is to make concepts such as **debouncing**, **stale responses**, **infinite scrolling**, and **stale-while-revalidate caching** observable and easy to explain.

> **Scope:** This repository is a frontend-focused learning project. Its API is simulated; it does not send real HTTP requests or provide production authentication.

## Features

| Area | Implemented behavior |
| --- | --- |
| Search | Case-insensitive substring search across book titles and authors |
| Filtering | Single-select filters for cultural center and category; `All` disables a filter |
| Sorting | Newest, oldest, or title |
| Pagination | 12 items per page with infinite-scroll loading and duplicate-ID protection |
| Debouncing | Optional 400 ms delay after text input |
| Request cancellation | `CancelToken`-based cancellation in the simulated transport |
| Stale-response protection | Generation counter to reject outdated results |
| Network simulation | Adjustable latency (0–2000 ms), offline toggle, and forced next-request failure |
| Caching | In-memory cache keyed by search parameters, with first-page stale-while-revalidate behavior |
| UI states | Initial loading, load-more indicator, empty results, error banner, and retry |
| Session demo | Two simulated users with separate in-memory favorite sets |

The sample catalog contains **120 generated books** with titles, authors, centers, categories, and publication years.

## App Screens

| Screen | Purpose |
| --- | --- |
| **Search** | Search, filter, sort, browse paginated results, and favorite books |
| **Network** | Change simulated latency and toggle debounce, cancellation, and generation protection |
| **Cache** | Enable/disable memory caching, simulate offline mode, refresh, clear cache, and force a failure |
| **Session** | Switch between two demo users and inspect their separate favorites |

<!-- Add screenshots after capturing them from your running app.

## Screenshots

| Search | Network | Cache | Session |
| --- | --- | --- | --- |
| ![](screenshots/search.png) | ![](screenshots/network.png) | ![](screenshots/cache.png) | ![](screenshots/session.png) |

-->

## Tech Stack

- **Flutter / Dart** — UI and asynchronous programming
- **flutter_bloc (Cubit)** — search state management
- **Dio types** — `CancelToken` and `DioException` for cancellation/error simulation
- **Material 3** — application UI
- **In-memory mock data** — no backend or database required to run the current demo

> A `Dio` instance is present in the prototype, but the fake API does **not** perform `dio.get()` or any other real HTTP call.

## Getting Started

### Prerequisites

- Flutter SDK installed and configured
- Dart SDK (included with Flutter)
- Android emulator, connected device, or another enabled Flutter target

### Run locally

```bash
git clone https://github.com/ibrahem137/flutter-searchlab.git
cd flutter-searchlab
flutter pub get
flutter run
```

> **Repository URL:** The clone command assumes the repository is published at the address above. Until then, open your existing local project directory and run `flutter pub get` followed by `flutter run`.

To inspect the code before presenting it:

```bash
dart format lib
flutter analyze
```

## How Search Works

```text
User input / filter change
          |
          v
  SearchPage (Flutter UI)
          |
          v
  SearchCubit.updateQuery()
          |
          +--> invalidate older generation
          +--> cancel pending debounce / previous request (if enabled)
          +--> debounce text input (400 ms, if enabled)
          |
          v
    SearchCubit.refresh()
          |
          +--> read cached first-page results (if available)
          +--> emit loading / stale-cache state
          |
          v
    FakeCatalogApi.fetch()
          |
          +--> simulated latency and network conditions
          +--> filter + sort + paginate mock books
          |
          v
   validate generation
          |
          v
  update memory cache + emit SearchState
          |
          v
  BlocBuilder renders results
```

### Why both cancellation and a generation guard?

A user can change the query while a previous request is still running. A late response from an older query must not overwrite the newest results.

- **Cancellation** attempts to stop unnecessary work.
- **Generation validation** checks whether a completed response still belongs to the current search cycle.

Debouncing reduces the number of requests, but **does not by itself prevent race conditions**.

### Query keys vs. generations

- A **query key** identifies the search parameters (`text`, `center`, `category`, `sort`) for cache lookup.
- A **generation** identifies the current execution cycle and is used to discard stale responses.

These solve different problems: *data identity* versus *response validity*.

## Live Demo Walkthrough

1. **Basic search:** Search for `History` or `Artificial`, then change the center, category, and sort order.
2. **Debouncing:** In **Network**, reset the request counter, disable debouncing, and type several characters quickly. Re-enable it and compare. Actual counts depend on typing timing.
3. **Concurrency:** Increase latency, rapidly change the search query, and compare behavior with cancellation and generation protection enabled or disabled. Because delays are simulated rather than scripted per request, a visible out-of-order race is **not guaranteed** on every attempt.
4. **Pagination:** Clear the filters and scroll toward the bottom to load the next 12 books.
5. **Cache fallback:** While online, load a search. In **Cache**, enable offline mode and refresh the *same* query. Cached first-page results remain visible, labeled as offline cache, alongside the network error.
6. **User-scoped favorites:** Favorite books under **User A**, switch to **User B**, and verify that their favorites are separate.

## Refactored Source

The app now uses feature-first folders with separate search data, domain models,
Cubit/state, pages, and focused book/filter widgets. All four original labs and
their teaching controls remain available. See [REFACTORING_REPORT.md](REFACTORING_REPORT.md)
for the initial audit, decisions, complete file inventory, tests, and validation limits.

18 automated test cases are included. They have **not been executed** in the
refactoring environment because Flutter and Dart executables are unavailable.
Run the following from the project directory before accepting the changes:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
```

`pubspec.lock` retains the original resolution; `flutter pub get` must refresh it
and generated platform plugin registrants after removal of unused SQLite/codegen
packages. No new dependency was introduced.

## Project Status

**Educational prototype — not production-ready.**

The following are **not implemented** in the current version:

- Real backend/API integration or actual HTTP transport
- Persistent Drift/SQLite caching and offline search over stored records
- Authentication, OAuth/OIDC, secure token storage, or production session isolation
- Multi-select filters, range filters, Arabic text normalization, or relevance ranking
- Integration tests on a device/browser
- A deterministic, instrumented race-condition demonstration

### Known Limitations

- Memory cache stores **only the first page** per query and is lost when the app is terminated.
- Favorites are isolated in UI memory only, not in persistent storage or authenticated sessions.
- The mock data is generated periodically, so its distributions are not representative of a real catalog.

## Possible Next Steps

- Connect a real paginated REST API through a repository abstraction
- Add persistent caching and offline search using Drift/SQLite
- Add robust query normalization, richer filter combinations, and accessible Arabic/RTL UI
- Execute the included unit/widget tests in a Flutter SDK environment
- Add deterministic request timing and observability for live demonstrations

## Author

**Ibrahem Alhuossien**  
Flutter Developer · Information Engineering Student

- [GitHub](https://github.com/ibrahem137)
- [Portfolio](https://ibrahem-portfolio.web.app)

---

<div align="center">
  <sub>Built to learn, test, and explain advanced search behavior in Flutter.</sub>
</div>
