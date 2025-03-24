import Fluent
import Vapor

struct DirectorDTO: Content {
    var adult: Bool
    var gender: Int
    var id: Int
    var knownForDepartment: String
    var originalName: String
    var popularity: Double
    var profilePath: String?
    var creditId: String
    var department: String
    var job: String
    
    enum CodingKeys: String, CodingKey {
        case adult
        case gender
        case id
        case knownForDepartment = "known_for_department"
        case originalName = "original_name"
        case popularity
        case profilePath = "profile_path"
        case creditId = "credit_id"
        case department
        case job
    }
}

