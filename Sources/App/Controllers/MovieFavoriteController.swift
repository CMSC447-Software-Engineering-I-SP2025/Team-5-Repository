import Vapor
import Fluent

struct MovieFavoriteController: RouteCollection, @unchecked Sendable {
    let sessionProtected: RoutesBuilder
    
    init(sessionProtected: RoutesBuilder) {
        self.sessionProtected = sessionProtected
    }

    func boot(routes: RoutesBuilder) throws {
        sessionProtected.post("api", "movies", ":movieID", "favorite", use: toggleFavorite)
    }
    
    @Sendable
    func toggleFavorite(req: Request) async throws -> [String: Bool] {
        guard let user = try await req.auth.get(Token.self)?.$user.get(on: req.db) else {
            throw Abort(.unauthorized)
        }
        
        guard let movieID = req.parameters.get("movieID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid movie ID")
        }
        
        // Check if movie exists
        guard let movie = try await Movie.find(movieID, on: req.db) else {
            throw Abort(.notFound, reason: "Movie not found")
        }
        // load favorite movies
        _ = try await user.$favoriteMovies.get(on: req.db)

        var retVal = false
        if user.favoriteMovies.contains(where: { $0.id == movieID }) {
            try await user.$favoriteMovies.detach(movie, on: req.db)
        } else {
            try await user.$favoriteMovies.attach(movie, on: req.db)
            retVal = true
        }
        return ["isFavorited": retVal]
    }
} 
