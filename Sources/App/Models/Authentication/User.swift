import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Siblings(through: UserMovieFavorite.self, from: \.$user, to: \.$movie)
    var favoriteMovies: [Movie]
    
    init() { }
    init (id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}

extension User {
    func generateToken() throws -> Token {
        return try Token(value: [UInt8].random(count: 16).base64,
                         userID: self.requireID())
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

// Favorites
extension User {
    func favoriteMovieIds(on db: Database) async throws -> [Int] {
        try await UserMovieFavorite.query(on: db)
            .filter(\.$user.$id == requireID())
            .all(\.$movie.$id)
    }
    func favoriteMoviewTitles(on db: Database) async throws -> [String] {
        let ids = try await UserMovieFavorite.query(on: db)
            .filter(\.$user.$id == requireID())
            .all(\.$movie.$id)
        return try await Movie.query(on: db)
            .filter(\.$id ~~ ids)
            .all(\.$title)
    }
}
