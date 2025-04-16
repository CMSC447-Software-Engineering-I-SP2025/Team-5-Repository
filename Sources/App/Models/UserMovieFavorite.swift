import Fluent
import Vapor

final class UserMovieFavorite: Model, Content, @unchecked Sendable {
    static let schema = "user_movie_favorites"

    @ID(key: .id)
    var id: UUID?

    // Foreign key linking to the User model
    @Parent(key: "user_id")
    var user: User

    // Foreign key linking to the Movie model
    @Parent(key: "movie_id")
    var movie: Movie

    init() { }

    init(id: UUID? = nil, userID: User.IDValue, movieID: Movie.IDValue) {
        self.id = id
        self.$user.id = userID
        self.$movie.id = movieID
    }
} 