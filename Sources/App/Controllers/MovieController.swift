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
    func index(req: Request) async throws -> [ListMovieDTO] {
        try await Movie.query(on: req.db)
            .range(..<30)
            .with(\.$genres)
            .all()
            .compactMap({ $0.toListDTO() })
    }
    
    @Sendable
    func detail(req: Request) async throws -> MovieDTO {
        guard let param = req.parameters.get("movieID"),
              let movieId = Int(param),
              let movie: Movie = try await Movie.query(on: req.db)
            .filter(\.$id == movieId)
            .with(\.$genres)
            .with(\.$spokenLanguages)
            .with(\.$productionCompanies)
            .with(\.$productionCountries)
            .with(\.$cast)
            .with(\.$cast.$pivots, { $0.with(\.$cast) })
            .with(\.$directors)
            .with(\.$directors.$pivots, { $0.with(\.$director) })
            .first()
        else {
            throw Abort(.notFound)
        }
        return movie.toDTO()
    }
    
    
    @Sendable
    func create(req: Request) async throws -> MovieDTO {
        let movieDTO = try req.content.decode(MovieDTO.self)
        print(movieDTO.id)
        _ = try await Movie.createOrUpdate(on: req.db, from: movieDTO)
        //        try await movie.save(on: req.db)
        guard let movie = try await Movie.query(on: req.db)
            .filter(\.$id == movieDTO.id)
            .with(\.$genres)
            .with(\.$spokenLanguages)
            .with(\.$productionCompanies)
            .with(\.$productionCountries)
            .with(\.$cast)
            .with(\.$cast.$pivots, { $0.with(\.$cast) })
            .with(\.$directors)
            .with(\.$directors.$pivots, { $0.with(\.$director) })
            .first() else {
            throw Abort(.notFound)
        }
        
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


