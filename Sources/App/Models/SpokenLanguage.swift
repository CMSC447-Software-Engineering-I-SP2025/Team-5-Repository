import Fluent
import struct Foundation.UUID

final class SpokenLanguage: Model, @unchecked Sendable {
    static let schema = "spoken_languages"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "iso_639_1")
    var iso639_1: String?
    
    @Field(key: "english_name")
    var englishName: String
    
    @Field(key: "name")
    var name: String
    
    init() {}
    init(dto: SpokenLanguageDTO) {
        iso639_1 = dto.iso6391
        englishName = dto.englishName
        name = dto.name
    }
}

extension SpokenLanguage {
    var toDTO: SpokenLanguageDTO {
        .init(englishName: englishName, iso6391: iso639_1 ?? "", name: name)
    }
}

// Pivot

final class MovieSpokenLanguage: Model, @unchecked Sendable {
    static let schema = "movie_spoken_language"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "movie_id")
    var movie: Movie
    
    @Parent(key: "spoken_language_id")
    var spokenLanguage: SpokenLanguage
}
