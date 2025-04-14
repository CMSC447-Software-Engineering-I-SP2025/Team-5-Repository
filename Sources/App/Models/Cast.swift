import Fluent
import struct Foundation.UUID

final class MovieCast: Model, @unchecked Sendable {
    static let schema = "movie_cast"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "movie_id")
    var movie: Movie
    
    @Parent(key: "cast_id")
    var cast: Person
    
    @Field(key: "movie_cast_id")
    var movieCastId: Int
    
    @Field(key: "character")
    var character: String
    
    @Field(key: "cast_order")
    var castOrder: Int
    
    @Field(key: "credit_id")
    var creditId: String
}

extension MovieCast {
    var toDTO: CastDTO {
        .init(adult: cast.adult,
              gender: cast.gender,
              id: cast.id ?? 0,
              knownForDepartment: cast.knownForDepartment,
              name: cast.name ?? "",
              originalName: cast.originalName,
              popularity: cast.popularity,
              profilePath: cast.profilePath,
              castId: movieCastId,
              character: character,
              creditId: creditId,
              order: castOrder
        )
    }
    
    func toCreditDTO() -> ActingCreditDTO {
        .init(
            id: movie.id!,
            title: movie.title,
            character: character,
            posterPath: movie.posterPath,
            creditId: creditId,
            order: castOrder
        )
    }

}


