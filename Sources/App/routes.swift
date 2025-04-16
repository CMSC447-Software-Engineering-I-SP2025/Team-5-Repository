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
    
    // "/" index
    sessionProtected.get { req async throws -> View in
        let user = try await req.auth.get(Token.self)?.$user.get(on: req.db)
        let page = Page(file: "index", meta: .init(title: "Outitech Movies",
                                                   description: "Outitech Movie RecomendationEngine",
                                                   user: user))
        return try await page.render(with: req)
    }

   

    app.get("genres") { req async throws -> Response in
        let genreDTOs = try await Genre.query(on: req.db)
            .all()
            .map(\.toDTO)
        return try await jsonOrHTML(request: req, templateName: "genres_list", value: ["genres": genreDTOs])

        let resp = Response(status: .ok)
        if req.headers.accept.contains(where: { $0.mediaType == .html }) {
            let view: View = try await req.view.render("genres", genreDTOs)
            resp.headers.contentType = .html
            resp.body = .init(buffer: view.data)
        } else {
            try resp.content.encode(genreDTOs)
            resp.headers.contentType = .json
        }
        return resp
    }

    // Auth controllers
    try app.register(collection: LoginController(sessionEnabled: sessionEnabled))
    try app.register(collection: UserController(sessionProtected: sessionProtected))
    try app.register(collection: RegistrationController(sessionProtected: sessionProtected))

    // App controllers
    try app.register(collection: MovieController(sessionProtected: sessionProtected))
    try app.register(collection: PeopleController(sessionProtected: sessionProtected))
    try app.register(collection: MovieFavoriteController(sessionProtected: sessionProtected))
}
