import Fluent
import struct Foundation.UUID

final class Genre: Model, @unchecked Sendable {
    static let schema = "genres"

    @ID(custom: "id", generatedBy: .user)
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    init() {}
    
    init(dto: GenreDTO) {
        self.id = dto.id
        self.name = dto.name
    }
    
    var toDTO: GenreDTO { .init(id: id ?? 0, name: name) }
}

// Pivot

final class MovieGenre: Model, @unchecked Sendable {
    static let schema = "movie_genres"

    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "movie_id")
    var movie: Movie
    
    @Parent(key: "genre_id")
    var genre: Genre
}

