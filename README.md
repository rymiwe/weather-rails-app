[![codecov](https://codecov.io/gh/rymiwe/weather-rails-app/branch/main/graph/badge.svg)](https://codecov.io/gh/rymiwe/weather-rails-app)

# Weather Rails App

A Rails 8+ weather forecast application featuring:
- SPA-like experience using Hotwire (Turbo/Stimulus) for seamless, reactive interactivity
- Redis-based caching for both geocoding and weather forecasts, maximizing performance and minimizing API usage
- Database-free architecture using Redis exclusively for data persistence
- Nearly 100% code coverage with comprehensive tests at all levels (unit, integration, feature)
- Service-oriented architecture with instance methods for improved testability
- Tests are isolated and avoid global stubs

**Flexible location input:**
- Accepts any format of location (partial or full address, city/state/country/zip). Geocoder disambiguates and the resolved location is shown to the user.
- Temperature units are determined by what is standard for the geocoded location.

---

## Table of Contents
- [Overview](#overview)
- [Live Demo](#live-demo)
- [CI, Coverage, and Deployment](#ci-coverage-and-deployment)
- [Screenshots](#screenshots)
- [Caching Strategy](#caching-strategy)
- [Key Architectural Choices](#key-architectural-choices)
- [Gem Dependencies](#gem-dependencies)
- [Configuration & Environment](#configuration--environment)
- [Running the App](#running-the-app)
- [Testing](#testing)
- [Best Practices & Noteworthy Patterns](#best-practices--noteworthy-patterns)
- [Scalability & Extensibility](#scalability--extensibility)
- [License](#license)

---

## Overview

This app provides weather forecasts for user-supplied locations, with geocoding and weather data fetched from external APIs. It is built for reliability, testability, and developer clarity, following modern Rails conventions and best practices.

---

## Live Demo

[View the deployed app on Heroku](https://weather-rails-app-9087a4c3e26a.herokuapp.com/)

---

## CI, Coverage, and Deployment

- **Continuous Integration:** All commits and pull requests are tested automatically using GitHub Actions. The workflow includes linting, security scans, and a full test suite run.
- **Code Coverage:** Test coverage is measured with SimpleCov and reported to [Codecov.io](https://codecov.io/gh/rymiwe/weather-rails-app) (see badge above).
- **Deployment:** The app is automatically deployed to Heroku on pushes to `main`. No asset precompilation is needed; Tailwind CSS and importmap handle frontend assets.

---

## Screenshots

Below are example screenshots of the UI, showcasing the forecast results for various cities:

![Forecast for Anchorage](docs/screenshots/anchorage.png)
*Forecast result for Anchorage, AK*

![Forecast for Banff](docs/screenshots/banff.png)
*Forecast result for Banff, AB (Canada) — result is cached, showing expiration time*

![Forecast for Cheyenne](docs/screenshots/cheyenne.png)
*Forecast result for Cheyenne, WY — result is cached, showing expiration time*

![Forecast for Phoenix](docs/screenshots/phoenix.png)
*Forecast result for Phoenix, AZ*

---

## Caching Strategy

### Redis-Based Caching
This application uses Redis for all data persistence, with a two-layer caching strategy:
- **Geocoder Cache**: All location lookups (turning a user query into coordinates) are cached via Rails.cache using Redis, as configured in `config/initializers/geocoder.rb`. This drastically reduces external geocoding API requests and speeds up repeat queries.
- **Forecast Cache**: Weather forecasts for specific coordinates are cached in Redis via Rails.cache, with expiry controlled by `WEATHER_CACHE_EXPIRY_MINUTES`. This minimizes calls to the Pirate Weather API and ensures fast, consistent results for users.

Both caches are independent, so a hit in one does not guarantee a hit in the other. This layered approach maximizes efficiency and reliability.

### Forecast Serialization
The `Forecast` class implements `marshal_dump` and `marshal_load` methods to ensure proper serialization when storing in Redis. This approach maintains object integrity while allowing efficient storage and retrieval.

### Result Wrapper Pattern
We use a `ForecastResult` wrapper object that encapsulates:
- The actual `Forecast` object (when available)
- Cache status flag (`from_cache: true/false`)
- Any error messages
- Location name and units information

This pattern provides a clean API between services and controllers, making it clear what data is available and from where.

### Narrative Description
1. **User submits a location** via the UI (e.g., "Portland, OR").
2. **Controller** calls `ForecastService.fetch(query)`.
3. **ForecastService**:
   - Calls `GeocodingService.lookup(query)` to get coordinates.
   - Constructs a cache key from the coordinates.
   - Checks `ForecastCacheService.read(lat, lon)`:
     - If a valid, unexpired forecast is cached, returns a `ForecastResult` with `from_cache: true`.
     - If not, calls `PirateWeatherClient` to fetch a fresh forecast.
   - Saves the new forecast to the cache with an expiry (`WEATHER_CACHE_EXPIRY_MINUTES`).
   - Returns a `ForecastResult` object to the controller.
4. **Controller** extracts data from the `ForecastResult` and renders to the user, showing a cache indicator when applicable.

- **Cache Expiry**: Controlled by `WEATHER_CACHE_EXPIRY_MINUTES` in `.env`.
- **Cache Backend**: Uses Redis exclusively for all environments.
- **Keying**: Cache keys are based on latitude/longitude, ensuring unique entries per location.
- **Security**: No sensitive info is ever cached or exposed.
- **UI Indication**: The UI clearly shows when results come from cache with a badge and expiry countdown.

### Sequence Diagram
```mermaid
sequenceDiagram
  participant User
  participant UI
  participant Controller
  participant ForecastService
  participant GeocodingService
  participant ForecastCacheService
  participant PirateWeatherClient

  User->>UI: Enter location & submit
  UI->>Controller: POST /forecasts
  Controller->>ForecastService: fetch(query)
  ForecastService->>GeocodingService: lookup(query)
  GeocodingService-->>ForecastService: coordinates (lat, lon, location_name, units)
  ForecastService->>ForecastCacheService: read(lat, lon)
  alt Cache hit
    ForecastCacheService-->>ForecastService: cached Forecast object
    ForecastService-->>Controller: ForecastResult(forecast, from_cache: true)
  else Cache miss
    ForecastCacheService-->>ForecastService: nil
    ForecastService->>PirateWeatherClient: fetch_forecast(lat, lon, units)
    PirateWeatherClient-->>ForecastService: raw forecast data
    ForecastService->>Note: Create Forecast object
    ForecastService->>ForecastCacheService: write(lat, lon, forecast)
    ForecastCacheService-->>ForecastService: OK
    ForecastService-->>Controller: ForecastResult(forecast, from_cache: false)
  end
  Controller->>Note: Extract data from ForecastResult
  Controller-->>UI: Render forecast with cache indicator if applicable
  UI-->>User: Display forecast with cache badge if cached
```

---

## Key Architectural Choices
- **SPA with Hotwire**: The app delivers a single-page application (SPA) experience using Hotwire (Turbo and Stimulus). All forecast interactions and UI updates happen seamlessly without full page reloads, resulting in a fast and modern user experience.
- **Database-Free Architecture**: The application operates entirely without a relational database, using Redis exclusively for caching and data persistence, simplifying deployment and operations.
- **Redis-Based Caching**: Both geocoding results and weather forecasts are cached independently using Redis. This two-layer approach ensures minimal redundant API calls and optimal performance.
- **Result Wrapper Pattern**: Uses a `ForecastResult` object to wrap the actual `Forecast` data along with metadata about the operation (from cache, errors, etc.), providing a clean and consistent API between services and controllers.
- **Service Objects with Instance Methods**: `ForecastService`, `GeocodingService`, and `ForecastCacheService` use instance methods with class delegators, improving testability and maintainability.
- **Serialization Support**: The `Forecast` class implements custom Marshal methods to ensure proper serialization when storing in Redis.
- **Visual Cache Indicators**: The UI clearly shows when results come from cache with a badge and expiry countdown, improving transparency.
- **API Client Encapsulation**: All communication with the Pirate Weather API is handled by a dedicated `PirateWeatherClient` class, ensuring single responsibility.
- **Dependency Injection**: External services are injected into service objects, allowing for robust, isolated tests without global stubs or HTTP requests.
- **Explicit Error Handling**: All user-facing errors are caught and displayed cleanly; no stack traces or sensitive info are ever leaked.
- **Constants Module**: Icon mapping and similar logic are centralized in `app/constants` for maintainability.

---

## Gem Dependencies
- **rails**: Modern Rails 8+ framework
- **redis**: Redis for caching across all environments
- **puma**: Web server
- **tailwindcss-rails**: CSS utility framework
- **importmap-rails**: ESM asset management
- **hotwire-rails**: Turbo/Stimulus for reactive UI
- **geocoder**: Geocoding queries
- **faraday**: HTTP client for API calls
- **rspec-rails**: Testing framework
- **capybara**, **selenium-webdriver**: Feature/system tests
- **simplecov**: Code coverage
- **vcr**, **webmock**: HTTP request stubbing (legacy, not required with DI)
- **brakeman**, **rubocop-rails-omakase**: Security and style (dev/test)

---

## Configuration & Environment
- **Geocoder**: Configured in `config/initializers/geocoder.rb` to use `Rails.cache` and prefer US results for ambiguous queries.
- **Cache Expiry**: Set via `WEATHER_CACHE_EXPIRY_MINUTES` in your `.env` file (default: 15 minutes).
- **Forecast API Key**: The Pirate Weather API key is managed securely outside of `.env` (see deployment or secrets setup).
- **Autoload Paths**: `app/constants` is autoloaded for easy access to shared constants.

---

## Running the App
1. **Install dependencies** (using WSL as required):
   ```sh
   wsl -u rymiwe -e bash -ic "bundle install"
   ```

2. **Install and start Redis** (required for caching in all environments):
   ```sh
   # Install Redis in WSL if not already installed
   wsl -u rymiwe -e bash -ic "sudo apt-get update && sudo apt-get install -y redis-server"
   
   # Start the Redis server
   wsl -u rymiwe -e bash -ic "sudo service redis-server start"
   
   # Verify Redis is running
   wsl -u rymiwe -e bash -ic "redis-cli ping"
   # Should return "PONG"
   ```

3. **Configure environment variables**:
   - Copy `.env.example` to `.env` and set `WEATHER_CACHE_EXPIRY_MINUTES` as needed (default is 30 minutes).
   - Set `REDIS_URL` to `redis://localhost:6379/1` if you want to use a different Redis instance.
   - The Pirate Weather API key is securely stored in environment variables. Set `PIRATE_WEATHER_API_KEY` in your environment.

4. **Start the development server** (required for Tailwind CSS):
   ```sh
   wsl -u rymiwe -e bash -ic "bin/dev"
   ```
   This ensures Tailwind CSS is built and live-reloaded during development.

5. Visit [http://localhost:3000](http://localhost:3000)

---

## Testing

- **Run all specs**:
  ```sh
  bundle exec rspec
  ```
- **Coverage**: SimpleCov will generate a report in `coverage/`. The test suite achieves nearly 100% coverage, ensuring robust protection against regressions.
- **Comprehensive Coverage**: Tests exist at all levels—unit, integration, and feature/system—covering services, helpers, controllers, and the full user experience.
- **Test Isolation**: All external dependencies are mocked or injected. No real HTTP requests are made in tests. Geocoder is always stubbed.
- **Feature/Request Specs**: Cover all user input edge cases, error handling, and UI feedback.

---

## Best Practices & Noteworthy Patterns
- **Strict Test Isolation**: No global stubs or VCR cassettes required; all dependencies are injected or mocked at the spec level.
- **Service-Oriented**: Business logic is never in controllers or views.
- **Centralized Constants & Icon Mapping**: All weather condition mappings from Pirate Weather are handled in a single location and mapped to a weather icon set hosted on a CDN for efficient display.

- **Security**: No sensitive info is ever leaked. Brakeman is included for static analysis.
- **Accessibility**: UI is designed to be accessible and clear for all users.
- **Redis-Based Caching**: Uses Redis for caching in all environments (development, test, production) for consistent behavior and scalability.

---

## Scalability & Extensibility
- **Caching**: Minimizes API calls and improves performance.
- **Service decomposition**: Makes the app easy to maintain and extend (e.g., add user accounts, favorites, etc.).
- **Easily extensible**: Add new features or swap out APIs with minimal code changes.

---

## License
MIT
