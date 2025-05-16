# movies-api

An API in Swift using Vapor4, Fluent, and PostgreSQL for data.

### Environment setup
Read through [SETUP](SETUP.md) instructions

### Building for development
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

After running the migration, we can import data.  (If this fails, just re-run it, there's a small race condition on initial imports)
```bash
swift run App import
```

Run the app
```bash
swift run [App]
```


### Building for Deployment
Install [Docker](https://docs.docker.com/desktop/)

Clone repo
```bash
git clone git@github.com:outitech/movies-api.git
cd movies-api
```

Build docker image.  This may take 5+ minutes
```bash
docker compose build
```

Bring up containers. This may take a few minutes
```bash
docker compose up app db elasticsearch ollama
```

Run DB migration.
```bash
docker compose run migrate
```

Import data into PSQL.  This may take a few minutes
```bash
docker compose run import
```

Optional:  Uncomment the section in `docker-compose.yml` that relates to GPU usage if on Windows

Import data into ElasticSearch/Ollama.  This will take a while, get some coffee (GPU speeds it up)
```bash
docker compose run loades
```


