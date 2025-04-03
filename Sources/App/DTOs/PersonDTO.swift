import Vapor
import Fluent

struct PersonDTO: Content {
    var id: Int?
    var adult: Bool
    var gender: Int
    var knownForDepartment: String
    var name: String?
    var originalName: String
    var popularity: Double
    var profilePath: String?
}

extension Person {
    var personDTO: PersonDTO {
        PersonDTO(
            id: self.id,
            adult: self.adult,
            gender: self.gender,
            knownForDepartment: self.knownForDepartment,
            name: self.name,
            originalName: self.originalName,
            popularity: self.popularity,
            profilePath: self.profilePath
        )
    }
}