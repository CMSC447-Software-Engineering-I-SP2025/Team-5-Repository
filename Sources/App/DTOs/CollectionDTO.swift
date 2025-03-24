import Fluent
import Vapor

struct CollectionDTO: Content {
    var id: Int
    var name: String
    var posterPath: String?
    var backdropPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
}
