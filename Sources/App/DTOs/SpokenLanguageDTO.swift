import Fluent
import Vapor

struct SpokenLanguageDTO: Content {
    var englishName: String
    var iso6391: String
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case englishName = "english_name"
        case iso6391 = "iso_639_1"
        case name
    }
}
