import Fluent
import Vapor

struct MovieIndexQuery: Content {
    var page: Int? = 1
    var perPage: Int? = 36
    
    var selectedGenres: [Int]?
    var selectedCountries: [String]?
    var selectedLanguages: [String]?
    var startDate: Date?
    var endDate: Date?
    var minimumRating: Double?
    
    // Manual init to ignore type mismatched keys from a query string
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.page = (try? container.decodeIfPresent(Int.self, forKey: .page)) ?? 1
        self.perPage = (try? container.decodeIfPresent(Int.self, forKey: .perPage)) ?? 36
        self.selectedGenres = try? container.decodeIfPresent([Int].self, forKey: .selectedGenres)
        self.selectedCountries = try? container.decodeIfPresent([String].self, forKey: .selectedCountries)
        self.selectedLanguages = try? container.decodeIfPresent([String].self, forKey: .selectedLanguages)
        self.startDate = try? container.decodeIfPresent(Date.self, forKey: .startDate)
        self.endDate = try? container.decodeIfPresent(Date.self, forKey: .endDate)
        self.minimumRating = try? container.decodeIfPresent(Double.self, forKey: .minimumRating)
    }
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case selectedGenres = "selected_genres"
        case selectedCountries = "selected_countries"
        case selectedLanguages = "selected_languages"
        case startDate = "start_date"
        case endDate = "end_date"
        case minimumRating = "minimum_rating"
    }
}



struct MovieSearchResponse: LeafPage {
    var query: MovieIndexQuery
    var pages: Int
    var movies: [ListMovieDTO]
    var genres: [GenreDTO]
    var languages: [SpokenLanguageDTO]
    var countries: [ProductionCountryDTO]
    var favoriteMovieIds: [Int]
    
    init(query: MovieIndexQuery, pages: Int,
         movies: [ListMovieDTO], genres: [GenreDTO],
         languages: [SpokenLanguageDTO], countries: [ProductionCountryDTO],
         favoriteMovieIds: [Int], user: User?=nil) {
        self.query = query
        self.pages = pages
        self.movies = movies
        self.genres = genres
        self.languages = languages
        self.countries = countries
        self.meta = .init(title: "Movies", description: "Outitech Movies", user: user)
        self.favoriteMovieIds = favoriteMovieIds
    }
    var meta: PageMetadata
    var file: String { "movies_index" }
}

struct MovieESSearchResponse: LeafPage {
    var query: String
    var pages: Int
    var movies: [ListMovieDTO]
    var favoriteMovieIds: [Int]
    init(query: String, pages: Int, movies: [ListMovieDTO], favoriteMovieIds: [Int], user: User?) {
        self.query = query
        self.pages = pages
        self.movies = movies
        self.favoriteMovieIds = favoriteMovieIds
        self.meta = .init(title: "Movies", description: "Outitech Movies", user: user)
    }
    var meta: PageMetadata
    var file: String { "movies_es" }
    
    // fixme
    var genres: [String] = []
    var languages: [String] = []
    var countries: [String] = []
    
}

struct MovieDetailPage: LeafPage {
    var file: String { "movie_detail" }
    var meta: PageMetadata
    var movie: MovieDTO
    var favoriteMovieIds: [Int]
    
    init(movie: MovieDTO, favoriteMovieIds: [Int], user: User?=nil) {
        self.movie = movie
        self.favoriteMovieIds = favoriteMovieIds
        self.meta = .init(title: movie.title, description: movie.overview, user: user)
    }
}

struct MovieController: RouteCollection, @unchecked Sendable {
    let sessionProtected: RoutesBuilder
    
    func boot(routes: RoutesBuilder) throws {
        // API routes
        let api = sessionProtected.grouped("api").grouped("movies")
        api.get(use: self.searchAPI)
        api.get("es", use: self.esSearchAPI)
        api.post(use: self.create)
        api.group(":movieID") { movie in
            movie.delete(use: self.delete)
            movie.get(use: self.detail)
        }

        // View routes
        let movies = sessionProtected.grouped("movies")
        movies.get("es", use: self.esSearchView)
        movies.get(use: self.searchView)
        movies.get(":movieID", use: self.detailView)
    }
    
