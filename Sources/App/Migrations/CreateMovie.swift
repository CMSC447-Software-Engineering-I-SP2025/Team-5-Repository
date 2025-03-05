import Fluent

struct CreateMovie: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("movies")
            .id()
            .field("title", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("movies").delete()
    }
}
