# World Capitals Explorer

A Flutter application that fetches country data from a public GraphQL API and displays world capitals on an interactive Mapbox map.

---

## Features - Functionalities

- Interactive Mapbox map with circle markers for each world capital
- Markers color-coded by continent with an inline legend
- Tap any marker to view country details: capital, currency, languages
- Full error handling for both network failures and Mapbox map load errors, with retry support
- Graceful handling of countries without coordinate data (excluded from map, not crashed)

---

## Architecture and folder structure

The project follows **Clean Architecture** principles with a feature-based folder structure.
```
lib/
├── core/
│   ├── cubit/          → MapCubit, MapState
│   ├── di/             → dependency injection (get_it)
│   ├── graphql/        → GraphQL client setup, query definitions
│   ├── repositories/   → abstract interface + concrete implementation
│   └── services/       → CapitalsService (local JSON asset)
├── models/             → Country entity
├── screens/            → MapScreen, ErrorView
└── widgets/            → CountryBottomSheet, ContinentLegend
```

### Key decisions

**GraphQL with `graphql_flutter`** \
The Countries API (`countries.trevorblades.com`) exposes a GraphQL endpoint. GraphQL was used as required by the brief — it allows the client to request exactly the fields needed, avoiding over-fetching. The `GraphQLClient` is configured with `InMemoryStore` caching, so repeated queries within a session avoid unnecessary network calls.

**Coordinate data strategy** \
The Countries GraphQL API does not provide geographic coordinates. Capital coordinates are sourced from a bundled JSON asset (`assets/data/capitals.json`, derived from the public `mledoze/countries` dataset). The asset uses country centroid coordinates as an approximation for capital position — accurate enough for map display purposes. Countries without a coordinate match are excluded from the map rather than shown at incorrect positions. This decision is documented here intentionally: it reflects a pragmatic, real-world trade-off rather than a limitation.

**State management: Cubit** \
`flutter_bloc` with Cubit was chosen over full BLoC because the data flow is linear — there are no complex event transformations or debounce requirements. Cubit reduces boilerplate while maintaining the same unidirectional data flow guarantees. States: `MapInitial`, `MapLoading`, `MapLoaded`, `MapError`.

**Dependency injection: get_it** \
Dependencies are registered in `injection.dart` using `registerLazySingleton` for shared objects (`GraphQLClient`, `CountriesRepository`) and `registerFactory` for stateful objects (`MapCubit`). This separation ensures the Cubit is never accidentally shared across screens.

**Repository pattern** \
`CountriesRepository` is an abstract interface implemented by `CountriesRepositoryImpl`. The Cubit depends on the interface, not the concrete class — this is what makes the unit tests possible without hitting real network or filesystem.

**Error handling** \
Two independent error layers are handled:
- GraphQL errors (network, malformed response) → full-screen `ErrorView` with retry
- Mapbox map load errors (invalid token, no connection) → full-screen `ErrorView` with map widget reset via `UniqueKey`

**Mapbox integration** \
The `MapWidget` is kept in the widget tree at all times (via `Visibility`) rather than conditionally rendered. This avoids recreating the native map view on state changes, which is expensive. Markers are added via `CircleAnnotationManager.createMulti()` in a single native call rather than looping, to minimize Platform Channel overhead.

---


## Setup and personal takes on the assignment
### Requirements

- Flutter 3.x
- A free Mapbox account — [account.mapbox.com](https://account.mapbox.com)

---

### 1. Mapbox Secret Token (required for Android build)

The Mapbox Android SDK is distributed via a private Maven registry that requires authentication at build time. This token **must never be committed** — it lives outside the project.

Create a secret token with `DOWNLOADS:READ` scope at [account.mapbox.com/access-tokens](https://account.mapbox.com/access-tokens).

**macOS / Linux:**
```bash
mkdir -p ~/.gradle
echo "MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token" >> ~/.gradle/gradle.properties
```

**Windows (Command Prompt):**
```cmd
mkdir %USERPROFILE%\.gradle
echo MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token >> %USERPROFILE%\.gradle\gradle.properties
```

---

### 2. Mapbox Public Token

The public token is already present in the codebase:
- `lib/main.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

If the token has expired, replace it with your own `pk.` token from [account.mapbox.com](https://account.mapbox.com).

---

### 3. Install dependencies and run
```bash
flutter pub get
cd ios && pod install && cd ..   # iOS only — skip on Windows
flutter run
```

---

## Testing

Unit tests cover `CountriesRepositoryImpl` — the layer responsible for combining GraphQL data with local coordinate data.
```bash
flutter test
```

Tests use `mocktail` to mock both `GraphQLClient` and `CapitalsService`, ensuring no network or filesystem access occurs during tests. This was my first experience writing unit tests in Flutter — the implementation is intentionally focused on the most critical business logic rather than aiming for full coverage.

**Test cases:**
- Returns correct `Country` entities on successful GraphQL response
- Country with known capital correctly receives coordinates from the local asset
- Country with unknown capital has `hasCoordinates == false` and null lat/lng
- Throws `Exception` when GraphQL response contains errors

---

## Notes

- Tested on Android only. iOS configuration is in place (`Info.plist`, `Podfile` with `platform :ios, '14.0'`) and should work, but has not been verified on a physical device or simulator.