import Fluent
import Vapor

struct ProductionCompanyDTO: Content {
    var id: Int
    var logoPath: String?
    var name: String
    var originCountry: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case logoPath = "logo_path"
        case name
        case originCountry = "origin_country"
    }
}

struct ProductionCountryDTO: Content, Codable {
    var iso31661: String?
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case iso31661 = "iso_3166_1"
        case name
    }
}
