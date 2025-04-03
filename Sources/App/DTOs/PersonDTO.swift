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

    init(from person: Person) {
        self.id = person.id
        self.adult = person.adult
        self.gender = person.gender
        self.knownForDepartment = person.knownForDepartment
        self.name = person.name
        self.originalName = person.originalName
        self.popularity = person.popularity
        self.profilePath = person.profilePath
    }
}