    @Sendable
    func esSearchAPI(req: Request) async throws -> MovieESSearchResponse {
        struct IdTitle: Content {
            let id: Int, title: String
        }
        
        let page = (try? req.query.get(Int.self, at: "page")) ?? 1
        let size = (try? req.query.get(Int.self, at: "size")) ?? 30
        let from = max(0, (page - 1) * size)
        let searchQuery = (try? req.query.get(String.self, at: "q")) ?? ""
        var movies: [Movie] = []
        
        if !searchQuery.isEmpty {
            let body = ESQueryBody(query: .init(multi_match: .init(query: searchQuery,
                                                                   fields: ["title", "tagline", "overview"],
                                                                   op: "or")),
                                   _source: ["id","title"],
                                   from: from,
                                   size: size)
            
            
            let baseURL = (Environment.get("ELASTICSEARCH_URL") ?? "http://localhost:9200")
            let response = try await req.client.post(URI(string: baseURL + "/movies-index/_search")) {
                $0.headers.contentType = .json
                try $0.content.encode(body, as: .json)
            }
            
            let es = try response.content.decode(ESResponse<IdTitle>.self)
            let ids = es.hits.hits.map(\._source.id)
            movies = try await Movie
                .query(on: req.db).filter(\.$id ~~ ids)
                .with(\.$genres)
                .all()
        }

        // Get current user if authenticated
        let user = try await req.auth.get(Token.self)?.$user.get(on: req.db)
        print("Found \(movies.count)")
        let out = MovieESSearchResponse(query: searchQuery,
                                        pages: 1,
                                        movies: movies.map(\.toListDTO),
                                        favoriteMovieIds: try await user?.favoriteMovieIds(on: req.db) ?? [],
                                        user: user)
        //        let movieSearchResponse = MovieSearch
        
        return out
    }
    
    @Sendable
    func esSearchView(req: Request) async throws -> View {
        do {
            return try await esSearchAPI(req: req).render(with: req)

        } catch {
            print("error \(error)")
            return try await esSearchAPI(req: req).render(with: req)

        }
    }
    
    
    @Sendable
    func searchAPI(req: Request) async throws -> MovieSearchResponse {
        let query = try req.query.decode(MovieIndexQuery.self)
        let page = query.page ?? 1
        let perPage = query.perPage ?? 36
        
        
        // build query
        var dbQuery = Movie.query(on: req.db)
        
        // add date filters
        if let startDate = query.startDate {
            dbQuery = dbQuery.filter(\Movie.$releaseDate >= startDate)
        }
        if let endDate = query.endDate {
            dbQuery = dbQuery.filter(\Movie.$releaseDate <= endDate)
        }
        
        // add vote rating query
        if let minimumRating = query.minimumRating,
           minimumRating >= 0 && minimumRating <= 10 {
            dbQuery = dbQuery.filter(\Movie.$voteAverage >= minimumRating)
        }
        
        // add genre filters (not strict)
        if let selectedGenres = query.selectedGenres {
            dbQuery = dbQuery
                .join(MovieGenre.self, on: \Movie.$id == \MovieGenre.$movie.$id)
                .filter(MovieGenre.self, \.$genre.$id ~~ selectedGenres)
        }
        
        // add Country filters (not strict)
        if let selectedCountries = query.selectedCountries {
            dbQuery = dbQuery
                .join(MovieProductionCountry.self, on: \Movie.$id == \MovieProductionCountry.$movie.$id)
                .join(ProductionCountry.self, on: \MovieProductionCountry.$productionCountry.$id == \ProductionCountry.$id)
                .filter(ProductionCountry.self, \.$iso3166_1 ~~ selectedCountries)
        }
        
        // add Languages filters (not strict)
        if let selectedLanguages = query.selectedLanguages {
            dbQuery = dbQuery
                .join(MovieSpokenLanguage.self, on: \Movie.$id == \MovieSpokenLanguage.$movie.$id)
                .join(SpokenLanguage.self, on: \MovieSpokenLanguage.$spokenLanguage.$id == \SpokenLanguage.$id)
                .filter(SpokenLanguage.self, \.$iso639_1 ~~ selectedLanguages)
        }
        
        dbQuery = dbQuery
            .sort(\.$popularity, .descending)
            .with(\.$genres)
        
        // Paginate movies
        let movies = try await dbQuery.page(withIndex: page, size: perPage)
        
        // Get current user if authenticated
        let user = try await req.auth.get(Token.self)?.$user.get(on: req.db)
        
        // Fetch all Genres, Languages, and Production Countries (for filter view)
        async let genres = Genre.query(on: req.db).sort(\.$name).all().compactMap(\.toDTO)
        async let languages = SpokenLanguage.query(on: req.db).sort(\.$englishName).all().compactMap((\.toDTO))
        async let countries = ProductionCountry.query(on: req.db).sort(\.$name).all().compactMap(\.toDTO)
        
        // Final Response
        return MovieSearchResponse(query: query,
                                   pages: movies.metadata.pageCount,
                                   movies: movies.items.map(\.toListDTO),
                                   genres: try await genres,
                                   languages: try await languages,
                                   countries: try await countries,
                                   favoriteMovieIds: try await user?.favoriteMovieIds(on: req.db) ?? [],
                                   user: user)
    }
    
    @Sendable
    func searchView(req: Request) async throws -> View {
        try await searchAPI(req: req).render(with: req)
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
        
        return movie.toDTO
    }
    
    @Sendable
    func detailView(req: Request) async throws -> View {
        let user = try await req.auth.get(Token.self)?.$user.get(on: req.db)
        return try await MovieDetailPage(movie: try await detail(req: req),
                                  favoriteMovieIds: try await user?.favoriteMovieIds(on: req.db) ?? [],
                                  user: user)
            .render(with: req)
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
        
        return movie.toDTO
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


