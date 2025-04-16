# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

## Scalability
- Caching minimizes API calls
- Service decomposition for maintainability
- Easily extensible for more features (user accounts, favorites, etc.)

## Caching in Development vs Production

In this project, forecast caching is implemented using the database for simplicity and ease of development. In a real production environment, Redis (or a similar in-memory cache) is strongly recommended for caching because:
- Redis provides much faster read/write performance than a relational database for cache operations.
- Redis is designed for high-concurrency and can efficiently handle many simultaneous cache requests.
- Using an external cache like Redis keeps your cache resilient to web server restarts and enables easy scaling across multiple app servers.

For this codebase, you can swap the caching backend to Redis with minimal changes if deploying to production.

## License
MIT

* Deployment instructions

* ...
