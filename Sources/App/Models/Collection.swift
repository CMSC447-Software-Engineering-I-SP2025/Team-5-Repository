import Fluent

final class Collection: Model, @unchecked Sendable {
    static let schema = "collections"
    
    @ID(custom: .id, generatedBy: .user)
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "poster_path")
    var posterPath: String?
    
    @Field(key: "backdrop_path")
    var backdropPath: String?
    
    init() {}
    init?(dto: CollectionDTO?) {
        guard let dto else { return nil }
        id = dto.id
        name = dto.name
        posterPath = dto.posterPath
        backdropPath = dto.backdropPath
    }
    
    var toDTO: CollectionDTO {
        .init(id: id ?? 0, name: name, posterPath: posterPath, backdropPath: backdropPath)
    }
}

