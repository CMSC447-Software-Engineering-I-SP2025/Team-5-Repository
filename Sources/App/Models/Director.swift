import Fluent
import struct Foundation.UUID

final class MovieDirector: Model, @unchecked Sendable {
    static let schema = "movie_director"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "movie_id")
    var movie: Movie
    
    @Parent(key: "director_id")
    var director: Person
    
    @Field(key: "credit_id")
    var creditId: String
    
    @Field(key: "department")
    var department: String
    
    @Field(key: "job")
    var job: String
}


extension MovieDirector {
    var toDTO: DirectorDTO {
        .init(adult: director.adult,
              gender: director.gender,
              id: director.id ?? 0,
              knownForDepartment: director.knownForDepartment,
              originalName: director.originalName,
              popularity: director.popularity,
              profilePath: director.profilePath,
              creditId: creditId,
              department: department,
              job: job)
    }
}
