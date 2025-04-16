import Vapor
import Fluent

struct GenrePage: LeafPage {
    var file: String { "genres_list" }
    var genres: [GenreDTO]
    var meta: PageMetadata

    init(genres: [GenreDTO], user: User? = nil) {
        self.genres = genres
        self.meta = .init(title: "Genres", user: user)
    }
}

struct GenreController: RouteCollection, @unchecked Sendable {
    let sessionProtected: RoutesBuilder
    
    func boot(routes: RoutesBuilder) throws {
        sessionProtected.grouped("api")
            .grouped("genres")
            .get(use: self.searchAPI)

        sessionProtected.grouped("genres")
            .get(use: self.searchView)
    }

    @Sendable
    func searchAPI(req: Request) async throws -> [GenreDTO] { 
        try await Genre.query(on: req.db).all().map(\.toDTO)
    }
    
    @Sendable
    func searchView(req: Request) async throws -> View {
        try await GenrePage(genres: try await searchAPI(req: req),
                            user: try await req.auth.get(Token.self)?.$user.get(on: req.db))
            .render(with: req)
    }

}