# movies-api

An API in Swift using Vapor4, Fluent, and PostgreSQL for data.

### Environment setup
Read through [SETUP](SETUP.md) instructions

### Building
Clone repo first
```bash
git clone git@github.com:outitech/movies-api.git
cd movies-api
```

Build
```bash
swift build
```

Before running, you need to run the migration
```bash
swift run App migrate
```

Run the app
```bash
swift run [App]
```