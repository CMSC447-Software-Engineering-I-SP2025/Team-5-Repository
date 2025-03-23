import Fluent
import Vapor

struct MovieIndexQuery: Content {
    var page: Int?
    var perPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case page, perPage = "per_page"
    }
}
struct MovieIndexResponse: Codable {
    var currentPage: Int
    var totalPages: Int
    var movies: [ListMovieDTO]
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page", totalPages = "total_pages", movies
    }
}

struct MovieController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let movies = routes.grouped("movies")
        
        movies.get(use: self.index)
        
        movies.post(use: self.create)
        movies.group(":movieID") { movie in
            movie.delete(use: self.delete)
            movie.get(use: self.detail)
        }
    }
    
    @Sendable
    func index(req: Request) async throws -> Response {
        let query = try req.query.decode(MovieIndexQuery.self)
        let page = query.page ?? 1
        let perPage = query.perPage ?? 36
        
        let movies = try await Movie.query(on: req.db)
            .range((page * perPage)..<((page + 1) * perPage))
            .with(\.$genres)
            .all()
            .compactMap({ $0.toListDTO() })
        
        let totalPages = try await Movie.query(on: req.db).count() / perPage
        var resp = Response(status: .ok)
        if req.headers.accept.contains(where: { $0.mediaType == .html }) {
            let pageInfo = MovieIndexResponse(currentPage: page,
                                              totalPages: totalPages,
                                              movies: movies)
            let view: View = try await req.view.render("movies_index", pageInfo)
            resp.headers.contentType = .html
            resp.body = .init(buffer: view.data)
        } else {
            try resp.content.encode(movies)
            resp.headers.contentType = .json
        }
        return resp
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


