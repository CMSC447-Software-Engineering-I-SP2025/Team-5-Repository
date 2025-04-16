import Fluent
import Vapor

struct MovieDTO: Content {
    var adult: Bool
    var backdropPath: String?
    var belongsToCollection: CollectionDTO?
    var budget: Int
    var genres: [GenreDTO]
    var homepage: String
    var id: Int
    var imdbId: String
    var originCountry: [String]
    var originalLanguage: String
    var originalTitle: String
    var overview: String
    var popularity: Double
    var posterPath: String
    var productionCompanies: [ProductionCompanyDTO]
    var productionCountries: [ProductionCountryDTO]
    var releaseDate: Date
    var revenue: Int
    var runtime: Int
    var spokenLanguages: [SpokenLanguageDTO]
    var status: String
    var tagline: String
    var title: String
    var video: Bool
    var voteAverage: Double
    var voteCount: Int
    var cast: [CastDTO]
    var directors: [DirectorDTO]
    
    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case belongsToCollection = "belongs_to_collection"
        case budget
        case genres
        case homepage
        case id
        case imdbId = "imdb_id"
        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case overview
        case popularity
        case posterPath = "poster_path"
        case productionCompanies = "production_companies"
        case productionCountries = "production_countries"
        case releaseDate = "release_date"
        case revenue
        case runtime
        case spokenLanguages = "spoken_languages"
        case status
        case tagline
        case title
        case video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case cast
        case directors
    }
}


struct ListMovieDTO: Content {
    var adult: Bool
    var backdropPath: String?
    var budget: Int
    var genres: [GenreDTO]
    var homepage: String
    var id: Int
    var imdbId: String
    var originalLanguage: String
    var originalTitle: String
    var overview: String
    var popularity: Double
    var posterPath: String
    var releaseDate: Date
    var revenue: Int
    var runtime: Int
    var status: String
    var tagline: String
    var title: String
    var video: Bool
    var voteAverage: Double
    var voteCount: Int

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case budget
        case genres
        case homepage
        case id
        case imdbId = "imdb_id"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case overview
        case popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case revenue
        case runtime
        case status
        case tagline
        case title
        case video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}

