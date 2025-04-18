[![codecov](https://codecov.io/gh/rymiwe/weather-rails-app/branch/main/graph/badge.svg)](https://codecov.io/gh/rymiwe/weather-rails-app)

# Weather Rails App

A Rails 8+ weather forecast application featuring:
- SPA-like experience using Hotwire (Turbo/Stimulus) for seamless, reactive interactivity
- Multi-layer caching for both geocoding and weather forecasts, maximizing performance and minimizing API usage
- Nearly 100% code coverage with comprehensive tests at all levels (unit, integration, feature)
- Service-oriented architecture for clarity and maintainability
- Tests are isolated and avoid global stubs

**Flexible location input:**
- Accepts any format of location (partial or full address, city/state/country/zip). Geocoder disambiguates and the resolved location is shown to the user.
- Temperature units are determined by what is standard for the geocoded location.

---

## Table of Contents
- [Overview](#overview)
- [CI, Coverage, and Deployment](#ci-coverage-and-deployment)
- [Live Demo](#live-demo)
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

## CI, Coverage, and Deployment

- **Continuous Integration:** All commits and pull requests are tested automatically using GitHub Actions. The workflow includes linting, security scans, and a full test suite run.
- **Code Coverage:** Test coverage is measured with SimpleCov and reported to [Codecov.io](https://codecov.io/gh/rymiwe/weather-rails-app) (see badge above).
- **Deployment:** The app is automatically deployed to Heroku on pushes to `main`. No asset precompilation is needed; Tailwind CSS and importmap handle frontend assets.

## Live Demo

[View the deployed app on Heroku](https://weather-rails-app-9087a4c3e26a.herokuapp.com/)

## Overview
This app provides weather forecasts for user-supplied locations, with geocoding and weather data fetched from external APIs. It is built for reliability, testability, and developer clarity, following modern Rails conventions and best practices.

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

### Multi-Layer Caching
This application uses a two-layer caching strategy:
- **Geocoder Cache**: All location lookups (turning a user query into coordinates) are cached via Rails.cache, as configured in `config/initializers/geocoder.rb`. This drastically reduces external geocoding API requests and speeds up repeat queries.
- **Forecast Cache**: Weather forecasts for specific coordinates are also cached via Rails.cache, with expiry controlled by `WEATHER_CACHE_EXPIRY_MINUTES`. This minimizes calls to the Pirate Weather API and ensures fast, consistent results for users.

Both caches are independent, so a hit in one does not guarantee a hit in the other. This layered approach maximizes efficiency and reliability.

### Narrative Description
1. **User submits a location** via the UI (e.g., "Portland, OR").
2. **Controller** calls `ForecastService.fetch(query)`.
3. **ForecastService**:
   - Calls `GeocodingService.lookup(query)` to get coordinates.
   - Constructs a cache key from the coordinates.
   - Checks `ForecastCacheService.read(lat, lon)`:
     - If a valid, unexpired forecast is cached, returns it immediately.
     - If not, calls `PirateWeatherClient` to fetch a fresh forecast.
   - Saves the new forecast to the cache with an expiry (`WEATHER_CACHE_EXPIRY_MINUTES`).
   - Returns the forecast and location info to the controller.
4. **Controller** renders the result or error to the user.

- **Cache Expiry**: Controlled by `WEATHER_CACHE_EXPIRY_MINUTES` in `.env`.
- **Cache Backend**: Uses Rails.cache (SolidCache by default, easily swappable for Redis in production).
- **Keying**: Cache keys are based on latitude/longitude, ensuring unique entries per location.
- **Security**: No sensitive info is ever cached or exposed.

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
  GeocodingService-->>ForecastService: coordinates (lat, lon)
  ForecastService->>ForecastCacheService: read(lat, lon)
  alt Cache hit
    ForecastCacheService-->>ForecastService: cached forecast
    ForecastService-->>Controller: forecast (from cache)
  else Cache miss
    ForecastCacheService-->>ForecastService: nil
    ForecastService->>PirateWeatherClient: fetch_forecast(lat, lon)
    PirateWeatherClient-->>ForecastService: forecast data
    ForecastService->>ForecastCacheService: write(lat, lon, forecast)
    ForecastCacheService-->>ForecastService: OK
    ForecastService-->>Controller: forecast (fresh)
  end
  Controller-->>UI: Render forecast or error
```

---

## Key Architectural Choices
- **SPA with Hotwire**: The app delivers a single-page application (SPA) experience using Hotwire (Turbo and Stimulus). All forecast interactions and UI updates happen seamlessly without full page reloads, resulting in a fast and modern user experience.
- **Multi-Layer Caching**: Both geocoding results and weather forecasts are cached independently using Rails.cache. This two-layer approach ensures minimal redundant API calls and optimal performance for both location and forecast lookups.
- **Service Objects**: `ForecastService`, `GeocodingService`, and `ForecastCacheService` encapsulate business logic, keeping controllers thin and views simple.
- **API Client Encapsulation**: All communication with the Pirate Weather API is handled by a dedicated `PirateWeatherClient` class. This ensures single responsibility, easy mocking for tests, and clean separation from business logic.
- **Dependency Injection**: External services (like Geocoder) are injected into service objects, allowing for robust, isolated tests without global stubs or HTTP requests.
- **Explicit Error Handling**: All user-facing errors are caught and displayed cleanly; no stack traces or sensitive info are ever leaked.
- **Caching**: Forecasts are cached to minimize API calls, with cache expiry controlled via environment variable (`WEATHER_CACHE_EXPIRY_MINUTES`).
- **Constants Module**: Icon mapping and similar logic are centralized in `app/constants` for maintainability.

---

## Gem Dependencies
- **rails**: Modern Rails 8+ framework
- **pg**: PostgreSQL database
- **solid_cache**: Rails.cache adapter
- **solid_queue**: ActiveJob adapter
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
1. **Install dependencies** (from WSL terminal, as required):
   ```sh
   bundle install
   ```
2. **Set up the database**:
   ```sh
   rails db:setup
   ```
3. **Configure environment variables**:
   - Copy `.env.example` to `.env` and set `WEATHER_CACHE_EXPIRY_MINUTES` as needed. (No API keys are stored here.)
   - The Pirate Weather API key is securely stored in [Rails credentials](https://guides.rubyonrails.org/security.html#custom-credentials). See below for details.
4. **Start the development server** (required for Tailwind CSS):
   ```sh
   bin/dev
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
- **Scalable Caching**: Easily switch to Redis for production by changing Rails.cache backend.

---

## Scalability & Extensibility
- **Caching**: Minimizes API calls and improves performance.
- **Service decomposition**: Makes the app easy to maintain and extend (e.g., add user accounts, favorites, etc.).
- **Easily extensible**: Add new features or swap out APIs with minimal code changes.

---

## License
MIT
