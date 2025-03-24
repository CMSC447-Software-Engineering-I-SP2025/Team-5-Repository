import Fluent
import Foundation


final class Movie: Model, @unchecked Sendable {
    static let schema = "movies"
    
    @ID(custom: .id, generatedBy: .user)
    var id: Int?
    
    @Field(key: "adult")
    var adult: Bool
    
    @Field(key: "backdrop_path")
    var backdropPath: String?
    
    @OptionalParent(key: "belongs_to_collection")
    var belongsToCollection: Collection?
    
    @Field(key: "budget")
    var budget: Int
    
    @Field(key: "homepage")
    var homepage: String
    
    @Field(key: "imdb_id")
    var imdbId: String
    
    @Field(key: "origin_country")
    var originCountry: [String]
    
    @Field(key: "original_language")
    var originalLanguage: String
    
    @Field(key: "original_title")
    var originalTitle: String
    
    @Field(key: "overview")
    var overview: String
    
    @Field(key: "popularity")
    var popularity: Double
    
    @Field(key: "poster_path")
    var posterPath: String
    
    @Field(key: "release_date")
    var releaseDate: Date
    
    @Field(key: "revenue")
    var revenue: Int
    
    @Field(key: "runtime")
    var runtime: Int
    
    @Field(key: "status")
    var status: String
    
    @Field(key: "tagline")
    var tagline: String
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "video")
    var video: Bool
    
    @Field(key: "vote_average")
    var voteAverage: Double
    
    @Field(key: "vote_count")
    var voteCount: Int
    
    @Siblings(through: MovieGenre.self, from: \.$movie, to: \.$genre)
    var genres: [Genre]
    
    @Siblings(through: MovieSpokenLanguage.self, from: \.$movie, to: \.$spokenLanguage)
    var spokenLanguages: [SpokenLanguage]
    
    @Siblings(through: MovieProductionCompany.self, from: \.$movie, to: \.$productionCompany)
    var productionCompanies: [ProductionCompany]
    
    @Siblings(through: MovieProductionCountry.self, from: \.$movie, to: \.$productionCountry)
    var productionCountries: [ProductionCountry]
    
    @Siblings(through: MovieCast.self, from: \.$movie, to: \.$cast)
    var cast: [Person]
    
    @Siblings(through: MovieDirector.self, from: \.$movie, to: \.$director)
    var directors: [Person]
    
    init() { self.id = 0 }
    
    init(id: Int, adult: Bool, backdropPath: String?,
         belongsToCollectionID: Collection.IDValue? = nil,
         budget: Int, homepage: String, imdbId: String, originCountry: [String],
         originalLanguage: String, originalTitle: String, overview: String,
         popularity: Double, posterPath: String, releaseDate: Date, revenue: Int,
         runtime: Int, status: String, tagline: String, title: String, video: Bool,
         voteAverage: Double, voteCount: Int) {
        
        self.id = id
        self.adult = adult
        self.backdropPath = backdropPath
        self.$belongsToCollection.id = belongsToCollectionID
        self.budget = budget
        self.homepage = homepage
        self.imdbId = imdbId
        self.originCountry = originCountry
        self.originalLanguage = originalLanguage
        self.originalTitle = originalTitle
        self.overview = overview
        self.popularity = popularity
        self.posterPath = posterPath
        self.releaseDate = releaseDate
        self.revenue = revenue
        self.runtime = runtime
        self.status = status
        self.tagline = tagline
        self.title = title
        self.video = video
        self.voteAverage = voteAverage
        self.voteCount = voteCount
    }
}


extension Movie {
    func toDTO() -> MovieDTO {
        .init(adult: adult,
              backdropPath: backdropPath,
              belongsToCollection: belongsToCollection?.toDTO,
              budget: budget,
              genres: genres.map(\.toDTO),
              homepage: homepage,
              id: id ?? 0,
              imdbId: imdbId,
              originCountry: originCountry,
              originalLanguage: originalLanguage,
              originalTitle: originalTitle,
              overview: overview,
              popularity: 0,
              posterPath: posterPath,
              productionCompanies: productionCompanies.map(\.toDTO),
              productionCountries: productionCountries.map(\.toDTO),
              releaseDate: releaseDate,
              revenue: revenue,
              runtime: runtime,
              spokenLanguages: spokenLanguages.map(\.toDTO),
              status: status,
              tagline: tagline,
              title: title,
              video: video,
              voteAverage: voteAverage,
              voteCount: voteCount,
              cast: $cast.pivots.map(\.toDTO),
              directors: $directors.pivots.map(\.toDTO))
    }
    
    func toListDTO() -> ListMovieDTO {
        .init(adult: adult,
              backdropPath: backdropPath,
              budget: budget,
              genres: genres.map(\.toDTO),
              homepage: homepage,
              id: id ?? 0,
              imdbId: imdbId,
              originalLanguage: originalLanguage,
              originalTitle: originalTitle,
              overview: overview,
              popularity: popularity,
              posterPath: posterPath,
              releaseDate: releaseDate,
              revenue: revenue,
              runtime: runtime,
              status: status,
              tagline: tagline,
              title: title,
              video: video,
              voteAverage: voteAverage,
              voteCount: voteCount)
    }
}



