import Fluent
import Vapor

struct AuthenticationMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .unique(on: "name")
            .unique(on: "email")
            .create()
        
        try await database.schema(Token.schema)
            .id()
            .field("value", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .unique(on: "value")
            .create()
        
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Token.schema).delete()
        try await database.schema(User.schema).delete()
    }
}
