import Fluent

struct CreateInitialTables: AsyncMigration {
    func prepare(on database: Database) async throws {
        // movie collection
        try await database.schema("collections")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("poster_path", .string)
            .field("backdrop_path", .string)
            .create()
        
        // Movies
        try await database.schema("movies")
            .field("id", .int, .identifier(auto: true))
            .field("adult", .bool, .required)
            .field("backdrop_path", .string)
            .field("belongs_to_collection", .int, .references("collections", "id"))
            .field("budget", .int, .required)
            .field("homepage", .string, .required)
            .field("imdb_id", .string, .required)
            .field("origin_country", .array(of: .string), .required)
            .field("original_language", .string, .required)
            .field("original_title", .string, .required)
            .field("overview", .string, .required)
            .field("popularity", .double, .required)
            .field("poster_path", .string, .required)
            .field("release_date", .date, .required)
            .field("revenue", .int, .required)
            .field("runtime", .int, .required)
            .field("status", .string, .required)
            .field("tagline", .string, .required)
            .field("title", .string, .required)
            .field("video", .bool, .required)
            .field("vote_average", .double, .required)
            .field("vote_count", .int, .required)
            .create()
        
        // Cast
        try await database.schema("people")
            .field("id", .int, .identifier(auto: true))
            .field("adult", .bool, .required)
            .field("gender", .int, .required)
            .field("known_for_department", .string, .required)
            .field("name", .string)
            .field("original_name", .string, .required)
            .field("popularity", .double, .required)
            .field("profile_path", .string)
            .create()
        
        try await database.schema("movie_cast")
            .id()
            .field("movie_id", .int, .required, .references("movies", "id", onDelete: .cascade))
            .field("cast_id", .int, .required, .references("people", "id", onDelete: .cascade))
            .field("movie_cast_id", .int, .required)
            .field("character", .string, .required)
            .field("cast_order", .int, .required)
            .field("credit_id", .string, .required)
            .unique(on: "movie_id", "cast_id", "credit_id")
            .create()
        
        
        try await database.schema("movie_director")
            .id()
            .field("movie_id", .int, .required, .references("movies", "id", onDelete: .cascade))
            .field("director_id", .int, .required, .references("people", "id", onDelete: .cascade))
            .field("credit_id", .string, .required)
            .field("department", .string, .required)
            .field("job", .string, .required)
            .unique(on: "movie_id", "director_id", "credit_id")
            .create()
        
        // Genres
        try await database.schema("genres")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .create()
        
        try await database.schema("movie_genres")
            .id()
            .field("movie_id", .int, .required, .references("movies", "id", onDelete: .cascade))
            .field("genre_id", .int, .required, .references("genres", "id", onDelete: .cascade))
            .unique(on: "movie_id", "genre_id")
            .create()
        
        
        // Production Companies
        try await database.schema("production_companies")
            .field("id", .int, .identifier(auto: true))
            .field("logo_path", .string)
            .field("name", .string, .required)
            .field("origin_country", .string, .required)
            .create()
        
        try await database.schema("movie_production_company")
            .id()
            .field("movie_id", .int, .required, .references("movies", "id", onDelete: .cascade))
            .field("production_company_id", .int, .required, .references("production_companies", "id", onDelete: .cascade))
            .unique(on: "movie_id", "production_company_id")
            .create()
        
        // Production Countries
        try await database.schema("production_countries")
            .id()
            .field("iso_3166_1", .string, .required)
            .field("name", .string, .required)
            .unique(on: "iso_3166_1")
            .create()
        
        try await database.schema("movie_production_country")
            .id()
            .field("movie_id", .int, .required, .references("movies", "id", onDelete: .cascade))
            .field("production_country_id", .uuid, .required, .references("production_countries", "id", onDelete: .cascade))
            .unique(on: "movie_id", "production_country_id")
            .create()
        
        // Spoken Languages
        try await database.schema("spoken_languages")
            .id()
            .field("iso_639_1", .string, .required)
            .field("english_name", .string, .required)
            .field("name", .string, .required)
            .unique(on: "iso_639_1")
            .create()
        
        try await database.schema("movie_spoken_language")
            .id()
            .field("movie_id", .int, .required, .references("movies", "id", onDelete: .cascade))
            .field("spoken_language_id", .uuid, .required, .references("spoken_languages", "id", onDelete: .cascade))
            .unique(on: "movie_id", "spoken_language_id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try? await database.schema("movie_director").delete()
        try? await database.schema("people").delete()
        try? await database.schema("movie_genres").delete()
        try? await database.schema("genres").delete()
        try? await database.schema("movie_production_company").delete()
        try? await database.schema("production_companies").delete()
        try? await database.schema("movie_production_country").delete()
        try? await database.schema("production_countries").delete()
        try? await database.schema("movie_spoken_language").delete()
        try? await database.schema("spoken_languages").delete()
        try? await database.schema("movie_cast").delete()
        try? await database.schema("movies").delete()
        try? await database.schema("collections").delete()
    }
}
