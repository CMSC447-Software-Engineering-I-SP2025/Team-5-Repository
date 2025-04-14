import Vapor

struct ActingCreditDTO: Content {
    var id: Int
    var title: String
    var character: String
    var posterPath: String?
    var creditId: String
    var order: Int
}
