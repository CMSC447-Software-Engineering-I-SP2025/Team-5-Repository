import Vapor
import Fluent

struct MovieFavoriteController: RouteCollection {
    let sessionProtected: RoutesBuilder
    
    init(sessionProtected: RoutesBuilder) {
        self.sessionProtected = sessionProtected
    }

    func boot(routes: RoutesBuilder) throws {
        sessionProtected.post("api", "movies", ":movieID", "favorite", use: toggleFavorite)
    }
    
    func toggleFavorite(req: Request) async throws -> Response {
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
        
        // Check if the user has already favorited this movie
        let existingFavorite = try await UserMovieFavorite.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .filter(\.$movie.$id == movieID)
            .first()
        
        if let favorite = existingFavorite {
            // If favorite exists, remove it
            try await favorite.delete(on: req.db)
            return Response(status: .ok, body: .init(string: """
                {"isFavorited": false}
                """))
        } else {
            // If favorite doesn't exist, create it
            let favorite = UserMovieFavorite(userID: try user.requireID(), movieID: movieID)
            try await favorite.save(on: req.db)
            return Response(status: .ok, body: .init(string: """
                {"isFavorited": true}
                """))
        }
    }
} 