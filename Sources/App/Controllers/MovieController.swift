import Fluent
import Vapor

struct MovieController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let movies = routes.grouped("movies")

        movies.get(use: self.index)
        movies.post(use: self.create)
        movies.group(":movieID") { movie in
            movie.delete(use: self.delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [MovieDTO] {
        try await Movie.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func create(req: Request) async throws -> MovieDTO {
        let movie = try req.content.decode(MovieDTO.self).toModel()

        try await movie.save(on: req.db)
        return movie.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let movie = try await Movie.find(req.parameters.get("movieID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await movie.delete(on: req.db)
        return .noContent
    }
}
