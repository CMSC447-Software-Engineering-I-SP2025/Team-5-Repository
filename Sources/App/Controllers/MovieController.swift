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

struct MovieIndexResponse: Content {
    var query: MovieIndexQuery
    var pages: Int
    var movies: [ListMovieDTO]
    var genres: [GenreDTO]
    var languages: [SpokenLanguageDTO]
    var countries: [ProductionCountryDTO]
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

        // Fetch all Genres, Languages, and Production Countries (for filter view)
        let genres = try await Genre.query(on: req.db).sort(\.$name).all().compactMap(\.toDTO)
        let languages = try await SpokenLanguage.query(on: req.db).sort(\.$englishName).all().compactMap((\.toDTO))
        let countries = try await ProductionCountry.query(on: req.db).sort(\.$name).all().compactMap(\.toDTO)
        
        
        // Build response
        let pageInfo = MovieIndexResponse(query: query,
                                          pages: movies.metadata.pageCount,
                                          movies: movies.items.compactMap({ $0.toListDTO() }),
                                          genres: genres,
                                          languages: languages,
                                          countries: countries)
        
        // Render JSON or HTML
        return try await jsonOrHTML(request: req,
                                    templateName: "movies_index",
                                    value: pageInfo)
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


