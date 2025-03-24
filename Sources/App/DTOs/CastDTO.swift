import Fluent
import Vapor

struct CastDTO: Content {
    var adult: Bool
    var gender: Int
    var id: Int
    var knownForDepartment: String
    var name: String
    var originalName: String
    var popularity: Double
    var profilePath: String?
    var castId: Int
    var character: String
    var creditId: String
    var order: Int
    
    enum CodingKeys: String, CodingKey {
        case adult
        case gender
        case id
        case knownForDepartment = "known_for_department"
        case name
        case originalName = "original_name"
        case popularity
        case profilePath = "profile_path"
        case castId = "cast_id"
        case character
        case creditId = "credit_id"
        case order
    }
}
