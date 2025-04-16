import Fluent
import Vapor

struct CreateUserMovieFavorite: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_movie_favorites")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("movie_id", .int, .required, .references("movies", "id", onDelete: .cascade))
            .unique(on: "user_id", "movie_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_movie_favorites").delete()
    }
} 