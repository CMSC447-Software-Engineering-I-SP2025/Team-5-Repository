import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    let sessionEnabled = app.grouped(
        SessionsMiddleware(session: app.sessions.driver)
    )
    
    let sessionProtected = app.grouped(
        SessionsMiddleware(session: app.sessions.driver),
        Token.sessionAuthenticator()
        //            UserToken.guardMiddleware()
    )
    
    sessionProtected.get { req async throws in
        
        return try await req.view.render("index", ["title": "Hello Vapor!", "message": "Testing!"])
    }

app.get("people", ":personID") { req async throws -> Response in
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

    let dto = person.personDTO
    return try await jsonOrHTML(
        request: req,
        templateName: "person_detail",
        value: ["person": dto]
    )


}



    try app.register(collection: MovieController(sessionProtected: sessionProtected))
    try app.register(collection: LoginController(sessionEnabled: sessionEnabled))
    try app.register(collection: UserController(sessionProtected: sessionProtected))
    try app.register(collection: RegistrationController())
}