extension Movie {
    static func createOrUpdate(on db: Database, from dto: MovieDTO) async throws -> Movie {
        // Get collection first
        let collection: Collection?
        if let existing = try await Collection.query(on: db)
            .filter(\.$id == dto.belongsToCollection?.id ?? 0)
            .first() {
            collection = existing
        } else {
            // doesn't exist, create and save
            collection = Collection(dto: dto.belongsToCollection)
            try await collection?.save(on: db)
        }
        
        // Get movie
        let movie: Movie
        if let existing = try await Movie.query(on: db)
            .filter(\.$id == dto.id)
            .with(\.$genres)
            .with(\.$spokenLanguages)
            .with(\.$productionCompanies)
            .with(\.$productionCountries)
            .with(\.$cast)
            .with(\.$cast.$pivots)
            .with(\.$directors)
            .with(\.$directors.$pivots)
            .first() {
            movie = existing
        } else {
            // doesn't exist, create and save
            movie = Movie(id: dto.id,
                          adult: dto.adult,
                          backdropPath: dto.backdropPath,
                          belongsToCollectionID: collection?.id,
                          budget: dto.budget,
                          homepage: dto.homepage,
                          imdbId: dto.imdbId,
                          originCountry: dto.originCountry,
                          originalLanguage: dto.originalLanguage,
                          originalTitle: dto.originalTitle,
                          overview: dto.overview,
                          popularity: dto.popularity,
                          posterPath: dto.posterPath,
                          releaseDate: dto.releaseDate,
                          revenue: dto.revenue,
                          runtime: dto.runtime,
                          status: dto.status,
                          tagline: dto.tagline,
                          title: dto.title,
                          video: dto.video,
                          voteAverage: dto.voteAverage,
                          voteCount: dto.voteCount)
            try await movie.save(on: db)
        }
        
        
        // Attach many-to-many types
        // initialize first
        var genres: [Genre] = try await Genre.query(on: db)
            .filter(\.$id ~~ dto.genres.map(\.id)).all()
        if genres.isEmpty {
            genres = dto.genres.map(Genre.init)
            for genre in genres { try await genre.save(on: db) }
            
        }
        
        var languages = try await SpokenLanguage.query(on: db)
            .filter(\.$iso639_1 ~~ dto.spokenLanguages.map(\.iso6391)).all()
        if languages.isEmpty {
            languages = dto.spokenLanguages.map({ SpokenLanguage(dto: $0) })
            for language in languages { try await language.save(on: db) }
        }
        
        var prodCompanies = try await ProductionCompany.query(on: db)
            .filter(\.$id ~~ dto.productionCompanies.map(\.id)).all()
        if prodCompanies.isEmpty {
            prodCompanies = dto.productionCompanies.map({ ProductionCompany(dto: $0)})
            for prodCompany in prodCompanies { try await prodCompany.save(on: db) }
        }
        var prodCountries = try await ProductionCountry.query(on: db)
            .filter(\.$iso3166_1 ~~ dto.productionCountries.map(\.iso31661)).all()
        if prodCountries.isEmpty {
            prodCountries = dto.productionCountries.map({ ProductionCountry(dto: $0)})
            for prodCountry in prodCountries { try await prodCountry.save(on: db) }
        }
        
        var cast: [Person] = []
        for castDTO in dto.cast {
            var member: Person
            if let existing = try await Person.query(on: db)
                .filter(\.$id == castDTO.id).first() {
                member = existing
            } else {
                member = .init(id: castDTO.id,
                               adult: castDTO.adult,
                               gender: castDTO.gender,
                               knownForDepartment: castDTO.knownForDepartment,
                               name: castDTO.name,
                               originalName: castDTO.originalName,
                               popularity: castDTO.popularity,
                               profilePath: castDTO.profilePath)
                try await member.save(on: db)
            }
            cast.append(member)
        }
        var directors: [Person] = []
        for directorDTO in dto.directors {
            var director: Person
            if let existing = try await Person.query(on: db)
                .filter(\.$id == directorDTO.id).first() {
                director = existing
            } else {
                director = .init(id: directorDTO.id,
                                 adult: directorDTO.adult,
                                 gender: directorDTO.gender,
                                 knownForDepartment: directorDTO.knownForDepartment,
                                 name: nil,
                                 originalName: directorDTO.originalName,
                                 popularity: directorDTO.popularity,
                                 profilePath: directorDTO.profilePath)
                try await director.save(on: db)
            }
            directors.append(director)
        }
        
        // Strip relations
        try await movie.$genres.detachAll(on: db)
        try await movie.$spokenLanguages.detachAll(on: db)
        try await movie.$productionCompanies.detachAll(on: db)
        try await movie.$productionCountries.detachAll(on: db)
        try await movie.$cast.detachAll(on: db)
        try await movie.$directors.detachAll(on: db)
        
        // Now attach new
        try await movie.$genres.attach(genres, on: db)
        try await movie.$spokenLanguages.attach(languages, on: db)
        try await movie.$productionCompanies.attach(prodCompanies, on: db)
        try await movie.$productionCountries.attach(prodCountries, on: db)
        
        var dtoCast = dto.cast
        try await movie.$cast.attach(cast, on: db) { pivot in
            guard let match = dtoCast.first(where: { $0.id == pivot.cast.id }) else {
                return
            }
            if let index = dtoCast
                .firstIndex(where: { $0.creditId == match.creditId }) {
                dtoCast.remove(at: index)
            }
            
            pivot.movieCastId = match.castId
            pivot.character = match.character
            pivot.castOrder = match.order
            pivot.creditId = match.creditId
        }
        var dtoDirectors = dto.directors
        try await movie.$directors.attach(directors, on: db) { pivot in
            guard let match = dtoDirectors.first(where: { $0.id == pivot.director.id }) else {
                return
            }
            if let index = dtoDirectors
                .firstIndex(where: { $0.creditId == match.creditId }) {
                dtoDirectors.remove(at: index)
            }
            
            
            pivot.creditId = match.creditId
            pivot.department = match.department
            pivot.job = match.job
        }

        // Save again
        try await movie.save(on: db)
        
        return movie
    }
}


