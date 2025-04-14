import Vapor

struct DirectingCreditDTO: Content {
    var id: Int
    var title: String
    var posterPath: String?
    var creditId: String
}
