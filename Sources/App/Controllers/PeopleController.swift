import Vapor
import Fluent

struct PersonPage: LeafPage {
    var file: String { "person_detail" }
    var person: PersonDTO
    var meta: PageMetadata
    
    init(person: PersonDTO, user: User? = nil) {
        self.person = person
        self.meta = .init(title: person.originalName, user: user)
    }
}

struct PeopleController: RouteCollection, @unchecked Sendable {
    let sessionProtected: RoutesBuilder
    
    func boot(routes: RoutesBuilder) throws {
        // API routes
        let api = sessionProtected.grouped("api").grouped("people")
        api.get(":personID", use: self.detailAPI)
        
        
        // View routes
        let people = sessionProtected.grouped("people")
        people.get(":personID", use: self.detailView)
    }
    
    @Sendable
    func detailAPI(req: Request) async throws -> PersonDTO {
        guard let personID = req.parameters.get("personID", as: Int.self) else {
            throw Abort(.badRequest)
        }
    
        let person = try await Person.query(on: req.db)
            .filter(\.$id == personID)
            .with(\.$actedIn)
            .with(\.$actedIn.$pivots) { pivot in pivot.with(\.$movie) }
            .with(\.$directed)
            .with(\.$directed.$pivots) { pivot in pivot.with(\.$movie) }
            .first()
        
        guard let person = person else {
            throw Abort(.notFound, reason: "Person not found")
        }
        
        return person.personDTO
    }
    
    @Sendable
    func detailView(req: Request) async throws -> View {
        try await PersonPage(person: try await detailAPI(req: req),
                             user: try await req.auth.get(Token.self)?.$user.get(on: req.db))
            .render(with: req)
    }
}
