import Vapor
import Fluent

struct RegistrationRequest: Content {
    let name: String
    let email: String
    let password: String
    let confirm: String
    
    func hash(with req: Request) async throws -> String {
        try await req.password.async.hash(password)
    }
}

extension RegistrationRequest: Validatable {
    static func decode(from req: Request) throws -> RegistrationRequest {
        try validate(content: req)
        let request = try req.content.decode(Self.self)
        
        guard request.password == request.confirm
        else { throw AuthenticationError.passwordsDontMatch }
        
        return request
    }
    
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(4...))
    }
}

extension User {
    convenience init(from register: RegistrationRequest, hash: String) {
        self.init(name: register.name, email: register.email, passwordHash: hash)
    }
}

struct RegistrationController: RouteCollection, @unchecked Sendable {
    let sessionProtected: RoutesBuilder

    func boot(routes: any RoutesBuilder) throws {
        sessionProtected.get("register", use: renderRegister)
        routes.post("register", use: handleRegister)
    }
    
    @Sendable
    func renderRegister(_ req: Request) async throws -> Response {
        if let user = try await req.auth.get(Token.self)?.$user.get(on: req.db) {
            return req.redirect(to: "/")
        }

        return try await Page(file: "register",
                       meta: .init(title: "Register",
                                   description: "Registration Page"))
            .render(with: req)
    }
    
    @Sendable
    func handleRegister(_ req: Request) async throws -> Response {
        let registration = try RegistrationRequest.decode(from: req)

        // hash password
        let hash = try await registration.hash(with: req)
        
        // Create user
        let user = User(from: registration, hash: hash)
        do {
            try await user.create(on: req.db)
        } catch {
            throw AuthenticationError.emailAlreadyExists
        }
        
        // Redirect to login
        return req.redirect(to: "/login")
    }
}
