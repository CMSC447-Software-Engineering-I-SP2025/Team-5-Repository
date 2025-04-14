import Vapor
import Fluent
import Leaf

struct LoginRequest: Content {
    var email: String
    var password: String
    var redirect: String?
    
    func find(with request: Request) async throws -> User {
        guard let user = try await User.query(on: request.db)
            .filter(\.$email == email) .first(),
              try await request.password.async.verify(password, created: user.passwordHash)
        else { throw AuthenticationError.invalidEmailOrPassword }
        return user
    }
}



extension LoginRequest: Validatable {
    static func decode(from req: Request) throws -> LoginRequest {
        try validate(content: req)
        return try req.content.decode(Self.self)
    }
    
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
    }
}

struct LoginPage: LeafPage {
    var file: String
    var meta: PageMetadata
    let request: LoginRequest?
    let redirect: String?
    
    init(request: LoginRequest? = nil, redirect: String? = nil, error: Error? = nil) {
        self.file = "login"
        self.meta = .init(title: "Login", description: "Login", error: error?.localizedDescription)
        self.request = request
        self.redirect = redirect
    }
}



struct LoginController: RouteCollection, @unchecked Sendable {
    let sessionEnabled: RoutesBuilder
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("login", use: renderLogin)
        sessionEnabled.post("login", use: handleLogin)
    }

    
    struct Redirect: Content {
        var redirect: String?
    }
    
    @Sendable
    func renderLogin(_ req: Request) async throws -> Response {
        var redirect = try req.query.decode(Redirect.self).redirect
        if redirect == nil {
            if let referrerString = req.headers["Referer"].first,
               let referrerURL = URL(string: referrerString) {
                redirect = referrerURL.path()
            }
        }
        return try await LoginPage(redirect: redirect).render(with: req)
    }
    
    @Sendable
    func handleLogin(_ req: Request) async throws -> Response {
        do {
            let login = try LoginRequest.decode(from: req)

            do {
                // get find valid user
                let user = try await login.find(with: req)
                
                // remove existing tokens
                try await Token.query(on: req.db)
                    .filter(\.$user.$id == user.requireID())
                    .delete()
                
                // Generate new token
                let token = try user.generateToken()
                try await token.create(on: req.db)
                
                // Authenticate session
                req.session.authenticate(token)
                
                // Redirect
                return req.redirect(to: try req.query.decode(Redirect.self).redirect ?? "/")

            } catch {
                // Handle invalid login error
                return try await LoginPage(request: login, error: error)
                    .render(with: req)
            }
        } catch {
            // Handle invalid login request error
           let page = Page(file: "login", meta: .init(title: "Login",
                                                      description: "Login Page",
                                                      error: String(describing: error)))
            return try await page.render(with: req)
        }
    }
}
